workflow HYPHYMPI_ANALYSES {

    take:
    ch_input // channel: [ val(meta), aln, tree ]

    main:
    // Placeholder MPI-enabled HyPhy analyses subworkflow.
    // TODO: Implement MPI versions of FEL, MEME, PRIME, BUSTED, CONTRASTFEL, RELAX.
    log.warn "HYPHYMPI_ANALYSES is a placeholder. No MPI analyses are run yet."

    ch_versions = Channel.empty()
    has_foreground = params.foreground_list || params.foreground_regexp

    // Empty outputs for now to keep pipeline compilable
    ch_fel         = Channel.empty()
    ch_meme        = Channel.empty()
    ch_prime       = Channel.empty()
    ch_busted      = Channel.empty()
    ch_contrastfel = has_foreground ? Channel.empty() : Channel.empty()
    ch_relax       = has_foreground ? Channel.empty() : Channel.empty()

    emit:
    fel_json        = ch_fel           // channel: [ val(meta), [ fel_json ] ]
    meme_json       = ch_meme          // channel: [ val(meta), [ meme_json ] ]
    prime_json      = ch_prime         // channel: [ val(meta), [ prime_json ] ]
    busted_json     = ch_busted        // channel: [ val(meta), [ busted_json ] ]
    contrastfel_json= ch_contrastfel   // channel: [ val(meta), [ contrastfel_json ] ]
    relax_json      = ch_relax         // channel: [ val(meta), [ relax_json ] ]
    versions        = ch_versions      // channel: [ versions.yml ]
}
