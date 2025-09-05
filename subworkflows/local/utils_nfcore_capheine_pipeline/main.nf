//
// Subworkflow with functionality specific to the CAPHEINE pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { samplesheetToList         } from 'plugin/nf-schema'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { imNotification            } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    reference_genes   //  string: Path to FASTA of gene reference sequences
    unaligned_seqs    //  string: Path to FASTA of unaligned DNA sequences
    //input             //  string: Path to input samplesheet

    main:

    ch_versions = Channel.empty()
    //ch_samplesheet = Channel.empty()
    ch_reference_genes = Channel.empty()
    ch_unaligned_seqs = Channel.empty()
    ch_foreground_list = Channel.empty()
    ch_foreground_regexp = Channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    //
    // Validate parameters and generate parameter summary to stdout
    //
    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE (
        nextflow_cli_args
    )

    //
    // Custom validation for pipeline parameters
    //
    validateInputParameters()

    //
    // Create channels from input files provided through params.input
    //
    // ch_samplesheet = Channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
    if (params.hyphy_dir) {
        ch_reference_genes = []
        ch_unaligned_seqs = []
    } else {
        ch_reference_genes = file(reference_genes, checkIfExists: true)
        ch_unaligned_seqs = file(unaligned_seqs, checkIfExists: true)
    }

    if (params.foreground_list) {
        ch_foreground_list         = file(params.foreground_list, checkIfExists: true)
        ch_foreground_regexp       = []
    } else if (params.foreground_regexp) {
        ch_foreground_list         = []
        ch_foreground_regexp       = params.foreground_regexp
    } else {
        ch_foreground_list         = []
        ch_foreground_regexp       = []
    }

    emit:
    //samplesheet = ch_samplesheet
    ref_genes = ch_reference_genes
    unaligned = ch_unaligned_seqs
    foreground_list = ch_foreground_list
    foreground_regexp = ch_foreground_regexp
    versions    = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW FOR PIPELINE COMPLETION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_COMPLETION {

    take:
    email           //  string: email address
    email_on_fail   //  string: email address sent on pipeline failure
    plaintext_email // boolean: Send plain-text email instead of HTML
    outdir          //    path: Path to output directory where results will be published
    monochrome_logs // boolean: Disable ANSI colour codes in log output
    hook_url        //  string: hook URL for notifications
    multiqc_report  //  string: Path to MultiQC report

    main:
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def multiqc_reports = multiqc_report.toList()

    //
    // Completion email and summary
    //
    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
                multiqc_reports.getVal(),
            )
        }

        completionSummary(monochrome_logs)
        if (hook_url) {
            imNotification(summary_params, hook_url)
        }
    }

    workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting. For more information, see the CAPHEINE GitHub repository: https://github.com/veg/capheine"
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//
// Check and validate pipeline parameters
//
def validateInputParameters() {
    foregroundError()
    hyphyInputError()
}

//
// Validate channels from input samplesheet
//
def validateInputSamplesheet(input) {
    // return input as-is until I decide how I want to validate it
    return input
}
// ORIGINAL VERSION
// def validateInputSamplesheet(input) {
//     def (metas, fastqs) = input[1..2]

//     // Check that multiple runs of the same sample are of the same datatype i.e. single-end / paired-end
//     def endedness_ok = metas.collect{ meta -> meta.single_end }.unique().size == 1
//     if (!endedness_ok) {
//         error("Please check input samplesheet -> Multiple runs of a sample must be of the same datatype i.e. single-end or paired-end: ${metas[0].id}")
//     }

//     return [ metas[0], fastqs ]
// }

//
// Get attribute from genome config file e.g. fasta
//
def getGenomeAttribute(attribute) {
    if (params.genomes && params.genome && params.genomes.containsKey(params.genome)) {
        if (params.genomes[ params.genome ].containsKey(attribute)) {
            return params.genomes[ params.genome ][ attribute ]
        }
    }
    return null
}

//
// Exit pipeline if incorrect --genome key provided
//
def genomeExistsError() {
    if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
        def error_string = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
            "  Genome '${params.genome}' not found in any config files provided to the pipeline.\n" +
            "  Currently, the available genome keys are:\n" +
            "  ${params.genomes.keySet().join(", ")}\n" +
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        error(error_string)
    }
}
//
// Exit pipeline if two different methods of specifying foreground sequences are provided
//
def foregroundError() {
    if (params.foreground_list && params.foreground_regexp) {
        def error_string = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
            "  ERROR: either a file of foreground sequences OR a regular expression matching foreground " +
            "  sequences can be provided, not both. Please ensure that only one parameter is provided." +
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        error(error_string)
    }
}

// Ensure that either `--hyphy-dir` OR both `--reference-genes` and `--unaligned-seqs` are provided, but not all three
def hyphyInputError() {
    def hasHyphyDir = params.hyphy_dir
    def hasRef      = params.reference_genes
    def hasUnaln    = params.unaligned_seqs

    if (hasHyphyDir && (hasRef || hasUnaln)) {
        def error_string = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
            "  ERROR: Please provide EITHER --hyphy-dir OR BOTH --reference-genes and --unaligned-seqs.\n" +
            "  You have specified --hyphy-dir together with one or both of the other inputs.\n" +
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        error(error_string)
    }
    if (!hasHyphyDir && !(hasRef && hasUnaln)) {
        def error_string = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
            "  ERROR: Please provide EITHER --hyphy-dir OR BOTH --reference-genes and --unaligned-seqs.\n" +
            "  No valid input combination was detected.\n" +
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        error(error_string)
    }
}
//
// Generate methods description for MultiQC
//
def toolCitationText() {
    // Optionally add in-text citation tools to this list.
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "Tool (Foo et al. 2023)" : "",
    def citation_text = [
            "Tools used in the workflow included:",
            "BioPython (Cock et al., 2009)",
            "BUSTED (Murrell et al., 2015)",
            "Cawlign",
            "Contrast-FEL (Kosakovsky Pond et al., 2020)",
            "DRHIP",
            "FEL (Kosakovsky Pond et al., 2005)",
            "HyPhy (Kosakovsky Pond et al., 2019)",
            "IQ-TREE (Minh et al., 2020)",
            "MEME (Murrell et al., 2012)",
            "MultiQC (Ewels et al., 2016)",
            "PRIME",
            "RELAX (Wertheim et al., 2014)",
            "SeqKit (Shen et al., 2024)",
            "."
    ].join(' ').trim()

    return citation_text
}

