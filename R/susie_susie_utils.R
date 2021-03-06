#' @title Local false sign rate (lfsr) for susie credible sets.
#'
#' @description Computes the average lfsr across SNPs for each single l,
#'   weighted by the posterior inclusion probability, alpha.
#'
#' @param res A susie fit, an output from \code{\link{susie}}.
#'
#' @return An l-vector of lfsr for credible sets.
#'
#' @importFrom stats pnorm
#'
#' @export
#'
susie_get_lfsr = function (res) {
  pos_prob = pnorm(0,mean = t(res$mu),sd = sqrt(res$mu2 - res$mu^2))
  neg_prob = 1 - pos_prob
  return(1 - rowSums(res$alpha * t(pmax(pos_prob,neg_prob))))
}

# Find how many variables in the CS.
# x is a probability vector.
n_in_CS_x = function (x, coverage = 0.9)
  sum(cumsum(sort(x,decreasing = TRUE)) < coverage) + 1

# Return binary vector indicating if each point is in CS.
# x is a probability vector.
in_CS_x = function (x, coverage = 0.9) {
  n = n_in_CS_x(x,coverage)
  o = order(x,decreasing = TRUE)
  result = rep(0,length(x))
  result[o[1:n]] = 1
  return(result)
}

# Returns an l-by-p binary matrix indicating which variables are in
# susie credible sets.
in_CS = function (res, coverage = 0.9) {
  if (inherits(res,"susie"))
    res = res$alpha
  return(t(apply(res,1,function(x) in_CS_x(x,coverage))))
}

n_in_CS = function(res, coverage = 0.9) {
  if (inherits(res,"susie"))
    res = res$alpha
  return(apply(res,1,function(x) n_in_CS_x(x,coverage)))
}

# Subsample and compute min, mean, median and max abs corr.
#
#' @importFrom stats median
get_purity = function(pos, X, Xcorr, squared = FALSE, n = 100) {
  if (length(pos) == 1)
    c(1,1,1)
  else {
    if (length(pos) > n)
      pos = sample(pos, n)
    if (is.null(Xcorr)) {
      X_sub = X[,pos]
      if (length(pos) > n) {

        # Remove identical columns.
        pos_rm = sapply(1:ncol(X_sub), function(i) all(abs(X_sub[,i] - mean(X_sub[,i])) < .Machine$double.eps^0.5))
        if (length(pos_rm))
          X_sub = X_sub[,-pos_rm]
      }
      value = abs(muffled_corr(as.matrix(X_sub)))
    } else
      value = abs(Xcorr[pos, pos])
    if (squared)
      value = value^2
    return(c(min(value,na.rm = TRUE),
             mean(value,na.rm = TRUE),
             median(value,na.rm = TRUE)))
  }
}

#' @title `cor` function with specified warning muffled
#' @keywords internal
#' @importFrom stats cor
muffled_corr = function(x)
  withCallingHandlers(cor(x),
                    warning = function(w) {
                      if (grepl("the standard deviation is zero", w$message))
                        invokeRestart("muffleWarning")
                    } )

#' @title `cov2cor` function with specified warning muffled
#' @keywords internal
#' @importFrom stats cov2cor
muffled_cov2cor = function(x)
  withCallingHandlers(cov2cor(x),
                      warning = function(w) {
                        if (grepl("had 0 or NA entries; non-finite result is doubtful", w$message))
                          invokeRestart("muffleWarning")
                      } )

# Check for symmetric matrix.
is_symmetric_matrix = function(x) {
  res = isSymmetric(x)
  if (!res)
    res = isSymmetric(unname(x))
  return(res)
}

