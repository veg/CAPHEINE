# CAPHEINE: Usage

## Introduction

## Input files and parameters

The CAPHEINE pipeline requires you to provide input files directly via command line flags. There is no longer a samplesheet input.

- `--reference_genes` (required): Path to a FASTA file containing reference gene sequences.
- `--unaligned_seqs` (required): Path to a FASTA file containing unaligned DNA sequences.
- `--outdir` (required): Output directory for results.
- `--foreground_list` (optional): Path to a text file with a newline-separated list of foreground taxa.
- `--foreground_regexp` (optional): Regular expression string to match foreground taxa.
- `--test_branches` (optional): Branch selection for HyPhy site-wise analyses. Use `internal` to test only internal branches, or `all` to test all branches. If unset, no flag is passed and HyPhy defaults to all branches.
- `--use_mpi` (optional): Run MPI-enabled HyPhy analyses (FEL, MEME, PRIME; Contrast-FEL when foreground branches are provided). BUSTED and RELAX run without MPI. Default: false.

Only one of `--foreground_list` or `--foreground_regexp` should be provided per run (if either is used).

> [!NOTE]
> Contrast-FEL and RELAX are run only if you provide either `--foreground_list` or `--foreground_regexp`. Otherwise, these analyses are skipped.

Example usage:

```bash
nextflow run veg/CAPHEINE \
  --reference_genes ./reference_genes.fasta \
  --unaligned_seqs ./unaligned_seqs.fasta \
  --outdir ./results \
  -profile docker
```

With a foreground taxa list:

```bash
nextflow run veg/CAPHEINE \
  --reference_genes ./reference_genes.fasta \
  --unaligned_seqs ./unaligned_seqs.fasta \
  --foreground_list ./foreground_taxa.txt \
  --outdir ./results \
  -profile docker
```

With a foreground taxa regular expression:

```bash
nextflow run veg/CAPHEINE \
  --reference_genes ./reference_genes.fasta \
  --unaligned_seqs ./unaligned_seqs.fasta \
  --foreground_regexp '^Homo.*' \
  --outdir ./results \
  -profile docker
```

Selecting HyPhy branches explicitly (internal branches only):

```bash
nextflow run veg/CAPHEINE \
  --reference_genes ./reference_genes.fasta \
  --unaligned_seqs ./unaligned_seqs.fasta \
  --test_branches internal \
  --outdir ./results \
  -profile docker
```

Selecting HyPhy branches explicitly (all branches):

```bash
nextflow run veg/CAPHEINE \
  --reference_genes ./reference_genes.fasta \
  --unaligned_seqs ./unaligned_seqs.fasta \
  --test_branches all \
  --outdir ./results \
  -profile docker
```

Running with MPI-enabled HyPhy:

```bash
nextflow run veg/CAPHEINE \
  --reference_genes ./reference_genes.fasta \
  --unaligned_seqs ./unaligned_seqs.fasta \
  --use_mpi \
  --outdir ./results \
  -profile docker
```

> [!NOTE]
> Using `--use_mpi` requires a container runtime or environment with MPI. The `HYPHYMPI` binary is bundled with the docker containers and the conda packages, and should be available by default. Each MPI job uses the number of CPUs configured for the process (`mpirun -np $task.cpus`).

All of the above commands will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run veg/CAPHEINE -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
reference_genes: "./reference_genes.fasta"
unaligned_seqs: "./unaligned_seqs.fasta"
outdir: "./results/"
# Optional (uncomment to use):
# foreground_list: './foreground_taxa.txt'
# foreground_regexp: '^Homo.*'
# test_branches: internal   # or 'all'; if unset, HyPhy runs on all branches by default
# use_mpi: true              # enable MPI-enabled HyPhy (default: false)
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the command below, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull veg/CAPHEINE
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [CAPHEINE releases page](https://github.com/veg/CAPHEINE/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster-specific paths to files, nor institutional-specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility. However, when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

You may also load additional configuration profiles at run time if you supply custom configuration files (for example via `-c <file>` or profiles bundled in this repository). Consult the Nextflow documentation for configuration profiles.

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. You can use Nextflow's error and retry strategies to resubmit tasks with increased resources when appropriate.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline step for a particular tool. By default, this pipeline uses containers and software from the [BioContainers](https://biocontainers.pro/) or [Bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

This pipeline may not expose every possible argument of each tool. Fortunately, nf-core-style pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default. Where needed, you can extend or override arguments in your own configuration using Nextflow's `withLabel:` selectors and module argument patterns.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues with custom configs, please send the nf-core team a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
