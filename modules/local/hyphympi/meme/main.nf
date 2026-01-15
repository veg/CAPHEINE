process HYPHYMPI_MEME {
    tag "$meta"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.93--hbee74ec_0' :
        'biocontainers/hyphy:2.5.93--hbee74ec_0' }"

    input:
    tuple val(meta), path(alignment), path(tree)

    output:
    tuple val(meta), path("MEME/${meta}.MEME.json"), emit: meme_json
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    mkdir -p MEME

    mpirun -np $task.cpus HYPHYMPI meme \
        --alignment $alignment \
        --tree $tree \
        --output MEME/${meta}.MEME.json \
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(HYPHYMPI --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    mkdir -p MEME

    touch MEME/${prefix}.MEME.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(HYPHYMPI --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
