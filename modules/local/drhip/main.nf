// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process DRHIP {
    label 'process_low'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/drhip:0.1.1--pyhdfd78af_0':
        'biocontainers/drhip:0.1.1--pyhdfd78af_0' }"

    input:
    path fel_results
    path meme_results
    path prime_results
    path busted_results
    path contrastfel_results
    path relax_results

    output:
    path "${params.outdir}/combined_summary.csv",              emit: summary_csv
    path "${params.outdir}/combined_sites.csv",                emit: sites_csv
    path "${params.outdir}/combined_comparison_summary.csv",   optional: true, emit: comparison_summary_csv
    path "${params.outdir}/combined_comparison_sites.csv",     optional: true, emit: comparison_sites_csv
    path "${params.outdir}/versions.yml",                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    drhip \\
        --input ${params.outdir} \\
        --output ${params.outdir}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drhip: \$(drhip --version | sed 's/drhip //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """    
    touch ${params.outdir}/combined_summary.csv
    touch ${params.outdir}/combined_sites.csv
    touch ${params.outdir}/combined_comparison_summary.csv
    touch ${params.outdir}/combined_comparison_sites.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drhip: \$(drhip --version | sed 's/drhip //g')
    END_VERSIONS
    """
    }
