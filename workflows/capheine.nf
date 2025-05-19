/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PROCESS_VIRAL_NONRECOMBINANT } from '../subworkflows/local/process_viral_nonrecombinant/main'
include { HYPHY_ANALYSES         } from '../subworkflows/local/hyphy_analyses/main'
include { FASTAVALIDATOR         } from '../modules/nf-core/fastavalidator/main'
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
    } else if (params.foreground_regexp) {
        ch_foreground_regexp       = params.foreground_regexp
    } else {
        ch_foreground_seqs         = []
        ch_foreground_regexp       = []
    }

    //
    // VALIDATE INPUT FILES
    //
    FASTAVALIDATOR(ch_unaligned)
    FASTAVALIDATOR(ch_reference)
    ch_versions = ch_versions.mix(FASTAVALIDATOR.out.versions)

    //
    // SUBWORKFLOW: Run preprocessing of viral non-recombinant viral data
    //
    PROCESS_VIRAL_NONRECOMBINANT (
        ch_unaligned,
        ch_reference,
        (ch_foreground_seqs.size() > 0) ? [ch_foreground_seqs] : ch_foreground_regexp
    )
    ch_processed_aln = ch_processed_aln.mix(PROCESS_VIRAL_NONRECOMBINANT.out.deduplicated)
    ch_processed_trees = ch_processed_trees.mix(PROCESS_VIRAL_NONRECOMBINANT.out.labeled_tree)
    ch_versions = ch_versions.mix(PROCESS_VIRAL_NONRECOMBINANT.out.versions.first())

    // TODO: possibly have PROCESS_VIRAL_NONRECOMBINANT output a branch set channel
    // for use in HYPHY_ANALYSES

    //
    // SUBWORKFLOW: Run Hyphy Analyses
    //
    HYPHY_ANALYSES (
        ch_processed_aln,
        ch_processed_trees,
        (ch_foreground_seqs.size() > 0) ? [ch_foreground_seqs] : ch_foreground_regexp
    )
    ch_fel      = ch_fel.mix(HYPHY_FEL.out.fel_json)
    ch_meme     = ch_meme.mix(HYPHY_MEME.out.meme_json)
    ch_prime    = ch_prime.mix(HYPHY_PRIME.out.prime_json)
    ch_busted   = ch_busted.mix(HYPHY_BUSTED.out.busted_json)
    ch_contrastfel = ch_contrastfel.mix(HYPHY_CONTRASTFEL.out.contrastfel_json)
    ch_relax    = ch_relax.mix(HYPHY_RELAX.out.relax_json)
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

    // TODO: if necessary, emit whatever hyphy emits in the interim before we create the final subworkflow
    // emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
