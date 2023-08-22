options(future.globals.maxSize= 891289600)

doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@resources[["ncores"]])

data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed

cat("Running ML on", nrow(data_processed), "samples and", ncol(data_processed)-1, "features\n")

ml_results <- mikropml::run_ml(
  dataset = data_processed,
  method = snakemake@params[["method"]],
  outcome_colname = snakemake@params[['outcome_colname']],
  find_feature_importance = FALSE,
  kfold = 10,
  cv_times = 20,
  training_frac = 0.9,
  seed = as.numeric(snakemake@params[['seed']])
)

saveRDS(ml_results, file = snakemake@output[["model"]])
readr::write_csv(ml_results$performance, snakemake@output[["perf"]])
