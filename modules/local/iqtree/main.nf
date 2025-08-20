process IQTREE {
    tag "$meta"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree:2.4.0--h503566f_0' :
        'biocontainers/iqtree:2.4.0--h503566f_0' }"

    input:
    tuple val(meta), path(alignment)

    output:
    tuple val(meta), path("*.treefile")      , emit: phylogeny     , optional: true
    tuple val(meta), path("*.iqtree")        , emit: report        , optional: true
    tuple val(meta), path("*.mldist")        , emit: mldist        , optional: true
    tuple val(meta), path("*.lmap.svg")      , emit: lmap_svg      , optional: true
    tuple val(meta), path("*.lmap.eps")      , emit: lmap_eps      , optional: true
    tuple val(meta), path("*.lmap.quartetlh"), emit: lmap_quartetlh, optional: true
    tuple val(meta), path("*.sitefreq")      , emit: sitefreq_out  , optional: true
    tuple val(meta), path("*.ufboot")        , emit: bootstrap     , optional: true
    tuple val(meta), path("*.state")         , emit: state         , optional: true
    tuple val(meta), path("*.contree")       , emit: contree       , optional: true
    tuple val(meta), path("*.nex")           , emit: nex           , optional: true
    tuple val(meta), path("*.splits")        , emit: splits        , optional: true
    tuple val(meta), path("*.suptree")       , emit: suptree       , optional: true
    tuple val(meta), path("*.alninfo")       , emit: alninfo       , optional: true
    tuple val(meta), path("*.partlh")        , emit: partlh        , optional: true
    tuple val(meta), path("*.siteprob")      , emit: siteprob      , optional: true
    tuple val(meta), path("*.sitelh")        , emit: sitelh        , optional: true
    tuple val(meta), path("*.treels")        , emit: treels        , optional: true
    tuple val(meta), path("*.rate  ")        , emit: rate          , optional: true
    tuple val(meta), path("*.mlrate")        , emit: mlrate        , optional: true
    tuple val(meta), path("GTRPMIX.nex")     , emit: exch_matrix   , optional: true
    tuple val(meta), path("*.log")           , emit: log
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args                        = task.ext.args           ?: ''
    def alignment_arg               = alignment               ? "-s ${alignment.join(',')}"     : ''
    def prefix                      = task.ext.prefix         ?: meta
    def memory                      = task.memory.toString().replaceAll(' ', '')
    """
    iqtree \\
        $alignment_arg \\
        $args \\
        -pre $prefix \\
        -nt AUTO \\
        -ntmax $task.cpus \\
        -mem $memory

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: meta
    """
    touch "${prefix}.treefile"
    touch "${prefix}.iqtree"
    touch "${prefix}.mldist"
    touch "${prefix}.lmap.svg"
    touch "${prefix}.lmap.eps"
    touch "${prefix}.lmap.quartetlh"
    touch "${prefix}.sitefreq"
    touch "${prefix}.ufboot"
    touch "${prefix}.state"
    touch "${prefix}.contree"
    touch "${prefix}.nex"
    touch "${prefix}.splits"
    touch "${prefix}.suptree"
    touch "${prefix}.alninfo"
    touch "${prefix}.partlh"
    touch "${prefix}.siteprob"
    touch "${prefix}.sitelh"
    touch "${prefix}.treels"
    touch "${prefix}.rate"
    touch "${prefix}.mlrate"
    touch "GTRPMIX.nex"
    touch "${prefix}.log"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """

}
