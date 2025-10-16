include { HYPHYMPI_FEL         } from '../../../modules/local/hyphympi/fel/main'
include { HYPHYMPI_MEME        } from '../../../modules/local/hyphympi/meme/main'
include { HYPHYMPI_PRIME       } from '../../../modules/local/hyphympi/prime/main'
include { HYPHYMPI_BUSTED      } from '../../../modules/local/hyphympi/busted/main'
include { HYPHYMPI_CONTRASTFEL } from '../../../modules/local/hyphympi/contrastfel/main'

workflow HYPHYMPI_ANALYSES {

    take:
    ch_input // channel: [ val(meta), aln, tree ]

    main:
    ch_versions = Channel.empty()
    has_foreground = params.foreground_list || params.foreground_regexp

    // Run FEL analysis (MPI)
    HYPHYMPI_FEL (
        ch_input
    )
    ch_versions = ch_versions.mix(HYPHYMPI_FEL.out.versions)

    // Run MEME analysis (MPI)
    HYPHYMPI_MEME (
        ch_input
    )
    ch_versions = ch_versions.mix(HYPHYMPI_MEME.out.versions)

    // Run PRIME analysis (MPI)
    HYPHYMPI_PRIME (
        ch_input
    )
    ch_versions = ch_versions.mix(HYPHYMPI_PRIME.out.versions)

    // Run BUSTED analysis (MPI)
    HYPHYMPI_BUSTED (
        ch_input
    )
    ch_versions = ch_versions.mix(HYPHYMPI_BUSTED.out.versions)

    // Run Contrast-FEL analysis if branch set is provided
    if (has_foreground) {
        // confirm that the tree is labeled
        ch_input
            .map { it ->
                def tree = it[2]
                if (tree.text.contains("Foreground")) {
                    true
                } else {
                    error "No branches were labeled as 'Foreground' in the tree file ${tree}, but branch set was provided."
                }
            }

        HYPHYMPI_CONTRASTFEL (
            ch_input,
            foreground_tag="Foreground",
            reference_tag="Reference"
        )
        ch_versions = ch_versions.mix(HYPHYMPI_CONTRASTFEL.out.versions)
    }

    emit:
    fel_json         = HYPHYMPI_FEL.out.fel_json                // channel: [ val(meta), [ fel_json ] ]
    meme_json        = HYPHYMPI_MEME.out.meme_json              // channel: [ val(meta), [ meme_json ] ]
    prime_json       = HYPHYMPI_PRIME.out.prime_json            // channel: [ val(meta), [ prime_json ] ]
    busted_json      = HYPHYMPI_BUSTED.out.busted_json          // channel: [ val(meta), [ busted_json ] ]
    contrastfel_json = has_foreground ? HYPHYMPI_CONTRASTFEL.out.contrastfel_json : Channel.empty()
    relax_json       = Channel.empty()
    versions         = ch_versions                               // channel: [ versions.yml ]
}
