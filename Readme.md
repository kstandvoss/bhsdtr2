At present, only the most important functions in the bhsdtr2 package (e.g., bhsdtr, samples) are documented.

The bhsdtr2 package overview
----------------------------

The bhsdtr2 (short for Bayesian Hierarchical Signal Detection Theory with Ratings version 2) package implements a novel method of Bayesian inference for hierarchical or non-hierarchical ordinal models with ordered thresholds, such as Equal-Variance (EV) Normal SDT, Unequal-Variance (UV) Normal SDT, EV meta-d', parsimonious (UV or EV) SDT and meta-d' (only EV) models (see this [paper](https://link.springer.com/article/10.3758/s13428-019-01231-3) by Selker, van den Bergh, Criss, and Wagenmakers for an explanation of the term 'parsimonious' in this context), as well as more general ordinal models.

For example, a hierarchical SDT model can be fitted by writing:

``` r
gabor$r = combined.response(gabor$stim, gabor$rating, gabor$acc)
m = bhsdtr(c(dprim ~ duration * order + (duration | id), thr ~ order + (1 | id)),
           r ~ stim,
           gabor)
```

The package uses the state-of-the-art platform [Stan](http://mc-stan.org/) for sampling from posterior distributions. The models can accommodate binary responses as well as ordered polytomous responses and an arbitrary number of nested or crossed random grouping factors. The parameters (e.g., d', decision criterion, thresholds, the ratio of standard deviations, latent mean) can be regressed on additional predictors within the same model via intermediate unconstrained parameters. The models can be extended by modifying automatically generated human-readable Stan code.

Background
----------

Ordinal models are *non-linear*. An immediate consequence of non-linearity is that inference based on data aggregated over grouping factors (such as participants or items) is invalid because the resulting estimates of all the model parameters may be (and usually are) asymptotically biased, often severely so (see this [paper](http://rouder.psyc.missouri.edu/sites/default/files/morey-jmp-zROC-2008_0.pdf) by Morey, Pratte, and Rouder for a demonstration, or see our [preprint](http://dx.doi.org/10.23668/psycharchives.2725) for an even more striking demonstration). The only correct solution to this problem is to model the (possibly correlated) "random" effects of all the relevant grouping factors.

In the bhsdtr2 package, ordinal models are supplemented with a hierarchical linear regression structure (normally distributed correlated random effects) thanks to a novel parametrization described in this [preprint](http://dx.doi.org/10.23668/psycharchives.2725) (which was recently accepted for publication in Behavior Research Methods), and - more concisely - in the package documentation.

The main advantage of the bhsdtr2 (and bhsdtr) package over other available methods of fitting ordinal models with ordered thresholds has to do with the order-preserving link functions which are used for the thresholds (aka criteria). To my knowledge, at present bhsdtr and bhsdtr2 are the only correct implementations of hierarchical SDT-like models, because both packages allow for variability in d' (or latent mean) and in individual thresholds, while respecting the assumptions of non-negativity (d') and order (thresholds) (see the [preprint](http://dx.doi.org/10.23668/psycharchives.2725) for more details). Without the order-preserving link functions, it is impossible to correctly model the effects in *individual* thresholds, including the possibly ubiquitous individual differences (i.e., participant effects) in the *pattern* of threshold placement. Note that the preprint covers only the SDT models and only one order-preserving link function, whereas there are now five such functions (softmax, log\_distance, log\_ratio, twoparamter and parsimonious) to choose from in bhsdtr and bhsdtr2.

Prerequisites
-------------

A fairly up-to-date version of [R](https://www.r-project.org/) with the [devtools package](https://cran.r-project.org/web/packages/devtools/index.html) already installed.

Installing the package
----------------------

The bhsdtr2 package, together will all of its dependencies, can be installed directly from this github repository using the devtools package:

``` r
devtools::install_git('git://github.com/boryspaulewicz/bhsdtr2')
```

Usage examples
--------------

The package contains the gabor dataset

``` r
library(bhsdtr2)
library(rstan)

head(gabor[,-1])
```

      duration trial acc id           order age gender rating stim
    1    32 ms     1   0  4 DECISION-RATING  32      M      1    1
    3    32 ms     3   1  4 DECISION-RATING  32      M      2    0
    4    64 ms     4   1  4 DECISION-RATING  32      M      3    0
    5    64 ms     5   1  4 DECISION-RATING  32      M      2    0
    8    32 ms     8   1  4 DECISION-RATING  32      M      2    1
    9    64 ms     9   0  4 DECISION-RATING  32      M      1    1

To fit a hierarchical SDT model with multiple thresholds to this data we need to create the combined response variable that encodes both the binary classification decision and rating:

``` r
gabor$r = combined.response(gabor$stim, gabor$rating, gabor$acc)
```

The responses are automatically aggregated by the bhsdtr function to make the sampling more efficient. Here is how you can fit the simplest possible SDT model, i.e., EV Normal with one threshold / criterion, to the data from one participant in one condition and obtain the point estimate of d':

``` r
gabor$r.binary = combined.response(gabor$stim, accuracy = gabor$acc)
unique(gabor[order(gabor$r), c('stim', 'r.binary', 'acc', 'rating',  'r')])
```

         stim r.binary acc rating r
    4       0        1   1      3 1
    1064    1        1   0      3 1
    3       0        1   1      2 2
    32      1        1   0      2 2
    1       1        1   0      1 3
    21      0        1   1      1 3
    35      0        1   1      0 4
    52      1        1   0      0 4
    53      0        2   0      0 5
    96      1        2   1      0 5
    34      1        2   1      1 6
    44      0        2   0      1 6
    8       1        2   1      2 7
    36      0        2   0      2 7
    13      1        2   1      3 8
    239     0        2   0      3 8

``` r
m = bhsdtr(c(dprim ~ 1, thr ~ 1),
           r.binary ~ stim,
           gabor[gabor$order == 'DECISION-RATING' & gabor$duration == '32 ms' &
                 gabor$id == 1,])
samples(m, 'dprim')
```

    samples: 1, estimates rounded to 2 decimal places
     dprim.1
        0.95

In bhsdtr the link-transformed parameters (i.e., delta, gamma, theta, and eta) have normal priors with default mean and standard deviation values that depend on the model type and the link function. If you want to use non-default priors you can alter the elements of the model object and fit it again using the fit function:

``` r
## Here we introduce strong priors which imply that d' is near zero
m.alt = set.prior(m, delta_prior_fixed_mu = log(.5), delta_prior_fixed_sd = .5)
m.alt = fit(m.alt)
samples(m.alt, 'dprim')
```

    samples: 1, estimates rounded to 2 decimal places
     dprim.1
        0.63

Note that the priors are specified using matrices. In this case there is only one d' fixed effect (i.e., the intercept), and d' has only one dimension (it has two in the meta-d' model), so the prior matrices for mean and standard deviation of d' fixed effects have dimension 1x1. You can provide vectors or matrices of prior parameter values; The vectors will be used to fill the relevant matrices in column-major order.

Here is how you can fit the hierarchical EV Normal SDT model in which we assume that d' depends on duration (a within-subject variable) and order (a between-subject variable), the effect of duration may vary between the participants, and the thresholds - which may also vary between the participants - depend only on order:

``` r
m = bhsdtr(c(dprim ~ duration * order + (duration | id), thr ~ order + (1 | id)),
           r ~ stim, gabor)
```

On my laptop, this model was fitted in less than half a minute, because by default, bhsdtr2 uses stan's optimizing function which fits the model by maximizing the joint posterior. If you want posterior samples you just have to add the method = 'stan' argument (plus any additional arguments that you want to pass to the stan function, although the defaults seem to be working quite well most of the time).

Even though in bhsdtr2 the d' (meta-d', thresholds, latent mean, sd ratio) parameter is internally represented by the isomorphic delta (delta, gamma, eta, theta) parameter (more on that later) and the two kinds of parameters are non-linearly related, you can easily obtain condition-specific posterior samples (method = 'stan') or point estimates (method = 'jmap', the default) of d' (meta-d', thresholds, latent means, the standard deviation ratios) using the samples function:

``` r
samples(m, 'dprim')
```

    samples: 1, estimates rounded to 2 decimal places
                          dprim.1
    32 ms:DECISION-RATING    0.89
    32 ms:RATING-DECISION    0.78
    64 ms:DECISION-RATING    3.07
    64 ms:RATING-DECISION    3.96

If this model was fitted using stan you would also see a similar summary table, but the object returned by the samples function would contain all the posterior samples, stored as a three dimensional array, where the first dimension is the sample number, the second dimension is the dimensionality of the parameter (d' has 1, meta-d' has 2, thresholds have K - 1, sd ratio has 1, latent mean has 1), and the third dimension corresponds to all the unique combinations of the predictors specified in the model formula for the given parameter, seen above as the names of the rows.

To do to fit the UV version of this model you have to introduce the model formula for the sdratio parameter. Here, for example, we assume that the ratio of the standard deviations doest not depend on any of the two factors, but may vary between the participants:

``` r
m = bhsdtr(c(dprim ~ duration * order + (duration | id), thr ~ order + (1 | id),
             sdratio ~ 1 + (1 | id)),
           r ~ stim,
           gabor)
```

To fit the hierarchical meta-d' model you just have to replace the dprim parameter with the metad parameter:

``` r
m = bhsdtr(c(metad ~ duration * order + (duration | id), thr ~ order + (1 | id)),
           r ~ stim,
           gabor)
```

If you want, you can fit the hierarchical parsimonious SDT model (here UV):

``` r
m = bhsdtr(c(dprim ~ duration * order + (duration | id), thr ~ order + (1 | id),
             sdratio ~ 1 + (1 | id)),
           r ~ stim, links = list(gamma = 'parsimonious'),
           gabor,)
```

etc. The plot method will show you if the model fits:

``` r
plot(m)
```

![](Figs/unnamed-chunk-13-1.svg)

Judging by this plot, the parsimonious model may be a bit too constrained. If you use stan:

``` r
m.stan = bhsdtr(c(dprim ~ duration * order + (duration | id), thr ~ order + (1 | id)),
                r ~ stim,
                gabor, method = 'stan')
```

you will be able to enjoy the stan summary table:

``` r
print(m.stan$stanfit, probs = c(.025, .975),
      pars = c('delta_fixed', 'gamma_fixed'))
```

    Inference for Stan model: f1227ab9a3feb55de2e21a3383b8b94d.
    7 chains, each with iter=5000; warmup=2000; thin=1; 
    post-warmup draws per chain=3000, total post-warmup draws=21000.

                      mean se_mean   sd  2.5% 97.5% n_eff Rhat
    delta_fixed[1,1] -0.09       0 0.14 -0.39  0.17  8758    1
    delta_fixed[1,2]  1.21       0 0.11  1.01  1.44 11248    1
    delta_fixed[1,3] -0.31       0 0.23 -0.77  0.14  9767    1
    delta_fixed[1,4]  0.46       0 0.18  0.11  0.80 11993    1
    gamma_fixed[1,1] -0.43       0 0.15 -0.72 -0.15  7939    1
    gamma_fixed[1,2]  0.27       0 0.23 -0.19  0.71  9167    1
    gamma_fixed[2,1] -0.57       0 0.13 -0.82 -0.33 10242    1
    gamma_fixed[2,2]  0.25       0 0.20 -0.15  0.63 10628    1
    gamma_fixed[3,1] -0.04       0 0.11 -0.26  0.17  9485    1
    gamma_fixed[3,2] -0.20       0 0.17 -0.55  0.13  9798    1
    gamma_fixed[4,1]  0.08       0 0.08 -0.07  0.22 10719    1
    gamma_fixed[4,2] -0.19       0 0.12 -0.43  0.05 12027    1
    gamma_fixed[5,1] -0.51       0 0.16 -0.82 -0.19 10248    1
    gamma_fixed[5,2]  0.16       0 0.25 -0.33  0.65 10508    1
    gamma_fixed[6,1] -0.90       0 0.15 -1.19 -0.60 12209    1
    gamma_fixed[6,2]  0.27       0 0.23 -0.21  0.72 13364    1
    gamma_fixed[7,1] -0.22       0 0.10 -0.42 -0.01 10943    1
    gamma_fixed[7,2]  0.21       0 0.17 -0.12  0.54 12794    1

    Samples were drawn using NUTS(diag_e) at Wed Feb 26 21:19:33 2020.
    For each parameter, n_eff is a crude measure of effective sample size,
    and Rhat is the potential scale reduction factor on split chains (at 
    convergence, Rhat=1).

and you will see the predictive intervals in the response distribution plots:

``` r
plot(m.stan, vs = c('duration', 'order'), verbose = F)
```

![](Figs/unnamed-chunk-17-1.svg)

as well as in the ROC plots:

``` r
plot(m.stan, vs = c('duration', 'order'), type = 'roc',  verbose = F)
```

![](Figs/unnamed-chunk-18-1.svg)

If you know what you are doing, you can use the stan posterior samples directly, but if the very idea of a link function makes you feel uneasy, note that most of the time you can forget about the delta, gamma, theta, and eta parameters and rely on the samples function:

``` r
(smp = samples(m.stan, 'thr'))
```

    samples: 21000, estimates rounded to 2 decimal places
                    thr.1 thr.2 thr.3 thr.4 thr.5 thr.6 thr.7
    DECISION-RATING -2.12 -1.46 -0.89  0.08  0.68  1.10  1.90
    RATING-DECISION -2.51 -1.65 -0.91 -0.11  0.61  1.15  2.15

except for the random effects' standard deviations and correlation matrices, with witch you have to deal directly. In this case, the array returned by the samples function has the following dimensions:

``` r
dim(smp)
```

    [1] 21000     7     2

which means that we have 21000 samples, 7 thresholds, and 2 conditions. Does the order affect the thresholds? We can compare the conditions separately for each threshold by apply-ing the quantile function to the sub-matrices indexed by the second (threshold number) dimension.

``` r
round(t(apply(smp, 2, function(x)quantile(x[,1] - x[,2], c(.025, .975)))), 2)
```

           2.5% 97.5%
    thr.1 -0.18  0.99
    thr.2 -0.24  0.62
    thr.3 -0.32  0.36
    thr.4 -0.05  0.43
    thr.5 -0.25  0.39
    thr.6 -0.50  0.37
    thr.7 -0.86  0.32

Judging by the 95% credible intervals, there seems to be no evidence of the order affecting the thresholds. You can make use of the fact the names of the columns of these sub-matrices represent unique conditions (in general, they represent unique combinations of variables which were introduced in the model formula for the given parameter):

``` r
round(t(apply(smp, 2, function(x)quantile(x[,'DECISION-RATING'] - x[,'RATING-DECISION'],
                                          c(.025, .975)))), 2)
```

           2.5% 97.5%
    thr.1 -0.18  0.99
    thr.2 -0.24  0.62
    thr.3 -0.32  0.36
    thr.4 -0.05  0.43
    thr.5 -0.25  0.39
    thr.6 -0.50  0.37
    thr.7 -0.86  0.32

Priors for d' and meta-d' fixed effects
=======================================

By default, d' (meta-d') are represented as delta = log(d') (log(meta-d')) and the prior on delta is normal. This means that the (implied) prior on d' is log-normal. This is how the default prior on d' fixed effect looks like (it is different in bhsdtr2 than in bhsdtr):

``` r
m = bhsdtr(c(dprim ~ 1, thr ~ 1), r ~ stim, gabor, method = F)
curve(dlnorm(x, m$sdata$delta_prior_fixed_mu, m$sdata$delta_prior_fixed_sd),
      0, 5, main = 'Default prior for d\' fixed effects', xlab = 'd\'', ylab = 'p(d\')')
```

![](Figs/unnamed-chunk-23-1.svg)

This is perhaps not very informative in typical situations, but in theory this prior excludes 0, although in practice posterior d' samples equal to 0 are not excluded by this prior because of the finite precision of floating point numbers. As a convenient alternative, it is now possible to use a more sophisticated prior for d' if the separate intercepts parametrization is used: when using the id\_log link function for delta, d' = delta fixed effect \* exp(sum of delta random effects), which means that delta (fixed effect) = d', but delta random effects are still on the log scale.

``` r
m = bhsdtr(c(dprim ~ 1 + (1 | id), thr ~ 1 + (1 | id)), r ~ stim,
           gabor[gabor$duration == '32 ms' & gabor$order == 'DECISION-RATING', ],
           list(delta = 'id_log'))
samples(m, 'dprim')
```

    samples: 1, estimates rounded to 2 decimal places
     dprim.1
        0.93

``` r
## delta_fixed == d' when id_log is used
round(m$jmapfit$par['delta_fixed[1,1]'], 2)
```

    delta_fixed[1,1] 
                0.93 

When this link function is used, the prior on delta fixed effects is a normal distribution truncated at 0. This way non-negativity of d' is preserved, but d' = 0 is not excluded by the fixed effects' prior even in theory. This link function and prior may be especially useful when e.g., Savage-Dickey density ratio Bayes Factors are to be estimated for the d' or meta-d' fixed effects. Note however, that the id\_log link function can only be used when there are no quantitative predictors (i.e., only factors) and the separate intercepts parametrization is used for the fixed effects, i.e., dprim (or metad) ~ 1, or ~ -1 + f1:...:fn, as well as for the random effects, i.e., (1 | g), or (-1 + fl:...:fk | g), where g is the grouping factor.

The importance of order-preserving link functions in ordinal models
===================================================================

Response labels such as "noise" and "signal" can be viewed as values of a nominal scale variable, however, from the point of view of Signal Detection Theory such variables are in fact *ordinal*. That's because in an SDT model, the response "signal" corresponds to *higher* values of internal evidence. Moreover, once the ratings (an ordinal variable) are introduced the problem of confounding sensitivity and bias still exists even if we consider only one kind of responses (e.g., only "signal" responses); A participant may respond "high confidence" not because the internal evidence is high, but because, for some reason, the labels are used differently. It is just as unrealistic to assume that the rating scale is invariant across participants, items, or conditions, as it is to assume that the SDT decision criterion is constant. It leads to the same kind of problem when interpreting the results - observed differences may indicate that what is supposed to be captured by the ratings (e.g., the latent mean) is different, or that the way the ratings are used (the average position and pattern of the thresholds) is different.

Consider a typical ordinal polytomous variable in psychology, such as PAS ratings, confidence ratings, or a Likert-type item in a questionnaire. Typically, it is natural to assume two things about such variables:

1.  *Order invariance*, i.e., whatever latent value X this outcome is supposed to represent, higher observed values correspond to higher values of X, e.g., higher confidence ratings correspond to higher value (more "signal-like") of internal evidence in an SDT model, or higher values in a questionnaire item correspond to higher values of the property X measured by the questionnaire. When order invariance does not hold, it indicates that the process of generating the responses changed in a *qualitative* way, e.g., the responses in a binary classification task were reversed because the task instructions were misunderstood, or some of the possible responses in a Likert-type item were interpreted in a way that was not intended by the authors of the questionnaire.

2.  *Lack of scale invariance*, i.e., the thresholds that correspond to the response categories may differ between participants, items, or conditions, or may covary with quantitative predictors. In fact, it would be more than just surprising if evidence was found that the mapping between the values of ordinal responses and the latent values captured by those responses was constant between participants, conditions or items, since the thresholds that correspond to such responses are parts of the psychological mechanism which is certain to be more or less unique to each participant and cannot be assumed to be invariant across changing conditions.

Whenever typical ordinal variables are used, there is the possibility of confounding "response bias", which in this case corresponds to the way the response categories are used to label e.g., some internal experience, and the internal experience itself. This problem is seen as important in the context of binary classification tasks and SDT theory, but it often seems to be ignored in other contexts. For example, in the context of IRT modelling, this is known as the 'item parameter invariance' problem and it is usually reduced to Differential Item Functioning (DIF). However, DIF is a population-level effect and in no way captures the individual differences in the *pattern* of the thresholds.

An *order-preserving link function* is an isomorphic function that maps the space of ordered real vectors (i.e., *v<sub>j</sub> &gt; v<sub>i</sub>* if *j &gt; i*) to the space of unresctricted real vectors *γ* in such a way that:

1.  The order is preserved in a sense that *v<sub>i</sub>* is mapped to *γ<sub>i</sub>*

2.  *Individual* elements (e.g., thresholds) become "free", i.e., each element of *γ* is unbounded and can be related in an arbitrary way to nominal (e.g., participants, items, conditions) or quantitative predictors.

*By using an order-preserving link function any model which represents an ordinal variable in terms of ordered thresholds can be supplemented with a hierarchical linear regression structure in a way that accounts for the effects in the latent values as well as for the effects in the thresholds.*

A model that (usually unrealistically) assumes that the pattern of thresholds' placement is constant across participants or conditions cannot account for the possibility of response/scale bias; If all the thresholds are shifted by the same amount in one direction the observed effects are the same as if the thresholds stayed the same but the latent value changed. It is only when the thresholds and the latent values are assumed to be related to different variables (selective influence) that deconfounding of latent values from scale/response bias becomes possible. Order-preserving link functions make many such models possible. Because ordinal models are non-linear, supplementing them with a hierarchical linear regression structure may solve the problem of asymptotic interval and point estimate bias introduced by aggregating the data or by otherwise ignoring hierarchical data structure.

Overview of order-preserving link functions
===========================================

In the current version of the package, there are five link functions for the thresholds to choose from. One is the link function described in the preprint - this is now called "softmax". This link function (softmax followed by inverse normal CDF) is quite complicated and makes the task of specifying the priors for the gamma vector difficult.

The remaining link functions also preserve the ordering of the thresholds and at the same time allow for individual threshold effects, which was arguably the main contribution of the bhsdtr package in its previous version.

The unconstrained gamma vector can be mapped to the ordered thresholds vector in many useful ways. Note that the middle threshold (the K/2th threshold) considered in isolation is an unconstrained parameter. The rest of the thresholds can be represented as log-distances between thresholds or as log-ratios of distances between thresholds. For example, the K/2+1th threshold can be represented as log(c\_<sub>K+1</sub> - c<sub>K/2</sub>). This general idea leads to some intuitive solutions. One is:

the middle threshold is unconstrained:

c\_<sub>K/2</sub> = γ<sub>K/2</sub>

the thresholds above the main threshold are represented as log-distances, e.g.:

c<sub>K/2+3</sub> = c<sub>K/2+2</sub> + exp(γ<sub>K/2+3</sub>)

and similarly for the thresholds below the main threshold, e.g.:

c<sub>K/2-3</sub> = c<sub>K/2-2</sub> - exp(γ<sub>K/2-3</sub>)

This is the log\_distance gamma/threshold link function, which is used by default. The prior for γ<sub>K/2</sub> is easy to specify because under the log\_distance link function this element of the γ vector directly represents the position of the main threshold. In SDT models this is relative to the midpoint between the evidence distribution means, i.e., the value of 0 corresponds to no bias and the positive (negative) values correspond to the tendency to respond "noise" ("signal"). The priors for all the other elements of the γ vector are almost as easy to specify. For example, the assumption that the average distance between the thresholds is probably .5 can be represented by setting the means of the priors for the γ vector (except for γ<sub>K/2</sub>) at log(.5).

The log\_ratio link function is similar. The K/2th element again represents the main threshold, the γ<sub>K/2+1</sub> element represents log(c<sub>K/2+1</sub> - c<sub>K/2</sub>), which I like to call the spread parameter, because all the other distances are represented in terms of this one. The γ<sub>K/2-1</sub> element represents the assymetry between the lower and the upper spread of the thresholds which are next to the main threshold, i.e., the following log-ratio of distances (hence the name of the link function): log((c<sub>K/2</sub> - c<sub>K/2-1</sub>) / (c<sub>K/2+1</sub> - c<sub>K/2</sub>)). The elements γ<sub>K/2+i</sub> where i &gt; 1 also represent ratios of distances, i.e., γ<sub>K/2+i</sub> = log((c<sub>K/2+i</sub> - c<sub>K/2+i-1</sub>) / (c<sub>K/2+1</sub> - c<sub>K/2</sub>)), and I like to call them upper consistency parameters. The elements γ<sub>K/2-i</sub> where i &gt; 1 are lower consistency parameters, i.e., γ<sub>K/2-i</sub> = log((c<sub>K/2-i+1</sub> - c<sub>K/2-i</sub>) / (c<sub>K/2</sub> - c<sub>K/2-1</sub>)). In SDT models the reasonable prior for the log-ratio parameters has mean = log(1) = 0.

For those who enjoy this kind of thing, here is the *generalized* link function for ordered thresholds:

1.  choose an index i between 1 and K-1, this will be your unconstrained parameter

2.  represent c<sub>i</sub> as γ<sub>i</sub>

3.  choose an index j from the remaining K-2 indices

4.  represent c<sub>j</sub> as log of distance, i.e., c<sub>j</sub> + exp(γ<sub>i</sub>) or c<sub>j</sub> - exp(γ<sub>i</sub>), depending on which threshold is supposed to be to the right of the other

5.  choose an index k from the remaining K-3 indices

6.  represent c<sub>k</sub> as log of distance between c<sub>k</sub> and c<sub>i</sub> or between c<sub>k</sub> and c<sub>j</sub> or as log of distance between c<sub>k</sub> and c<sub>i</sub> (or c<sub>k</sub> and c<sub>j</sub>) divided by the distance between c<sub>j</sub> and c<sub>i</sub>

7.  etc.
