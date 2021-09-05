#!/usr/bin/env Rscript --max-ppsize=500000
options(expressions=500000)

args = commandArgs(trailingOnly=TRUE)

library(mikropml)

doFuture::registerDoFuture()
future::plan(future::multicore, workers = as.numeric(args[1]))

data_raw <- read.csv(args[2], row.names = 1, check.names = FALSE)
data_processed <- preprocess_data(data_raw, outcome_colname = args[3])

saveRDS(data_processed, file = args[4])
