// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process HYPHY_LABELTREE_REGEXP {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.81--hbee74ec_0' :
        'biocontainers/hyphy:2.5.81--hbee74ec_0' }"

    input:
    tuple val(meta), path(in_tree)      // input tree to be labeled
    val(regexp)     // regexp to match sequences to label
    val(invert)     // whether or not to invert the match (ie. match everything except the regexp). "Yes" or "No"
    val(label)      // label to apply
    val(internal_nodes)     // how to label internal nodes. "All descendants" or "None"
    val(leaf_nodes)     // how to label leaf nodes. "Label" or "Skip"

    output:
    tuple val(meta), path("LABELTREE/${meta}-labeled.${in_tree.extension}"), emit: labeled_tree
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    def out_tree = "${prefix}-labeled.${in_tree.extension}"

    """
    mkdir -p LABELTREE

    hyphy label-tree \\
        --tree ${in_tree} \\
        --regexp '${regexp}' \\
        --invert '${invert}' \\
        --label '${label}' \\
        --internal-nodes '${internal_nodes}' \\
        --leaf-nodes '${leaf_nodes}' \\
        --output LABELTREE/${out_tree} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    def out_tree = "${prefix}-labeled.${in_tree.extension}"
    """
    mkdir -p LABELTREE
    touch LABELTREE/${out_tree}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}

process HYPHY_LABELTREE_LIST {
    tag "$meta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hyphy:2.5.71--he91c24d_0' :
        'biocontainers/hyphy:2.5.71--he91c24d_0' }"

    input:
    tuple val(meta), path(in_tree)      // input tree to be labeled
    path(in_list)                        // list of sequences to label
    val(invert)     // whether or not to invert the match (ie. match everything except the regexp). "Yes" or "No"
    val(label)      // label to apply
    val(internal_nodes)     // how to label internal nodes. "All descendants" or "None"
    val(leaf_nodes)     // how to label leaf nodes. "Label" or "Skip"


    output:
    tuple val(meta), path("LABELTREE/${meta}-labeled.${in_tree.extension}"), emit: labeled_tree
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    def out_tree = "${prefix}-labeled.${in_tree.extension}"

    """
    mkdir -p LABELTREE

    hyphy label-tree \\
        --tree ${in_tree} \\
        --list ${in_list} \\
        --invert '${invert}' \\
        --label '${label}' \\
        --internal-nodes '${internal_nodes}' \\
        --leaf-nodes '${leaf_nodes}' \\
        --output LABELTREE/${out_tree} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    def out_tree = "${prefix}-labeled.${in_tree.extension}"
    """
    mkdir -p LABELTREE
    touch LABELTREE/${out_tree}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hyphy: \$(hyphy --version | sed 's/HYPHY //g')
    END_VERSIONS
    """
}
