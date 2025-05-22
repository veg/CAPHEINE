# CAPHEINE: Output

## Introduction

CAPHEINE (Comprehensive Automated Pipeline using HyPhy for Evolutionary Inference with NExtflow) is a bioinformatics pipeline designed for evolutionary analysis of viral sequence data. This document describes the output produced by the pipeline, which integrates multiple tools for sequence alignment, phylogenetic analysis, and selection pressure analysis.

## Pipeline Overview

The CAPHEINE pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data through several key stages:

1. **Sequence Preprocessing**
   - Input validation
   - Removal of sequences with ambiguous bases
   - Codon-aware sequence alignment to a reference gene sequence

2. **Phylogenetic Analysis**
   - Phylogenetic tree construction
   - Tree annotation and labeling

3. **Selection Pressure Analysis**
   - FEL (Fixed Effects Likelihood) analysis
   - MEME (Mixed Effects Model of Evolution) analysis
   - PRIME (PRoperty Informed Models of Evolution) analysis
   - BUSTED (Branch-Site Unrestricted Statistical Test for Episodic Diversification) analysis
   - Contrast-FEL analysis (when foreground branches are specified)
   - RELAX analysis (when foreground branches are specified)

4. **Quality Control and Reporting**
   - Pipeline execution metrics

## Output Files

### 1. Sequence Preprocessing

- `processed_sequences/`
  - `*_cleaned.fasta`: Sequences after removal of ambiguous bases
  - `*_aligned.fasta`: Multiple sequence alignment (MSA) in FASTA format
  - `*_deduplicated.fasta`: Final processed alignment after removing duplicates

### 2. Phylogenetic Analysis

- `trees/`
  - `*.treefile`: Phylogenetic tree in Newick format
  - `*.log`: Log file from IQ-TREE
  - `*.ckp.gz`: Checkpoint file (can be used to resume analysis)

### 3. Selection Pressure Analysis

#### FEL (Fixed Effects Likelihood)
- `fel/`
  - `*.FEL.json`: JSON output with selection statistics

#### MEME (Mixed Effects Model of Evolution)
- `meme/`
  - `*.MEME.json`: JSON output with episodic diversifying selection results

#### PRIME
- `prime/`
  - `*.PRIME.json`: JSON output with PRIME analysis results

#### BUSTED
- `busted/`
  - `*.BUSTED.json`: JSON output with BUSTED analysis

#### Contrast-FEL (when foreground branches specified)
- `contrastfel/`
  - `*.CONTRAST-FEL.json`: JSON output with branch-specific selection results

#### RELAX (when foreground branches specified)
- `relax/`
  - `*.RELAX.json`: JSON output with RELAX analysis

### 4. Quality Control and Reports

- `pipeline_info/`
  - `execution_report.html`: Nextflow execution report
  - `execution_timeline.html`: Timeline of pipeline execution
  - `execution_trace.txt`: Detailed execution trace
  - `pipeline_dag.dot`/`pipeline_dag.svg`: Pipeline workflow visualization
  - `software_versions.yml`: Software versions used in the analysis
  - `pipeline_report.html`: Pipeline execution summary
  - `pipeline_report.txt`: Text version of the pipeline report
  - `samplesheet.valid.csv`: Validated input samplesheet
  - `params.json`: Parameters used for the pipeline run

## Output Interpretation

### Selection Analysis Results

1. **FEL Results**:
   - Look for sites with p-value < 0.05 (or your chosen significance threshold)
   - Negative beta values indicate purifying selection
   - Positive beta values indicate positive selection

2. **MEME Results**:
   - Identifies sites under episodic positive selection
   - Look for sites with p-value < 0.05

3. **BUSTED Results**:
   - Tests for gene-wide evidence of positive selection
   - Significant p-value indicates evidence of positive selection

4. **Contrast-FEL Results**:
   - Identifies sites with different selection pressures between foreground and background branches
   - Look for sites with significant p-values

5. **RELAX Results**:
   - Tests for relaxed or intensified selection on foreground branches
   - k < 1 suggests relaxation, k > 1 suggests intensification

## Notes

- All JSON outputs can be parsed programmatically for downstream analysis
- Intermediate files are preserved for additional analyses if needed

For more detailed information about specific analyses, please refer to the respective tool documentation:

- [HyPhy Documentation](http://hyphy.org)
- [IQ-TREE Documentation](http://www.iqtree.org/doc)
- [Cawlign Documentation](https://github.com/veg/cawlign)