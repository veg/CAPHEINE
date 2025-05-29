// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process HYPHY_REMOVEDUPS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.73--he91c24d_0':
        'biocontainers/hyphy:2.5.73--he91c24d_0' }"

    input:
    tuple val(meta), path(in_msa)

    output:
    tuple val(meta), path("REMOVEDUPS/${meta.id}-nodups.${in_msa.extension}"), emit: deduplicated_seqs
    path "versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"


    """
    mkdir -p REMOVEDUPS

    hyphy remove-duplicates \\
        --msa ${in_msa} \\
        --output REMOVEDUPS/${meta.id}-nodups.${in_msa.extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p REMOVEDUPS
    touch REMOVEDUPS/${meta.id}-nodups.${in_msa.extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
