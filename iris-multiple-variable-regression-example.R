## Multiple Regression Analysis.

# Personal prefered general packages
library(data.table)
library(ggplot2)
library(DescTools)

# Analysis packages
library(car)
library(gvlma)
library(MASS)
library(QuantPsyc)
library(Hmisc)
library(corrplot)
library(GGally)
library(lm.beta)

## Create a matrix for correlations and significance
## Based on output from rcorr
flattenCorrMatrix <- function(cormat, pmat, nmat) {
  ut <- upper.tri(cormat)
  data.frame(
    row = rownames(cormat)[row(cormat)[ut]],
    column = rownames(cormat)[col(cormat)[ut]],
    cor  =(cormat)[ut],
    p = pmat[ut],
    n = nmat[ut]
  )
}

## Some Code as per http://www.statmethods.net/stats/regression.html
## Some Code as per http://www.statmethods.net/stats/rdiagnostics.html

## Loading the IRIS file as an example.
load.file <- iris

## File Check
str(load.file)

# Convert the required factor column to numeric for use in cor analysis.
iris.df <- load.file
irisTrim.df <- iris.df[sapply(iris.df, is.numeric)]
irisTrim.df <- irisTrim.df[complete.cases(irisTrim.df),]

## Exploration of the data 
summary(irisTrim.df)
describe(irisTrim.df)

## Correlation plot with significance
## Will only return pairwise complete correlations and significance.
irisTrim.ma <- sapply(irisTrim.df, as.numeric)
irisTrim.df <- as.data.frame(sapply(irisTrim.df, as.numeric))
corMatrix <- rcorr(irisTrim.ma, type = "pearson")

# Correlation matrix and scatter plots.
flattenCorrMatrix(corMatrix$r, corMatrix$P, corMatrix$n)
ggpairs(irisTrim.df)

# Basic linear Model
fit <- lm(Sepal.Length~Sepal.Width+Petal.Length+Petal.Width, data = irisTrim.df)

# Review the fit.
# Multiple R-squared is displayed here.
# F statistic is also here, for the significance of R.
# Returns unstandardised coefficients
summary(fit)

## Returns the 95% CI for the coefficients.
# CIs for model parameters
cbind(summary(fit)$coefficients, confint(fit, level = 0.95)) 

# Produce the standardised parametre estimates.
lm.beta(fit)

## Durbin Watson test.
# Critical values: http://web.stanford.edu/~clint/bench/dw05c.htm
# k = number predictors, K=number coefficients including intercept
# Test for Autocorrelated Errors
durbinWatsonTest(fit)

## Display R.
rsq <- summary(fit)$r.squared
sqrt(rsq)

## Partial correlation statistics relevant to the model.
# http://comisef.wikidot.com/tip:partialcorrelation
t.values <- fit$coeff / sqrt(diag(vcov(fit)))
partcorr <- sqrt((t.values^2)/((t.values^2)+fit$df.residual))
partcorr

## Anova table 
# Checking predictors for linear relationship with dependent variable.
anova(fit) 

## Evaluate MultiCollinearity
# variance inflation factors and Tolerance
multi.df <- cbind(vif(fit), 1/vif(fit), sqrt(vif(fit)) > 2, 1/vif(fit) > 0.3)
colnames(multi.df) <- c("VIF", "Tolerance", "VIF > 2", "Tolerance > 0.3")
multi.df

## Review residuals
# distribution of studentized residuals
sresid <- studres(fit) 

## Studentized residuals range
# Falls between -3, 3
minStr <- min(sresid)
maxStr <- max(sresid)

# Plot distribution of studentized residuals.
hist(sresid, freq=FALSE, 
     main=paste("Distribution of Studentized Residuals\nRange = ", minStr, "-", maxStr, sep = " "))
xfit<-seq(min(sresid),max(sresid),length=40) 
yfit<-dnorm(xfit) 
lines(xfit, yfit)

## Maximum Mahalanobis Distance
covMa <- cov(na.omit(irisTrim.df))
mahalanobisDist <- mahalanobis(na.omit(irisTrim.df), colMeans(na.omit(irisTrim.df)), covMa)
max(na.omit(mahalanobisDist))
min(na.omit(mahalanobisDist))

## Influential values plot
# Another lot of plots
infIndexPlot(fit, vars=c("Cook", "Studentized", "Bonf", "hat"), main = "Diagnostic Plots",  id.method = cooks.distance(fit), id.n = 4)

## Residual plots
# Diagnostic plots 
layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
plot(fit)
layout(1,1,1)

## Partial regression plots.
avPlots(fit)

## Global test of model assumptions
# Including Skew and Kurtosis.
gvmodel <- gvlma(fit) 
summary(gvmodel)
