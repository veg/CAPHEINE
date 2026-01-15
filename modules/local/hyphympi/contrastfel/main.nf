process HYPHYMPI_CONTRASTFEL {
    tag "$meta"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.93--hbee74ec_0' :
        'biocontainers/hyphy:2.5.93--hbee74ec_0' }"

    input:
    tuple val(meta), path(alignment), path(tree)
    val(foreground_tag)
    val(reference_tag)

    output:
    tuple val(meta), path("CONTRASTFEL/${meta}.CONTRASTFEL.json"), emit: contrastfel_json
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p CONTRASTFEL

    mpirun -np $task.cpus HYPHYMPI contrast-fel \
        --alignment $alignment \
        --tree $tree \
        --branch-set $foreground_tag \
        --branch-set $reference_tag \
        --output CONTRASTFEL/${meta}.CONTRASTFEL.json \
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
    mkdir -p CONTRASTFEL

    touch CONTRASTFEL/${prefix}.CONTRASTFEL.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(HYPHYMPI --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
