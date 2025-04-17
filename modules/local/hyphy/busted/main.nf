process HYPHY_BUSTED {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.71--he91c24d_0' :
        'biocontainers/hyphy:2.5.71--he91c24d_0' }"

    input:
    tuple val(meta), path(alignment)
    tuple val(meta), path(tree)

    output:
    tuple val(meta), path("${meta.id}.BUSTED.json"), emit: busted_json
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    hyphy busted \\
        --alignment $alignment \\
        --tree $tree \\
        --branches 'Internal' \\
        --srv Yes \\
        --error-sink Yes \\
        --output ${meta.id}.BUSTED.json \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    touch ${prefix}.BUSTED.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
