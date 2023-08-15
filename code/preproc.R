#!/usr/bin/env Rscript --max-ppsize=500000
options(expressions=500000)

args = commandArgs(trailingOnly=TRUE)

library(mikropml)

doFuture::registerDoFuture()
future::plan(future::multicore, workers = as.numeric(args[1]))

cat("Reading input file...\n")
data_raw <- read.csv(args[2], row.names = 1, check.names = FALSE)

cat("Preprocessing data...\n")
data_processed <- preprocess_data(data_raw, outcome_colname = args[3], remove_var = "zv", prefilter_threshold = round(nrow(data_raw)*0.2))

cat("Saving final dataframe...\n")
saveRDS(data_processed, file = args[4])
