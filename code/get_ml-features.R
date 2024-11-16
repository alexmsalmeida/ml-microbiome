#!/usr/bin/env Rscript

options(future.globals.maxSize= 891289600)

doFuture::registerDoFuture()

option_list = list(
  optparse::make_option(c("-p", "--threads"), type="double", default=1,
              help="Number of threads. Default: 1", metavar="threads"),
  optparse::make_option(c("-i", "--input"), type="character", default=NULL,
              help="Input model file (.Rds)", metavar="input"),
  optparse::make_option(c("-m", "--method"), type="character", default=NULL,
              help="Machine learning method (e.g., glmnet, rf, xgbTree)", metavar="method"),
  optparse::make_option(c("-t", "--performance"), type="character", default=NULL,
              help="Performance metric to use (e.g., AUC, logLoss, Kappa, Mean_F1)", metavar="metric"),
  optparse::make_option(c("-f", "--fun"), type="character", default=NULL,
              help="Performance metric function (twoClassSummary or multiClassSummary)", metavar="fun"),
  optparse::make_option(c("-o", "--output"), type="character", default="features_importance.csv",
              help="Output CSV file. Default: 'features_importance.csv'", metavar="output"))
opt_parser = optparse::OptionParser(option_list=option_list);
opt = optparse::parse_args(opt_parser);

if (is.null(opt$input) || is.null(opt$method) || is.null(opt$fun) || is.null(opt$performance) || is.null(opt$output)){
  optparse::print_help(opt_parser)
  stop("Provide necessary arguments")
}


future::plan(future::multicore, workers = as.numeric(opt$threads)
)
ml.results = readRDS(opt$input)
outcol = which(colnames(ml.results$trained_model$trainingData) == ".outcome")
colnames(ml.results$trained_model$trainingData)[outcol] = "Variable"

if (opt$fun == "multiClassSummary") {
  perf_function = caret::multiClassSummary
} else if (opt$fun == "twoClassSummary") {
  perf_function = caret::twoClassSummary
}

cat("Estimating feature importance ... it might take a while\n")

feat.imp = mikropml::get_feature_importance(ml.results$trained_model,
  ml.results$trained_model$trainingData, ml.results$test_data,
  outcome_colname = "Variable",
  perf_metric_name = opt$performance,
  class_probs = TRUE,
  perf_metric_function = perf_function,
  method = opt$method)

readr::write_csv(feat.imp, opt$output)
