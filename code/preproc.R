#!/usr/bin/env Rscript --max-ppsize=500000
options(expressions=500000)

args = commandArgs(trailingOnly=TRUE)

library(mikropml)

doFuture::registerDoFuture()
future::plan(future::multicore, workers = as.numeric(args[1]))

cat("Reading input file...\n")
data_raw <- read.csv(args[2], row.names = 1, check.names = FALSE)
data_nogroups <- data_raw[,colnames(data_raw) != args[4]]

cat("Preprocessing data...\n")
data_processed <- preprocess_data(data_nogroups, outcome_colname = args[3], method = NULL, remove_var = "zv")

cat("Saving final dataframe...\n")
saveRDS(data_processed, file = args[5])
