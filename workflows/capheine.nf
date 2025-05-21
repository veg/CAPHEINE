/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PROCESS_VIRAL_NONRECOMBINANT } from '../subworkflows/local/process_viral_nonrecombinant/main'
include { HYPHY_ANALYSES         } from '../subworkflows/local/hyphy_analyses/main'
include { FASTAVALIDATOR         } from '../modules/nf-core/fastavalidator/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_capheine_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CAPHEINE {

    take:
    ch_input    // channel: [ meta, path(raw_sequences.fasta), path(reference_sequence.fasta) ]. Input is directly from the samplesheet, via --input

    main:
    ch_multiqc_files = Channel.empty()
    ch_versions = Channel.empty()
    ch_unaligned = Channel.empty()
    ch_reference = Channel.empty()

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

    // set up channels from input samplesheet
    ch_input
        .filter { it ->
            if (it[1].size() == 0) {
                println "Skipping entry with no raw sequences: ${it}"
                return false
            }
            return true
        }
        .map {
            meta, fasta, ref ->
                [ meta, file(fasta) ]
        }
        .set { ch_unaligned }

    ch_input
        .filter { it ->
            if (it[2].size() == 0) {
                println "Skipping entry with no reference sequence: ${it}"
                return false
            }
            return true
        }
        .map {
            meta, fasta, ref ->
                [ meta, file(ref) ]
        }
        .set { ch_reference }

    if (params.foreground_seqs && params.foreground_regexp) {
        error "ERROR: either a file of foreground sequences OR a regular expression matching foreground sequences can be provided, not both. Please ensure that only one parameter is provided."
    } else if (params.foreground_seqs) {
        ch_foreground_seqs         = file(params.foreground_seqs, checkIfExists: true)
        ch_foreground_regexp       = []
        has_foreground_seqs        = true
    } else if (params.foreground_regexp) {
        ch_foreground_seqs         = []
        ch_foreground_regexp       = params.foreground_regexp
        has_foreground_seqs        = true
    } else {
        ch_foreground_seqs         = []
        ch_foreground_regexp       = []
        has_foreground_seqs        = false
    }

    //
    // VALIDATE REFERENCE SEQUENCE
    //
    FASTAVALIDATOR(ch_reference)
    ch_versions = ch_versions.mix(FASTAVALIDATOR.out.versions)

    //
    // SUBWORKFLOW: Run preprocessing of viral non-recombinant viral data
    //
    PROCESS_VIRAL_NONRECOMBINANT (
        ch_unaligned,
        ch_reference,
        ch_foreground_seqs,
        ch_foreground_regexp
    )
    ch_processed_aln = ch_processed_aln.mix(PROCESS_VIRAL_NONRECOMBINANT.out.deduplicated)
    ch_processed_trees = ch_processed_trees.mix(PROCESS_VIRAL_NONRECOMBINANT.out.tree)
    ch_versions = ch_versions.mix(PROCESS_VIRAL_NONRECOMBINANT.out.versions.first())

    //
    // SUBWORKFLOW: Run Hyphy Analyses
    //
    HYPHY_ANALYSES (
        ch_processed_aln,
        ch_processed_trees,
        has_foreground_seqs
    )
    ch_fel      = ch_fel.mix(HYPHY_ANALYSES.out.fel_json)
    ch_meme     = ch_meme.mix(HYPHY_ANALYSES.out.meme_json)
    ch_prime    = ch_prime.mix(HYPHY_ANALYSES.out.prime_json)
    ch_busted   = ch_busted.mix(HYPHY_ANALYSES.out.busted_json)
    ch_contrastfel = ch_contrastfel.mix(HYPHY_ANALYSES.out.contrastfel_json)
    ch_relax    = ch_relax.mix(HYPHY_ANALYSES.out.relax_json)
    ch_versions = ch_versions.mix(HYPHY_ANALYSES.out.versions.first())

    //TODO: create a final subworkflow to process the hyphy data into something clean and useful

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

    // TODO: if necessary, emit whatever hyphy emits in the interim before we create the final subworkflow
    emit:
        multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
        versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
