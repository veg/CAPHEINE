process HYPHY_PRIME {
    tag "$meta"
    label 'process_medium'
    cache 'deep'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.81--hbee74ec_0' :
        'biocontainers/hyphy:2.5.81--hbee74ec_0' }"

    input:
    tuple val(meta), path(alignment), path(tree)

    output:
    tuple val(meta), path("PRIME/${meta}.PRIME.json"), emit: prime_json
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p PRIME

    hyphy prime \\
        --alignment $alignment \\
        --tree $tree \\
        --branches 'Internal' \\
        --property-set 'Atchley' \\
        --output PRIME/${meta}.PRIME.json \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"

    """
    mkdir -p PRIME

    touch PRIME/${prefix}.PRIME.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
