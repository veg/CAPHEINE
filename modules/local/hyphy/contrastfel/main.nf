process HYPHY_CONTRASTFEL {
    tag "$meta.id"
    label 'process_single'
    cache 'deep'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.73--he91c24d_0' :
        'biocontainers/hyphy:2.5.73--he91c24d_0' }"

    input:
    tuple val(meta), path(alignment)
    tuple val(meta), path(tree)
    val(branch_set_tag)

    output:
    tuple val(meta), path("CONTRASTFEL/${meta.id}.CONTRASTFEL.json"), emit: contrastfel_json
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p CONTRASTFEL

    hyphy contrast-fel \\
        --alignment $alignment \\
        --tree $tree \\
        --branch-set $branch_set_tag \\
        --output CONTRASTFEL/${meta.id}.CONTRASTFEL.json \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HyPhy //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p CONTRASTFEL

    touch CONTRASTFEL/${prefix}.CONTRASTFEL.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HyPhy //g')
    END_VERSIONS
    """
}
