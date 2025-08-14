process HYPHYMPI_BUSTED {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy-mpi:v2.3.14dfsg-1-deb_cv1':
        'biocontainers/hyphy-mpi:v2.3.14dfsg-1-deb_cv1' }"

    input:
    tuple val(meta), path(alignment)
    tuple val(meta), path(tree)

    output:
    tuple val(meta), path("*.BUSTED.json"), emit: busted_json
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p BUSTED

    mpirun -np $task.cpus HYPHYMPI busted \\
        --alignment $alignment \\
        --tree $tree \\
        --branches 'Internal' \\
        --srv Yes \\
        --error-sink Yes \\
        --output BUSTED/${meta.id}.BUSTED.json \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphympi: \$(HYPHYMPI --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    touch BUSTED/${prefix}.BUSTED.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphympi: \$(HYPHYMPI --version)
    END_VERSIONS
    """
}
