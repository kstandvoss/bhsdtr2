% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/set.prior.R
\name{set.prior}
\alias{set.prior}
\title{Set the parameters of the prior distributions}
\usage{
set.prior(model, ...)
}
\arguments{
\item{model}{a bhsdtr model object}

\item{...}{There are two ways of providing the values of the prior
parameters. One is by directly using the names of the prior
parameters, e.g., delta_prior_fixed_mu = log(1.5),
delta_prior_fixed_sd = 2. Note that with the exception of nu
(lkj prior), the prior parameters are internally represented
as matrices of dimension DxC, where D is the dimensionality of
the parameter (delta has 2 in the meta-d' model, otherwise it
has 1, theta has 1, eta has 1, gamma has K - 1, unless the
twoparameter or the parsimonious link function is used, in
which case it has dim = 2) and C is the number of columns in
the fixed (<par>_prior_fixed_mu, <par>_prior_fixed_sd) or the
random (<par>prior_scale_<g>) effects' model matrix. You can
provide scalars, vectors, or matrices. A vector will fill the
prior parameter matrix in column major order. A more
convenient way is to use arguments of the form: delta =
list(mu = log(2), sd = 4, scale = list('1' = 6), nu = list('1'
= 1000), etc.}
}
\value{
a bhsdtr model object with updated priors
}
\description{
Set the parameters of the prior distributions
}
