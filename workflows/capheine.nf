/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PROCESS_VIRAL_NONRECOMBINANT } from '../subworkflows/local/process_viral_nonrecombinant/main'
include { HYPHY_ANALYSES         } from '../subworkflows/local/hyphy_analyses/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_capheine_pipeline'
include { DRHIP                  } from '../modules/local/drhip/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CAPHEINE {

    take:
    ch_reference
    ch_unaligned
    ch_foreground_list // channel: path(foreground_sequences.fasta)
    ch_foreground_regexp // channel: string

    main:
    ch_multiqc_files = Channel.empty()
    ch_versions = Channel.empty()

    // preprocessing output channels
    ch_processed_aln = Channel.empty()
    ch_processed_trees = Channel.empty()

    // hyphy output channels
    ch_fel = Channel.empty()
    ch_meme = Channel.empty()
    ch_prime = Channel.empty()
    ch_busted = Channel.empty()
    ch_contrastfel = Channel.empty()
    ch_relax = Channel.empty()

    // if (params.foreground_list || params.foreground_regexp) {
    //     has_foreground_list        = true
    // } else {
    //     has_foreground_list        = false
    // }


    //
    // SUBWORKFLOW: Run preprocessing of viral non-recombinant viral data
    //
    PROCESS_VIRAL_NONRECOMBINANT (
        ch_unaligned,
        ch_reference,
        ch_foreground_list,
        ch_foreground_regexp
    )
    ch_processed_aln = ch_processed_aln.mix(PROCESS_VIRAL_NONRECOMBINANT.out.deduplicated)
    ch_processed_trees = ch_processed_trees.mix(PROCESS_VIRAL_NONRECOMBINANT.out.tree)
    ch_versions = ch_versions.mix(PROCESS_VIRAL_NONRECOMBINANT.out.versions)

    //
    // PROCESSING: Merge alignments & trees into a single channel for HYPHY analyses
    //
    // Combine channels using join, matching on the meta.id
    ch_processed_aln
        .combine(ch_processed_trees, by: 0)
        .map { meta, aln, tree ->
            if (!aln) {
                log.warn "Skipping ${meta.id}: missing alignment file"
                return null
            }
            if (!tree) {
                log.warn "Skipping ${meta.id}: missing tree file"
                return null
            }
            return [meta, aln, tree]
        }
        .filter { it != null }
        .set { ch_hyphy_input }

    //
    // SUBWORKFLOW: Run Hyphy Analyses
    //
    HYPHY_ANALYSES (
        ch_hyphy_input
    )
    ch_fel      = ch_fel.mix(HYPHY_ANALYSES.out.fel_json)
    ch_meme     = ch_meme.mix(HYPHY_ANALYSES.out.meme_json)
    ch_prime    = ch_prime.mix(HYPHY_ANALYSES.out.prime_json)
    ch_busted   = ch_busted.mix(HYPHY_ANALYSES.out.busted_json)
    ch_contrastfel = ch_contrastfel.mix(HYPHY_ANALYSES.out.contrastfel_json)
    ch_relax    = ch_relax.mix(HYPHY_ANALYSES.out.relax_json)
    ch_versions = ch_versions.mix(HYPHY_ANALYSES.out.versions)

    //
    // MODULE: Run DRHIP to process the hyphy data into csv files
    //

    DRHIP(
        // Extract only the file paths from [meta, file] tuples
        ch_fel.map{ meta, file -> file }.collect(),
        ch_meme.map{ meta, file -> file }.collect(),
        ch_prime.map{ meta, file -> file }.collect(),
        ch_busted.map{ meta, file -> file }.collect(),
        ch_contrastfel ? ch_contrastfel.map{ meta, file -> file }.collect() : Channel.empty(),  // null pointer exception is happening here, I think
        ch_relax    ? ch_relax.map{ meta, file -> file }.collect() : Channel.empty()  // I think the mapping fails if the channel is empty
    )
    def ch_summary_csv = DRHIP.out.summary_csv
    def ch_sites_csv = DRHIP.out.sites_csv
    def ch_comparison_summary_csv = DRHIP.out.comparison_summary_csv ?: Channel.empty()
    def ch_comparison_site_csv    = DRHIP.out.comparison_site_csv    ?: Channel.empty()
    ch_versions = ch_versions.mix(DRHIP.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'capheine_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml",
        checkIfExists: true
    )
    ch_multiqc_custom_config = params.multiqc_config
        ? Channel.fromPath(params.multiqc_config, checkIfExists: true)
        : Channel.empty()
    ch_multiqc_logo = params.multiqc_logo
        ? Channel.fromPath(params.multiqc_logo, checkIfExists: true)
        : Channel.empty()

    summary_params = paramsSummaryMap(
        workflow,
        parameters_schema: "nextflow_schema.json"
    )
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
    )
    ch_multiqc_custom_methods_description = params.multiqc_methods_description
        ? file(params.multiqc_methods_description, checkIfExists: true)
        : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description)
    )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )


    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
        multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
        fel_results      = ch_fel
        meme_results     = ch_meme
        prime_results    = ch_prime
        busted_results   = ch_busted
        contrastfel_results = ch_contrastfel
        relax_results    = ch_relax
        summary_csv            = ch_summary_csv
        sites_csv              = ch_sites_csv
        comparison_summary_csv = ch_comparison_summary_csv
        comparison_site_csv   = ch_comparison_site_csv
        versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
