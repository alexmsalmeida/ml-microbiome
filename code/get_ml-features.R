#!/usr/bin/env Rscript

options(future.globals.maxSize= 891289600)

doFuture::registerDoFuture()

option_list = list(
  optparse::make_option(c("-t", "--threads"), type="double", default=1,
              help="Number of threads. Default: 1", metavar="threads"),
  optparse::make_option(c("-i", "--input"), type="character", default=NULL,
              help="Input model file (.Rds)", metavar="input"),
  optparse::make_option(c("-m", "--method"), type="character", default=NULL,
              help="Machine learning method (glmnet, rf or svmRadial)", metavar="method"),
  optparse::make_option(c("-f", "--fun"), type="character", default=NULL,
              help="Performance metric function (twoClassSummary or multiClassSummary)", metavar="fun"),
  optparse::make_option(c("-o", "--output"), type="character", default="features_importance.csv",
              help="Output CSV file. Default: 'features_importance.csv'", metavar="output"))
opt_parser = optparse::OptionParser(option_list=option_list);
opt = optparse::parse_args(opt_parser);

if (is.null(opt$input) || is.null(opt$method) || is.null(opt$fun)){
  optparse::print_help(opt_parser)
  stop("Provide necessary arguments")
}

future::plan(future::multicore, workers = opt$threads)

ml.results = readRDS(opt$input)
colnames(ml.results$trained_model$trainingData)[1] = "Variable"
colnames(ml.results$test_data)[1] = "Variable"

if (opt$fun == "multiClassSummary") {
  perf_function = caret::multiClassSummary
} else if (opt$fun == "twoClassSummary") {
  perf_function = caret::twoClassSummary
}

cat("Estimating feature importance ... it might take a while\n")

feat.imp = mikropml::get_feature_importance(ml.results$trained_model,
  ml.results$trained_model$trainingData, ml.results$test_data,
  outcome_colname = "Variable",
  perf_metric_name = "AUC",
  class_probs = TRUE,
  perf_metric_function = perf_function,
  method = opt$method)

readr::write_csv(feat.imp, opt$output)