def toolBibliographyText() {
    // Optionally add bibliographic entries to this list.
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "<li>Author (2023) Pub name, Journal, DOI</li>" : "",
    def reference_text = [
            "<li>Cock PJ, Antao T, Chang JT, Chapman BA, Cox CJ, Dalke A, et al. Biopython: Freely available python tools for Computational Molecular Biology and Bioinformatics. Bioinformatics. 2009 Mar 20;25(11):1422–3. doi:10.1093/bioinformatics/btp163</li>",
            "<li>Murrell B, Weaver S, Smith MD, Wertheim JO, Murrell S, Aylward A, et al. Gene-wide identification of episodic selection. Molecular Biology and Evolution. 2015 Feb 19;32(5):1365–71. doi:10.1093/molbev/msv035</li>",
            "<li>Kosakovsky Pond SL, Wisotsky SR, Escalante A, Magalis BR, Weaver S. Contrast-FEL—a test for differences in selective pressures at individual sites among clades and sets of branches. Molecular Biology and Evolution. 2020 Oct 16;38(3):1184–98. doi:10.1093/molbev/msaa263</li>",
            "<li>Kosakovsky Pond SL, Frost SD. Not so different after all: A comparison of methods for detecting amino acid sites under selection. Molecular Biology and Evolution. 2005 Feb 9;22(5):1208–22. doi:10.1093/molbev/msi105</li>",
            "<li>Kosakovsky Pond SL, Poon AF, Velazquez R, Weaver S, Hepler NL, Murrell B, et al. Hyphy 2.5—a customizable platform for evolutionary hypothesis testing using phylogenies. Molecular Biology and Evolution. 2019 Aug 27;37(1):295–9. doi:10.1093/molbev/msz197</li>",
            "<li>Minh BQ, Schmidt HA, Chernomor O, Schrempf D, Woodhams MD, von Haeseler A, et al. IQ-tree 2: New models and efficient methods for phylogenetic inference in the genomic era. Molecular Biology and Evolution. 2020 Feb 3;37(5):1530–4. doi:10.1093/molbev/msaa015</li>",
            "<li>Murrell B, Wertheim JO, Moola S, Weighill T, Scheffler K, Kosakovsky Pond SL. Detecting individual sites subject to episodic diversifying selection. PLoS Genetics. 2012 Jul 12;8(7). doi:10.1371/journal.pgen.1002764</li>",
            "<li>Ewels P, Magnusson M, Lundin S, Käller M. MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics. 2016 Oct 1;32(19):3047-8. doi: 10.1093/bioinformatics/btw354. Epub 2016 Jun 16. PubMed PMID: 27312411; PubMed Central PMCID: PMC5039924.</li>",
            "<li>Wertheim JO, Murrell B, Smith MD, Kosakovsky Pond SL, Scheffler K. Relax: Detecting relaxed selection in a phylogenetic framework. Molecular Biology and Evolution. 2014 Dec 23;32(3):820–32. doi:10.1093/molbev/msu400</li>",
            "<li>Shen W, Sipos B, Zhao L. Seqkit2: A Swiss Army knife for sequence and alignment processing. iMeta. 2024 Apr 5;3(3). doi:10.1002/imt2.191</li>"
        ].join(' ').trim()

    return reference_text
}

def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named map so can be used as with familiar NXF ${workflow} variable syntax in the MultiQC YML file
    def meta = [:]
    meta.workflow = workflow.toMap()
    meta["manifest_map"] = workflow.manifest.toMap()

    // Pipeline DOI
    if (meta.manifest_map.doi) {
        // Using a loop to handle multiple DOIs
        // Removing `https://doi.org/` to handle pipelines using DOIs vs DOI resolvers
        // Removing ` ` since the manifest.doi is a string and not a proper list
        def temp_doi_ref = ""
        def manifest_doi = meta.manifest_map.doi.tokenize(",")
        manifest_doi.each { doi_ref ->
            temp_doi_ref += "(doi: <a href=\'https://doi.org/${doi_ref.replace("https://doi.org/", "").replace(" ", "")}\'>${doi_ref.replace("https://doi.org/", "").replace(" ", "")}</a>), "
        }
        meta["doi_text"] = temp_doi_ref.substring(0, temp_doi_ref.length() - 2)
    } else meta["doi_text"] = ""
    meta["nodoi_text"] = meta.manifest_map.doi ? "" : "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

    // Tool references
    meta["tool_citations"] = ""
    meta["tool_bibliography"] = ""

    // Only uncomment below if logic in toolCitationText/toolBibliographyText has been filled!
    meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    meta["tool_bibliography"] = toolBibliographyText()


    def methods_text = mqc_methods_yaml.text

    def engine =  new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}

