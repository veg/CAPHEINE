process CAWLIGN {
    tag "${reference.baseName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cawlign:0.1.15--he91c24d_0':
        'biocontainers/cawlign:0.1.15--he91c24d_0' }"

    input:
    path reference  // path to gene reference sequence in FASTA format
    path unaligned  // path to bulk unaligned sequences in FASTA format

    output:
    tuple val("${reference.baseName}"), path("${reference.baseName}-aligned.fasta") , emit: aligned_seqs
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: reference.baseName
    def args = task.ext.args ?: ''

    """
    cawlign \\
        -t codon \\
        -r ${reference} \\
        -f refmap \\
        -s BLOSUM62 \\
        ${args} \\
        \"${unaligned}\" \\
        > ${prefix}-aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cawlign: \$(cawlign --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: reference.baseName
    """
    touch ${prefix}-aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cawlign: \$(cawlign --version)
    END_VERSIONS
    """
}
