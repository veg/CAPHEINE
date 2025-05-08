include { HYPHY_FEL     } from '../../../modules/local/hyphy/fel/main'
include { HYPHY_MEME    } from '../../../modules/local/hyphy/meme/main'
include { HYPHY_PRIME   } from '../../../modules/local/hyphy/prime/main'
include { HYPHY_BUSTED  } from '../../../modules/local/hyphy/busted/main'
include { HYPHY_CONTRASTFEL  } from '../../../modules/local/hyphy/contrastfel/main'
include { HYPHY_RELAX   } from '../../../modules/local/hyphy/relax/main'

workflow HYPHY_ANALYSES {

    take:
    ch_aln // channel: [ val(meta), [ aln ] ]
    ch_tree // channel: [ val(meta), [ tree ] ]
    ch_branch_set // channel: branch_set

    main:

    ch_versions = Channel.empty()

    // Run FEL analysis
    HYPHY_FEL (
        ch_aln,
        ch_tree
    )
    ch_versions = ch_versions.mix(HYPHY_FEL.out.versions.first())

    // Run MEME analysis
    HYPHY_MEME (
        ch_aln,
        ch_tree
    )
    ch_versions = ch_versions.mix(HYPHY_MEME.out.versions.first())

    // Run PRIME analysis
    HYPHY_PRIME (
        ch_aln,
        ch_tree
    )
    ch_versions = ch_versions.mix(HYPHY_PRIME.out.versions.first())

    // Run BUSTED analysis
    HYPHY_BUSTED (
        ch_aln,
        ch_tree
    )
    ch_versions = ch_versions.mix(HYPHY_BUSTED.out.versions.first())

    // Run Contrast-FEL analysis
    HYPHY_CONTRASTFEL (
        ch_aln,
        ch_tree,
        ch_branch_set
    )
    ch_versions = ch_versions.mix(HYPHY_CONTRASTFEL.out.versions.first())

    // Run RELAX analysis
    HYPHY_RELAX (
        ch_aln,
        ch_tree,
        ch_branch_set
    )
    ch_versions = ch_versions.mix(HYPHY_RELAX.out.versions.first())

    emit:
    fel_json      = HYPHY_FEL.out.fel_json          // channel: [ val(meta), [ fel_json ] ]
    meme_json     = HYPHY_MEME.out.meme_json        // channel: [ val(meta), [ meme_json ] ]
    prime_json    = HYPHY_PRIME.out.prime_json      // channel: [ val(meta), [ prime_json ] ]
    busted_json   = HYPHY_BUSTED.out.busted_json    // channel: [ val(meta), [ busted_json ] ]
    contrastfel_json = HYPHY_CONTRASTFEL.out.contrastfel_json // channel: [ val(meta), [ contrastfel_json ] ]
    relax_json    = HYPHY_RELAX.out.relax_json      // channel: [ val(meta), [ relax_json ] ]
    versions      = ch_versions                     // channel: [ versions.yml ]
}

