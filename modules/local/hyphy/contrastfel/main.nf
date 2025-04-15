process HYPHY_CONTRASTFEL {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    // container section can be added as needed

    input:
    tuple val(meta), path(alignment)
    tuple val(meta), path(tree)
    val(branch_set_tag)

    output:
    tuple val(meta), path("${meta.id}.CONTRASTFEL.json"), emit: contrastfel_json
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    hyphy contrast-fel \\
        --alignment $alignment \\
        --tree $tree \\
        --branch-set $branch_set_tag \\
        --output ${meta.id}.CONTRASTFEL.json \\
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
    touch ${prefix}.CONTRASTFEL.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HyPhy //g')
    END_VERSIONS
    """
}
