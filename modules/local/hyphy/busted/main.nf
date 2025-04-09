process HYPHY_BUSTED {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(meta), path(alignment), path(tree)

    output:
    tuple val(meta), path("${meta.id}.BUSTED.json"), emit: busted_json
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    hyphy BUSTED \\
        --alignment $alignment \\
        --tree $tree \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HyPhy //g')
    END_VERSIONS
    """
}
