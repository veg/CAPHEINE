process REMOVETERMINALSTOPCODON {
    tag "${meta}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython:1.79':
        'biocontainers/biopython:1.79' }"

    input:
    path ref_fasta

    output:
    path "${ref_fasta.baseName}-noStopCodons.${ref_fasta.extension}", emit: clean_ref_fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python3 ${projectDir}/bin/remove-terminal-stop-codon.py \\
    --input ${ref_fasta} \\
    --output ${ref_fasta.baseName}-noStopCodons.${ref_fasta.extension} \\
    --table 'Standard'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
        biopython: \$(python3 -c "import Bio; print(Bio.__version__)")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    echo $args
    touch ${ref_fasta.baseName}-noStopCodons.${ref_fasta.extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //g')
        biopython: \$(python3 -c "import Bio; print(Bio.__version__)")
    END_VERSIONS
    """
}
