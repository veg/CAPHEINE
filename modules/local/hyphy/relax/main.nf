process HYPHY_RELAX {
    tag "$meta.id"
    label 'process_single'
    cache 'deep'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.73--he91c24d_0' :
        'biocontainers/hyphy:2.5.73--he91c24d_0' }"

    input:
    tuple val(meta), path(alignment), path(tree)
    val(test_tag)

    output:
    tuple val(meta), path("RELAX/${meta.id}.RELAX.json"), emit: relax_json
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p RELAX

    hyphy relax \\
        --alignment $alignment \\
        --tree $tree \\
        --output RELAX/${meta.id}.RELAX.json \\
        --mode "Classic mode" \\
        --test $test_tag \\
        --reference "Reference" \\
        --srv Yes \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p RELAX

    touch RELAX/${prefix}.RELAX.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
