options(future.globals.maxSize= 891289600)

doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@resources[["ncores"]])

data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed
group_names <- read.csv(snakemake@input[["csv"]], row.names = 1, check.names = FALSE)[,snakemake@params[['groups_colname']]]
n_groups = length(unique(group_names))

cat("Running ML on", nrow(data_processed), "samples,", ncol(data_processed)-1, "features and", n_groups, "groups\n")

if (n_groups > 1) {
   ml_results <- mikropml::run_ml(
     dataset = data_processed,
     method = snakemake@params[["method"]],
     outcome_colname = snakemake@params[['outcome_colname']],
     groups = group_names,
     find_feature_importance = FALSE,
     kfold = 5,
     cv_times = 10,
     training_frac = 0.8,
     seed = as.numeric(snakemake@params[['seed']]))
} else {
   ml_results <- mikropml::run_ml(
     dataset = data_processed,
     method = snakemake@params[["method"]],
     outcome_colname = snakemake@params[['outcome_colname']],
     find_feature_importance = FALSE,
     kfold = 5,
     cv_times = 10,
     training_frac = 0.8,
     seed = as.numeric(snakemake@params[['seed']]))
}

saveRDS(ml_results, file = snakemake@output[["model"]])
readr::write_csv(ml_results$performance, snakemake@output[["perf"]])
