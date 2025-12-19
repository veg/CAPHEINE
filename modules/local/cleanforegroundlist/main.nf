process CLEAN_FOREGROUND_LIST {
    tag '$taxa_list'
    label 'process_single'

    // no required tool dependencies, but we'll pull biopython anyway so that the module runs if a container is requested
    conda null
    container null

    input:
    path taxa_list

    output:
    path "${taxa_list.baseName}-sanitized.txt", emit: sanitized_list
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    python ${projectDir}/bin/clean-foreground-list.py \\
        --input ${taxa_list} \\
        --output ${taxa_list.baseName}-sanitized.txt \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    echo $args
    
    touch ${taxa_list.baseName}-sanitized.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
