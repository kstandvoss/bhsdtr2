## -*- coding: utf-8 -*-

## len is the number of columns of the prior matrix, e.g., par == 'delta', prior.par == 'fixed_mu'
default.prior = function(par, len, prior.par, model, links, K){
    prior.par.original = prior.par
    if(prior.par == 'random_scale')
        prior.par = 'fixed_sd'
    unb = unbiased(K)
    Kb2 = round(K / 2)
    priors = list(theta = list(fixed_mu = 0, fixed_sd = log(1.5)),
                  eta = list(fixed_mu = 0, fixed_sd = 3),
                  delta = list(), gamma = list())
    priors[[par]][['random_nu']] = 1
    priors[[par]][['fixed_lb']] = priors[[par]][['fixed_ub']] = priors[[par]][['random_scale_lb']] = priors[[par]][['random_scale_ub']] = ''
    if(par == 'delta')
        if(links$delta == 'id_log')
            priors$delta$lb = '0'
    ## prior for delta depends on the model (sdt, metad) and the link
    ## function
    if('delta' %in% names(links)){
        if(links$delta == 'identity'){
            fixed_mu = exp(acc.to.delta(.75))
            fixed_sd = .5 * (exp(acc.to.delta(.99)) - exp(acc.to.delta(.51)))
        }else if(links$delta == 'id_log'){
            fixed_mu = exp(acc.to.delta(.75))
            if(prior.par.original == 'random_scale'){
                fixed_sd = 4 ## .5 * (acc.to.delta(.99) - acc.to.delta(.51))
            }else{
                fixed_sd = .5 * (exp(acc.to.delta(.99)) - exp(acc.to.delta(.51)))
            }
        }else if(links$delta == 'log'){
            fixed_mu = .5 ## acc.to.delta(.75)
            if(prior.par.original == 'random_scale'){
                fixed_sd = 4
            }else{
                fixed_sd = 1 ## .5 * (acc.to.delta(.99) - acc.to.delta(.51))
            }
        }
        priors$delta$fixed_mu = fixed_mu
        priors$delta$fixed_sd = fixed_sd
        if(model == 'metad')
            for(prior.par in names(priors$delta))
                priors$delta[[prior.par]] = rep(priors$delta[[prior.par]], 2)
    }
    ## prior for gamma depends on the link function
    if(links$gamma == 'twoparameter'){
        priors$gamma$fixed_mu = c(0, log(unbiased(K)[K / 2 + 1] - unbiased(K)[K / 2]))
        priors$gamma$fixed_sd = c(priors$eta$fixed_sd, log(2))
    }else if(links$gamma == 'parsimonious'){
        priors$gamma$fixed_mu = c(0, log(1))
        priors$gamma$fixed_sd = c(priors$eta$fixed_sd, log(2))
    }else if(links$gamma == 'softmax'){
        priors$gamma$fixed_mu = rep(0, K - 1)
        priors$gamma$fixed_sd = rep(log(100), K - 1)
    }else if(links$gamma == 'log_distance'){
        res.mu = rep(0, K - 1)
        if(K > (Kb2 + 1))
            for(k in (Kb2+1):(K - 1))
                res.mu[k] = log(unb[k] - unb[k - 1])
        if((Kb2 - 1) > 0)
            for(k in (Kb2 - 1):1)
                res.mu[k] = log(unb[k + 1] - unb[k])
        res.sd = rep(log(2), K - 1)
        res.sd[Kb2] = priors$eta$fixed_sd
        priors$gamma$fixed_mu = res.mu
        priors$gamma$fixed_sd = res.sd
    }else if(links$gamma == 'log_ratio'){
        res.mu = rep(0, K - 1)
        res.sd = rep(log(2), K - 1)
        res.sd[Kb2] = priors$eta$fixed_sd
        res.mu[Kb2 + 1] = log(unb[Kb2 + 1] - unb[Kb2])
        if(Kb2 > 1)
            res.mu[Kb2 - 1] = log(1)
        if((Kb2 + 2) < K)
            for(k in (Kb2 + 2):(K - 1))
                res.mu[k] = log((unb[k] - unb[k - 1]) / (unb[Kb2 + 1] - unb[Kb2]))
        if((Kb2 - 2) > 0)
            for(k in (Kb2 - 2):1)
                res.mu[k] = log((unb[k + 1] - unb[k]) / (unb[k + 1] - unb[k]))
        priors$gamma$fixed_mu = res.mu
        priors$gamma$fixed_sd = res.sd
    }else{
        stop(sprintf('Unknown gamma link %s', links$gamma))
    }
    matrix(priors[[par]][[prior.par]], nrow = par.size(par, model, links, K)[1], ncol = len)
}
