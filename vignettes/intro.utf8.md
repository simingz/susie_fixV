---
title: "Intro"
author: "Matthew Stephens"
date: "April 11, 2018"
output: html_document
---



# Introduction

This is just a quick document to show some examples of `susie` in action.


# Simple simulation

Here we simulate data with four non-zero effects.

```r
library(susieR)
set.seed(1)
n = 1000
p = 1000
beta = rep(0,p)
beta[1] = 1
beta[2] = 1
beta[3] = 1
beta[4] = 1
X = matrix(rnorm(n*p),nrow=n,ncol=p)
y = X %*% beta + rnorm(n)

res =susie(X,y,L=10)
plot(coef(res))
```

<img src="/private/var/folders/1f/d96lz9ts15g81dqs_hcc_9cr0000gq/T/RtmpvVQ6PC/preview-ca4395e17b6.dir/intro_files/figure-html/unnamed-chunk-1-1.png" width="672" />

```r
plot(y,predict(res))
```

<img src="/private/var/folders/1f/d96lz9ts15g81dqs_hcc_9cr0000gq/T/RtmpvVQ6PC/preview-ca4395e17b6.dir/intro_files/figure-html/unnamed-chunk-1-2.png" width="672" />


# Trend filtering

This is an example of using susie to do trend filtering.


```r
set.seed(1)
n=1000
delta = matrix(1,nrow=n,ncol=n)
for(i in 1:(n-1)){
  for(j in (i+1):n){
    delta[i,j] = -1
  }
}

beta = c(rep(0,100),rep(1,100),rep(3,100),rep(-2,100),rep(0,600))
y = beta + rnorm(n)
delta[,2:1000] = scale(delta[,2:1000])
s = susie(delta,y,L=10,sigma2=1)
```

Plot results: the truth is green, and susie estimate is red.

```r
plot(y)
lines(predict(s),col=2,lwd=3)
lines(beta,col=3,lwd=3)
```

<img src="/private/var/folders/1f/d96lz9ts15g81dqs_hcc_9cr0000gq/T/RtmpvVQ6PC/preview-ca4395e17b6.dir/intro_files/figure-html/unnamed-chunk-3-1.png" width="672" />

```r
s$sigma2
```

```
## [1] 1.080451
```


Try something harder where the beta increases linearly:

```r
set.seed(1)
beta = seq(0,1,length=1000)
y = beta + rnorm(n)
s = susie(delta,y,sigma2=1,L=10)
plot(y)
lines(predict(s),col=2,lwd=3)
lines(beta,col=3,lwd=3)
```

<img src="/private/var/folders/1f/d96lz9ts15g81dqs_hcc_9cr0000gq/T/RtmpvVQ6PC/preview-ca4395e17b6.dir/intro_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Compare with the lasso based solution

```r
library("genlasso")
```

```
## Loading required package: MASS
```

```
## Loading required package: Matrix
```

```
## Loading required package: igraph
```

```
## 
## Attaching package: 'igraph'
```

```
## The following objects are masked from 'package:stats':
## 
##     decompose, spectrum
```

```
## The following object is masked from 'package:base':
## 
##     union
```

```r
y.tf = trendfilter(y,ord=1)
y.tf.cv = cv.trendfilter(y.tf)
```

```
## Fold 1 ... Fold 2 ... Fold 3 ... Fold 4 ... Fold 5 ...
```

```r
plot(y)
lines(predict(s),col=2,lwd=3)
lines(beta,col=3,lwd=3)
lines(y.tf$fit[,which(y.tf$lambda==y.tf.cv$lambda.min)],col=4,lwd=3)
```

<img src="/private/var/folders/1f/d96lz9ts15g81dqs_hcc_9cr0000gq/T/RtmpvVQ6PC/preview-ca4395e17b6.dir/intro_files/figure-html/unnamed-chunk-5-1.png" width="672" />

```r
#plot(y.tf,lambda=y.tf.cv$lambda.min,col=2)
```

What happens if we have trend plus sudden change.


```r
beta = beta + c(rep(0,500),rep(2,500))
y = beta + rnorm(n)
s = susie(delta,y,sigma2=1,L=10)
plot(y)
lines(predict(s),col=2,lwd=3)
lines(beta,col=3,lwd=3)

# trend
y.tf = trendfilter(y,ord=1)
y.tf.cv = cv.trendfilter(y.tf)
```

```
## Fold 1 ... Fold 2 ... Fold 3 ... Fold 4 ... Fold 5 ...
```

```r
lines(y.tf$fit[,which(y.tf$lambda==y.tf.cv$lambda.min)],col=4,lwd=3)
```

<img src="/private/var/folders/1f/d96lz9ts15g81dqs_hcc_9cr0000gq/T/RtmpvVQ6PC/preview-ca4395e17b6.dir/intro_files/figure-html/unnamed-chunk-6-1.png" width="672" />

