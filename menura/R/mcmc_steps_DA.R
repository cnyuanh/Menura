
#runs markov chain monte carlo with tanner-wong data augmentation method, estimation of parameters

mcmc_steps_DA <- function(fossils, tr, tipdata, rt_value, lst, theta, model,
                            para2est, update_method, proposals, priors,
                            method, N=N, ...) {


loglike_curr <-  tree_logL(fossils = fossils, tr = tr, tipdata = tipdata, lst = lst,
                           alpha = theta[, "alpha"], mu = theta[, "mu"],
                           sigma = theta[, "sigma"],
                           model = model,
                           method = method)


loglike <- loglike_curr
q_ratio <- p_theta <- p_theta_star <- 0
theta_star <- theta
for (var in para2est) {
  theta_star[, var] <- proposals[[var]]$rf(1, theta[, var][1])
  p_theta <- p_theta +
                priors[[var]]$df(theta[, var][1], log_scale = TRUE)
  p_theta_star <- p_theta_star +
                priors[[var]]$df(theta_star[, var][1], log_scale = TRUE)
  q_ratio <- proposals[[var]]$df(theta[, var][1], theta_star[, var][1]) -
                proposals[[var]]$df(theta_star[, var][1], theta[, var][1])
}

if (update_method == "tree") {
  rlst <- update_tree(fossils = fossils, lst = lst, tr = tr, tipdata = tipdata,
                  rt_value = rt_value, model = model, theta = theta,
                  N = N, method = method, mcmc_type = "DA")
  lst_star <- rlst$lst
  n_data_accept <- 1 #ifelse(rlst$data_accept > 0, 1, 0)
  
} else if (update_method == "subtree") {
  rlst <- update_subtree(fossils = fossils, lst = lst, tr = tr, tipdata = tipdata,
                  rt_value = rt_value, model = model, theta = theta,
                  N = N, method = method, mcmc_type = "DA")
  lst_star <- rlst$lst
  n_data_accept <- 1 #ifelse(rlst$data_accept > 0, 1, 0)
} else {
  stop("update_method must only be tree or subtree")
}

loglike_star <- tree_logL(fossils = fossils, tr = tr, tipdata = tipdata, lst = lst_star,
                          alpha = theta_star[, "alpha"],
                          mu = theta_star[, "mu"],
                          sigma = theta_star[, "sigma"],
                          model = model,
                          method = method)
accept_prob <- min(1,
                  exp(loglike_star + p_theta_star - loglike_curr -
                        p_theta + q_ratio))
#print(accept_prob)
n_para_accept <- 0
accept <- runif(1)
#print(accept)
if (is.nan(accept_prob))
  accept_prob <- 0
if (accept <= accept_prob) {
  lst <- lst_star
  theta <- theta_star
  n_para_accept <- 1
  loglike <- loglike_star
}

return(list(lst = lst, loglike = loglike, theta = theta, n_para_accept = n_para_accept,
  n_data_accept = n_data_accept))
}
