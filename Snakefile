import os

configfile: 'config/config.yml'
ncores = config['ncores']

ml_methods = config['ml_methods']
outcome_colname = config['outcome_colname']

nseeds = config['nseeds']
start_seed = 100
seeds = range(start_seed, start_seed + nseeds)

log_dir = "results/logs"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

model_dir = "results/models"
if not os.path.exists(model_dir):
    os.makedirs(model_dir)

rule targets:
    input:
        'results/performance_results.csv'

rule preprocess_data:
    input:
        R="code/preproc.R",
        csv=config['dataset']
    output:
        rds='results/dat_proc.Rds'
    params:
        outcome_colname=outcome_colname
    resources:
        ncores=ncores
    conda:
        "config/environment.yml"
    shell:
        "Rscript --max-ppsize=500000 {input.R} {resources.ncores} {input.csv} {params} {output}"

rule run_ml:
    input:
        R="code/ml.R",
        rds=rules.preprocess_data.output.rds
    output:
        model="results/models/{method}_{seed}_model.Rds",
        perf=temp("results/models/{method}_{seed}_performance.csv"),
    params:
        outcome_colname=outcome_colname,
        method="{method}",
        seed="{seed}",
    resources:
        ncores=ncores
    conda:
        "config/environment.yml"
    script:
        "code/ml.R"

rule combine_results:
    input:
        R="code/combine_results.R",
        csv=expand("results/models/{method}_{seed}_performance.csv", method = ml_methods, seed = seeds)
    output:
        csv='results/performance_results.csv'
    conda:
        "config/environment.yml"
    script:
        "code/combine_results.R"