#' @title Extract credible sets from SuSiE fit
#' @details Reports indices of variables in each credible set (CS) identified,
#' as well as summaries of correlation among the variables included in each CS.Revised from susieR::susie_get_cs.
#' If desired, one can filter out CSs that do not meet a specified purity threshold (min_abs_corr);
#' to do this either `X` or `Xcorr` must be supplied.
#' @param res a susie fit, the output of `susieR::susie()`, or simply the posterior
#' inclusion probability matrix alpha.
#' @param X N by P matrix of values of the P variables (covariates) in N samples.
#' When provided, correlation between variables will be computed and used to remove
#' CSs whose minimum correlation among variables is smaller than `min_abs_corr` (see below).
#' @param Xcorr P by P matrix of correlations between variables (covariates).
#' When provided, it will be used to remove CSs
#' whose minimum correlation among variables is smaller than `min_abs_corr` (see below).
#' @param coverage a number (in [0,1]) specifying desired coverage of each CS
#' @param min_abs_corr a "purity" threshold for the CS. Any CS that contains
#' a pair of variables with correlation less than this threshold will be filtered out and not reported.
#' @param dedup If TRUE, "deduplicate" - that is remove duplicated CSs.
#' @param squared If TRUE, report min, mean and median of squared correlation instead of absolute correlation.
#' @return a list with elements:
#'
#' \item{cs}{a list, each element corresponds to a CS, and is a vector containing the indices of the variables in the CS.}
#' \item{coverage}{the nominal coverage specified for each CS.}
#' \item{purity}{(If `X` or `Xcorr` are provided), the purity of each CS.}
#' \item{cs_index}{(If `X` or `Xcorr` are provided) the index (in 1,...,L) of each reported CS in the supplied susie fit.}
#'
#' @export
susie_get_cs <- function (res, X = NULL, Xcorr = NULL, coverage = 0.95, min_abs_corr = 0.5,
                          dedup = TRUE, squared = FALSE)
{
  if (!is.null(X) && !is.null(Xcorr)) {
    stop("Only one of X or Xcorr should be specified")
  }
  if (!is.null(Xcorr) && !is_symmetric_matrix(Xcorr)) {
    stop("Xcorr matrix must be symmetric")
  }
  if (inherits(res, "susie")) {
    null_index = res$null_index
    if (is.numeric(res$V))
      include_idx = rep(TRUE, nrow(res$alpha)) #different from susieR
    else include_idx = rep(TRUE, nrow(res$alpha))
  }
  else null_index = 0
  status = in_CS(res$alpha, coverage)
  cs = lapply(1:nrow(status), function(i) which(status[i, ] !=
                                                  0))
  include_idx = include_idx * (lapply(cs, length) > 0)
  if (dedup)
    include_idx = include_idx * (!duplicated(cs))
  include_idx = as.logical(include_idx)
  if (sum(include_idx) == 0)
    return(list(cs = NULL, coverage = coverage))
  cs = cs[include_idx]
  if (is.null(Xcorr) && is.null(X)) {
    names(cs) = paste0("L", which(include_idx))
    return(list(cs = cs, coverage = coverage))
  }
  else {
    purity = data.frame(do.call(rbind, lapply(1:length(cs),
                                              function(i) {
                                                if (null_index > 0 && null_index %in% cs[[i]])
                                                  c(-9, -9, -9)
                                                else get_purity(cs[[i]], X, Xcorr, squared)
                                              })))
    if (squared)
      colnames(purity) = c("min.sq.corr", "mean.sq.corr",
                           "median.sq.corr")
    else colnames(purity) = c("min.abs.corr", "mean.abs.corr",
                              "median.abs.corr")
    threshold = ifelse(squared, min_abs_corr^2, min_abs_corr)
    is_pure = which(purity[, 1] >= threshold)
    if (length(is_pure) > 0) {
      cs = cs[is_pure]
      purity = purity[is_pure, ]
      row_names = paste0("L", which(include_idx)[is_pure])
      names(cs) = row_names
      rownames(purity) = row_names
      ordering = order(purity[, 1], decreasing = T)
      return(list(cs = cs[ordering], purity = purity[ordering,
                                                     ], cs_index = which(include_idx)[is_pure[ordering]],
                  coverage = coverage))
    }
    else {
      return(list(cs = NULL, coverage = coverage))
    }
  }
}

#' @title Compute posterior inclusion probability (PIP) for all variables
#' @param res a susie fit, the output of `susieR::susie()`, or simply the posterior
#' inclusion probability matrix alpha. Revised from susieR::susie_get_pip.
#' @param prune_by_cs Whether or not to ignore single effects not in reported CS when calculating PIP. Default to FALSE.
#' @param prior_tol Filter out effects having estimated prior variance smaller than this threshold
#' @return a vector of posterior inclusion probability.
#' @export
susie_get_pip <- function (res, prune_by_cs = FALSE, prior_tol = 1e-09)
{
  if (inherits(res, "susie")) {
    if (res$null_index > 0)
      res$alpha = res$alpha[, -res$null_index, drop = FALSE]
    if (is.numeric(res$V))
      include_idx = 1:nrow(res$alpha) # different from susieR, will affect value of small PIPs
    else include_idx = 1:nrow(res$alpha)
    if (!is.null(res$sets$cs_index) && prune_by_cs)
      include_idx = intersect(include_idx, res$sets$cs_index)
    if (is.null(res$sets$cs_index) && prune_by_cs)
      include_idx = numeric(0)
    if (length(include_idx) > 0) {
      res = res$alpha[include_idx, , drop = FALSE]
    }
    else {
      res = matrix(0, 1, ncol(res$alpha))
    }
  }
  return(as.vector(1 - apply(1 - res, 2, prod)))
}

