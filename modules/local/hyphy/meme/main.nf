process HYPHY_MEME {
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

    output:
    tuple val(meta), path("MEME/${meta.id}.MEME.json"), emit: meme_json
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p MEME
    
    hyphy meme \\
        --alignment $alignment \\
        --tree $tree \\
        --branches 'Internal' \\
        --output MEME/${meta.id}.MEME.json \\
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
    mkdir -p MEME
    
    touch MEME/${prefix}.MEME.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
