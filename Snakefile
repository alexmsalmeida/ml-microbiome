import os

configfile: 'config/config.yml'

ncores = config['ncores']
ml_methods = config['ml_methods']
kfold = config['kfold']
outcome_colname = config['outcome_colname']

nseeds = config['nseeds']
start_seed = 100
seeds = range(start_seed, start_seed + nseeds)

log_dir = "results/logs/hpc/jobs"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

rule targets:
    input:
        'results/report.md'

rule preprocess_data:
    input:
        R="code/preproc.R",
        csv=config['dataset']
    output:
        rds='results/dat_proc.Rds'
    log:
        "results/logs/preprocess_data.txt"
    benchmark:
        "results/benchmarks/preprocess_data.txt"
    params:
        outcome_colname=outcome_colname
    resources:
        ncores=ncores
    conda:
        "config/environment.yml"
    script:
        "code/preproc.R"

rule run_ml:
    input:
        R="code/ml.R",
        rds=rules.preprocess_data.output.rds
    output:
        model="results/runs/{method}_{seed}_model.Rds",
        perf=temp("results/runs/{method}_{seed}_performance.csv"),
        feat=temp("results/runs/{method}_{seed}_feature-importance.csv")
    log:
        "results/logs/runs/run_ml.{method}_{seed}.txt"
    benchmark:
        "results/benchmarks/runs/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname=outcome_colname,
        method="{method}",
        seed="{seed}",
        kfold=kfold
    resources:
        ncores=ncores
    conda:
        "config/environment.yml"
    script:
        "code/ml.R"

rule combine_results:
    input:
        R="code/combine_results.R",
        csv=expand("results/runs/{method}_{seed}_{{type}}.csv", method = ml_methods, seed = seeds)
    output:
        csv='results/{type}_results.csv'
    log:
        "results/logs/combine_results_{type}.txt"
    benchmark:
        "results/benchmarks/combine_results_{type}.txt"
    conda:
        "config/environment.yml"
    script:
        "code/combine_results.R"

rule combine_hp_performance:
    input:
        R='code/combine_hp_perf.R',
        rds=expand('results/runs/{{method}}_{seed}_model.Rds', seed=seeds)
    output:
        rds='results/hp_performance_results_{method}.Rds'
    log:
        "results/logs/combine_hp_perf_{method}.txt"
    benchmark:
        "results/benchmarks/combine_hp_perf_{method}.txt"
    conda:
        "config/environment.yml"
    script:
        "code/combine_hp_perf.R"

rule combine_benchmarks:
    input:
        R='code/combine_benchmarks.R',
        tsv=expand(rules.run_ml.benchmark, method = ml_methods, seed = seeds)
    output:
        csv='results/benchmarks_results.csv'
    log:
        'results/logs/combine_benchmarks.txt'
    conda:
        "config/environment.yml"
    script:
        'code/combine_benchmarks.R'

rule plot_performance:
    input:
        R="code/plot_perf.R",
        csv='results/performance_results.csv',
        feat='results/feature-importance_results.csv'   
    output:
        plot='results/figures/performance.png'
    log:
        "results/logs/plot_performance.txt"
    conda:
        "config/environment.yml"
    script:
        "code/plot_perf.R"

rule plot_hp_performance:
    input: 
        R='code/plot_hp_perf.R',
        rds=rules.combine_hp_performance.output.rds,
    output:
        plot='results/figures/hp_performance_{method}.png'
    log:
        'results/logs/plot_hp_perf_{method}.txt'
    conda:
        "config/environment.yml"
    script:
        'code/plot_hp_perf.R'

rule plot_benchmarks:
    input:
        R='code/plot_benchmarks.R',
        csv=rules.combine_benchmarks.output.csv
    output:
        plot='results/figures/benchmarks.png'
    log:
        'results/logs/plot_benchmarks.txt'
    conda:
        "config/environment.yml"
    script:
        'code/plot_benchmarks.R'

rule render_report:
    input:
        Rmd='report.Rmd',
        R='code/render.R',
        perf_plot=rules.plot_performance.output.plot,
        hp_plot=expand(rules.plot_hp_performance.output.plot, method = ml_methods),
        bench_plot=rules.plot_benchmarks.output.plot
    output:
        doc='results/report.md'
    log:
        "results/logs/render_report.txt"
    params:
        nseeds=nseeds,
        ml_methods=ml_methods,
        ncores=ncores,
        kfold=kfold
    conda:
        "config/environment.yml"
    script:
        'code/render.R'

rule clean:
    input:
        rules.render_report.output,
        rules.plot_performance.output.plot,
        rules.plot_benchmarks.output.plot
    shell:
        '''
        rm -rf {input}
        '''
