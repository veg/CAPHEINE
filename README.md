<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-capheine_logo_dark.png">
    <img alt="CAPHEINE" src="docs/images/nf-core-capheine_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/veg/CAPHEINE/actions/workflows/ci.yml/badge.svg)](https://github.com/veg/CAPHEINE/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/veg/CAPHEINE/actions/workflows/linting.yml/badge.svg)](https://github.com/veg/CAPHEINE/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/capheine/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**CAPHEINE** is a bioinformatics pipeline designed for comparative analysis of protein-coding genes using the HyPhy software suite. The pipeline ingests FASTA files containing raw DNA sequences along with FASTA files containing reference gene sequences, and performs multiple sequence alignment, phylogenetic tree construction, and various selection analyses. Key outputs include statistical tests for positive selection (BUSTED, FEL, MEME), branch-site models, and comprehensive quality control reports, all presented in an easy-to-interpret MultiQC report.

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->

1. Sequence validation ([`FASTAValidator`](https://github.com/evolbioinfo/fastavalidator))
2. Ambiguous sequence removal
3. Multiple sequence alignment ([`cawlign`](https://github.com/evolbioinfo/cawlign))
4. Sequence deduplication and cleaning ([`HyPhy CLN`](https://hyphy.org/methods/selection-methods/))
5. Phylogenetic tree construction ([`IQ-TREE`](http://www.iqtree.org/))
6. Selection analyses using HyPhy:
   - [FEL](https://hyphy.org/methods/selection-methods/#FEL) (Fixed Effects Likelihood)
   - [MEME](https://hyphy.org/methods/selection-methods/#MEME) (Mixed Effects Model of Evolution)
   - [PRIME](https://hyphy.org/methods/selection-methods/#PRIME) (Probabilistic Inference of Molecular Evolution)
   - [BUSTED](https://hyphy.org/methods/selection-methods/#BUSTED) (Branch-Site Unrestricted Statistical Test for Episodic Diversification)
7. Optional branch-specific analyses when foreground branches are specified:
   - [Contrast-FEL](https://hyphy.org/methods/selection-methods/#CONTRAST-FEL)
   - [RELAX](https://hyphy.org/methods/selection-methods/#RELAX)
8. Report generation ([`MultiQC`](http://multiqc.info/))



## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):  -->

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv title="samplesheet.csv"
sample,raw_sequences,ref_sequence,foreground_seqs,foreground_regexp
Gene1,raw-seqs.fasta,Gene1_ref.fasta,,foreground_regexp
Gene2,raw-seqs.fasta,Gene2_ref.fasta,foreground_taxa.txt,
```

Each row represents a single reference gene, with the raw sequences to be aligned to it, and optional foreground taxa. The `foreground_seqs` column should contain a text file with a newline-separated list of foreground taxa, while the `foreground_regexp` column should contain a regular expression to match foreground taxa. Only one of these columns should be provided per row.


Now, you can run the pipeline using:

```bash
nextflow run veg/CAPHEINE \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](docs/usage.md).

## Testing the pipeline

To test the pipeline, you can run it with the `-profile test` option. This will run the pipeline with a minimal test dataset to check that it completes without any syntax errors.

```bash
nextflow run veg/CAPHEINE \
-profile test,docker \
--outdir <OUTDIR>
```

## Pipeline output

For more details about the output files and reports, please refer to the
[output documentation](docs/output.md).

## Credits

CAPHEINE was originally written by Hannah Verdonk and Danielle Callan.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch by creating a github issue!

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use CAPHEINE for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
