#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CAPHEINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/veg/CAPHEINE
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CAPHEINE  } from './workflows/capheine'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_capheine_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_capheine_pipeline'
include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_capheine_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// TODO nf-core: Remove this line if you don't need a FASTA file
//   This is an example of how to use getGenomeAttribute() to fetch parameters
//   from igenomes.config using `--genome`
// params.fasta = getGenomeAttribute('fasta')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow HYPHY_CAPHEINE {

    take:
    //samplesheet // channel: samplesheet read in from --input
    ch_reference // channel: path(reference_genes.fasta)
    ch_unaligned // channel: path(unaligned_sequences.fasta)
    foreground_list // channel: path(foreground_sequences.fasta)
    foreground_regexp // channel: string

    main:
    //
    // WORKFLOW: Run pipeline
    //
    // samplesheet was replaced with ch_reference and ch_unaligned
    CAPHEINE (
        ch_reference,
        ch_unaligned,
        foreground_list,
        foreground_regexp
    )
    emit:
    multiqc_report = CAPHEINE.out.multiqc_report // channel: /path/to/multiqc_report.html
    fel_results      = CAPHEINE.out.fel_results
    meme_results     = CAPHEINE.out.meme_results
    prime_results    = CAPHEINE.out.prime_results
    busted_results   = CAPHEINE.out.busted_results
    contrastfel_results = CAPHEINE.out.contrastfel_results
    relax_results    = CAPHEINE.out.relax_results
    summary_csv            = CAPHEINE.out.summary_csv
    sites_csv              = CAPHEINE.out.sites_csv
    comparison_summary_csv = CAPHEINE.out.comparison_summary_csv
    comparison_sites_csv   = CAPHEINE.out.comparison_sites_csv
    versions       = CAPHEINE.out.versions
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.reference_genes,
        params.unaligned_seqs
    )

    //
    // WORKFLOW: Run main workflow
    //
    //PIPELINE_INITIALISATION.out.samplesheet replaced with params.reference_genes and params.unaligned_seqs
    HYPHY_CAPHEINE (
        PIPELINE_INITIALISATION.out.ref_genes,
        PIPELINE_INITIALISATION.out.unaligned,
        PIPELINE_INITIALISATION.out.foreground_list,
        PIPELINE_INITIALISATION.out.foreground_regexp
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        HYPHY_CAPHEINE.out.multiqc_report
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