# compute standard error for regression coef
calc_stderr = function(X, residuals) {
    # S = (X'X)^-1 \Sigma
    sqrt(diag(sum(residuals^2) / (nrow(X) - 2) * chol2inv(chol(t(X) %*% X))))
  }

# univariate regression between each column of X and y
# Remove covariates if Z is not NULL
#
#' @importFrom stats lm
#' @importFrom stats .lm.fit
#' @importFrom stats coef
#' @importFrom stats summary.lm
univariate_regression = function(X, y, Z=NULL, center=TRUE, scale=FALSE,
                                 return_residuals=FALSE) {
  y_na = which(is.na(y))
  if (length(y_na)) {
    X = X[-y_na,]
    y = y[-y_na]
  }
  if (center) {
    y = y - mean(y)
    X = scale(X, center=TRUE, scale = scale)
  } else {
    X = scale(X, center=FALSE, scale = scale)
  }
  X[is.nan(X)] = 0
  if (!is.null(Z)) {
    if (center) Z = scale(Z, center=TRUE, scale=FALSE)
    y = .lm.fit(Z, y)$residuals
  }
  output = try(do.call(rbind,
                       lapply(1:ncol(X), function(i) {
                         g = .lm.fit(cbind(1, X[,i]), y)
                         return(c(coef(g)[2], calc_stderr(cbind(1, X[,i]), g$residuals)[2]))
                       })),
               silent = TRUE)
  if (inherits(output,"try-error")) {
    # Exception occurs, fall back to a safer but slower calculation
    output = matrix(0,ncol(X),2)
    for (i in 1:ncol(X)) {
      fit = summary(lm(y ~ X[,i]))$coef
      if (nrow(fit) == 2) {
        output[i,] = as.vector(summary(lm(y ~ X[,i]))$coef[2,1:2])
      } else {
        output[i,] = c(0,0)
      }
    }
  }
  if (return_residuals) {
    return(list(betahat = output[,1], sebetahat = output[,2],
                residuals = y))
  } else {
    return(list(betahat = output[,1], sebetahat = output[,2]))
  }
}

# computes z score (t-statistic) for association between each
# column of X and Y
calc_z = function(X,Y,center=FALSE,scale=FALSE){
  univariate_z = function(X,Y,center,scale) {
    out = univariate_regression(X,Y,center=center,scale=scale)
    return(out$betahat/out$sebetahat)
  }
  if (is.null(dim(Y))) {
    univariate_z(X,Y,center,scale)
  } else {
    do.call(cbind, lapply(1:ncol(Y), function(i) univariate_z(X, Y[,i], center=center, scale=scale)))
  }
}


# return residuals from Y after removing susie fit
#
#' @importFrom stats coef
get_R = function (X,Y,s)
  Y - X %*% coef(s)

#' @title Get updated prior variance
#'
#' @param res A susie fit, such as the output from \code{\link{susie}}.
#'
#' @export
#'
susie_get_prior_variance = function (res)
  res$V

#' @title Get updated residual variance
#'
#' @param res a susie fit, the output of `susieR::susie()`.
#'
#' @export
#'
susie_get_residual_variance = function (res)
  res$sigma2

#' @title Get evidence lower bound (ELBO) from fitted susie model
#'
#' @param res A susie fit, e.g., the output of \code{\link{susie}}.
#'
#' @param last_only whether or not to get ELBO from all iterations.
#'
#' @param warning_tol warn if ELBO is non-decreasing by this tolerance
#'   level.
#'
#' @export
#'
susie_get_objective = function (res, last_only = TRUE, warning_tol = 1e-6) {
  if (!all(diff(res$elbo) >= (-1*warning_tol)))
    warning("Objective is not non-decreasing")
  if (last_only)
    return(res$elbo[length(res$elbo)])
  else
    return(res$elbo)
}

# @title Slim the result of fitted susie model
# @param res a susie fit.
susie_slim = function (res)
  list(alpha = res$alpha,niter = res$niter,V = res$V,sigma2 = res$sigma2)

#' @title Get posterior mean for coefficients from fitted susie model
#'
#' @param res A susie fit.
#'
#' @export
#'
susie_get_posterior_mean = function (res)
  colSums(res$alpha*res$mu)/res$X_column_scale_factors

#' @title Get posterior standard deviation for coefficients from
#' fitted susie model
#'
#' @param res a susie fit
#'
#' @export
#'
susie_get_posterior_sd = function (res)
  sqrt(colSums(res$alpha * res$mu2 -
               (res$alpha*res$mu)^2))/(res$X_column_scale_factors)

#' @title Get number of iterations from fitted susie model
#'
#' @param res a susie fit
#'
#' @export
#'
susie_get_niter = function (res)
  res$niter

