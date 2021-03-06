## -*- coding: utf-8 -*-

## ensure that the indexing variable starts from 1 and - if fix_gaps
## == T, does not have any gaps between min(index) and max(index)
fix.index.gaps = function(v, description = 'unknown', fix_gaps = F, nvalues = NULL){
    if(is.character(v))
        v = as.factor(v)
    ## If this is a factor convert it to integer valued vector
    if(is.factor(v)){
        if(!is.null(nvalues))
           if(nlevels(v) != nvalues)
               stop(sprintf('Factor %s does not have %d levels', description, nvalues))
        v = as.numeric(v)
    }
    if(fix_gaps){
        res = sort(unique(v))
        if(!all((res[-1] - res[-length(res)]) == 1))
            v = as.numeric(as.factor(as.character(v)))
    }
    ## Ensure that min(v) == 1
    v - min(v, na.rm = T) + 1
}

## ensure that the dimensionality matches that required by stan (e.g., vector as a 1xSize matrix)
fix.stan.dim = function(x)if(length(x) == 1){ array(x, dim = 1) }else{ x }

## utility
rmatch = function (pattern, vector){
  res = TRUE
  for (i in 1:length(vector)) {
    if (length(grep(pattern, vector[i])) > 0) {
      res[i] = TRUE
    }
    else {
      res[i] = FALSE
    }
  }
  res
}

merged.extract = function(m, par, group = NULL){
    if(is.null(group)){
        par.name = sprintf('%s_fixed', par)
    }else{
        par.name = sprintf('%s_random_%d', par, group)
        group.size = m$sdata[[sprintf('%s_group_max_%d', par, group)]]
    }
    size = m$sdata[[sprintf('%s_size', par)]]
    res1 = rstan::extract(m$stanfit, par.name, permuted = F)
    if(!is.null(group)){
        res1 = array(res1, c(dim(res1)[1:2], group.size, size, dim(res1)[3] / (group.size * size)))
        array(res1, c(dim(res1)[1] * dim(res1)[2], group.size, size, dim(res1)[5]))
    }else{
        array(res1, c(dim(res1)[1] * dim(res1)[2], size, dim(res1)[3] / size))
    }
}

is.separate.intercepts = function(X){
    all(unique(as.vector(X)) %in% 0:1) &
        all((abs(X) %*% rep(1, ncol(X))) == 1)
    ## separate.intercepts = T
    ## for(i in 1:ncol(X)){
    ##     if(length(table(X[, i])) != 2){
    ##         separate.intercepts = F
    ##     }else if(!all(names(table(X[, i])) == c('0', '1'))){
    ##         separate.intercepts = F
    ##     }
    ## }
    ## if(!all(apply(X, 1, sum) == 1))
    ##     separate.intercepts = F
    ## separate.intercepts
}
