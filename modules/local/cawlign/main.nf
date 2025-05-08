// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.

process CAWLIGN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cawlign:0.1.11--he91c24d_0':
        'biocontainers/cawlign:0.1.11--he91c24d_0' }"

    input:
    tuple val(meta), path(reference)  // gene ID and path to gene reference sequence
    tuple val(meta), path(unaligned)  // path to bulk unaligned sequences

    output:
    tuple val(meta), path("${meta.id}-aligned.fasta"), emit: aligned_seqs
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    """
    cawlign \\
        -t codon \\
        -r ${reference} \\
        -f refmap \\
        -s BLOSUM62 \\
        \"${unaligned}\" \\
        > ${prefix}-aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cawlign: \$(cawlign --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}-aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cawlign: \$(cawlign --version)
    END_VERSIONS
    """
}
