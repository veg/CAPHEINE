process HYPHY_RELAX {
    tag "$meta"
    label 'process_medium'
    cache 'deep'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.73--he91c24d_0' :
        'biocontainers/hyphy:2.5.73--he91c24d_0' }"

    input:
    tuple val(meta), path(alignment), path(tree)
    val(foreground_tag)
    val(reference_tag)

    output:
    tuple val(meta), path("RELAX/${meta}.RELAX.json"), emit: relax_json
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def tree_arg = (tree && !(tree instanceof List && tree.isEmpty())) ? "--tree ${tree}" : ''
    """
    mkdir -p RELAX

    hyphy relax \\
        --alignment $alignment \\
        $tree_arg \\
        --output RELAX/${meta}.RELAX.json \\
        --mode "Classic mode" \\
        --test $foreground_tag \\
        --reference $reference_tag \\
        --srv Yes \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    mkdir -p RELAX

    touch RELAX/${prefix}.RELAX.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
