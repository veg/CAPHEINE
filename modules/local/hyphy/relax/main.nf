process HYPHY_RELAX {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    // container section can be added as needed

    input:
    tuple val(meta), path(alignment)
    tuple val(meta), path(tree)
    val(test_tag)

    output:
    tuple val(meta), path("${meta.id}.RELAX.json"), emit: relax_json
    path "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    hyphy relax \
        --alignment $alignment \
        --tree $tree \
        --output ${meta.id}.RELAX.json \
        --mode "Classic mode" \
        --test $test_tag \
        --reference "Reference" \
        --srv Yes \
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: $(hyphy --version | sed 's/HyPhy //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.RELAX.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: $(hyphy --version | sed 's/HyPhy //g')
    END_VERSIONS
    """
}
