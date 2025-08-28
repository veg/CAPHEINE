process HYPHYMPI_BUSTED {
    tag "$meta"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.73--he91c24d_0' :
        'biocontainers/hyphy:2.5.73--he91c24d_0' }"

    input:
    tuple val(meta), path(alignment), path(tree)

    output:
    tuple val(meta), path("BUSTED/${meta}.BUSTED.json"), emit: busted_json
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    mkdir -p BUSTED

    mpirun -np $task.cpus HYPHYMPI busted \\
        --alignment $alignment \\
        --tree $tree \\
        --branches 'Internal' \\
        --srv Yes \\
        --error-sink Yes \\
        --output BUSTED/${meta}.BUSTED.json \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphympi: \$(HYPHYMPI --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    mkdir -p BUSTED
    
    touch BUSTED/${prefix}.BUSTED.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphympi: \$(HYPHYMPI --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
