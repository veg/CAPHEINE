// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { HYPHY_FEL     } from '../../../modules/local/hyphy/fel/main'

workflow HYPHY_ANALYSES {

    take:
    // TODO nf-core: edit input (take) channels
    ch_aln // channel: [ val(meta), [ aln ] ]
    ch_tree // channel: [ val(meta), [ tree ] ]

    main:

    ch_versions = Channel.empty()

    // TODO nf-core: substitute modules here for the modules of your subworkflow

    HYPHY_FEL ( 
        alignment: ch_aln
        tree: ch_tree 
    )
    ch_versions = ch_versions.mix(HYPHY_FEL.out.versions.first())

    // SAMTOOLS_INDEX ( SAMTOOLS_SORT.out.bam )
    // ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    emit:
    fel_json      = HYPHY_FEL.out.fel_json          // channel: [ val(meta), [ fel_json ] ]
    // bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    // csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

