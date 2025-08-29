// Subworkflow to process viral non-recombinant sequences

include { SEQKIT_SPLIT } from '../../../modules/local/seqkit/split/main'
include { REMOVEAMBIGSEQS } from '../../../modules/local/removeambigseqs/main'
include { CAWLIGN         } from '../../../modules/local/cawlign/main'
include { HYPHY_CLN       } from '../../../modules/local/hyphy/cln/main'
include { IQTREE          } from '../../../modules/local/iqtree/main'
include { HYPHY_LABELTREE_LIST       } from '../../../modules/local/hyphy/labeltree/main'
include { HYPHY_LABELTREE_REGEXP     } from '../../../modules/local/hyphy/labeltree/main'

workflow PROCESS_VIRAL_NONRECOMBINANT {

    take:
    ch_unaligned      // channel: path(unaligned_sequences.fasta)
    ch_reference      // channel: path(reference_genes.fasta)
    ch_foreground_list     // channel: path(foreground_sequences_list)
    ch_foreground_regexp   // channel: val('regexp')

    main:
    ch_versions = Channel.empty()
    ch_out_tree = Channel.empty()

    // Split reference gene into individual genes
    SEQKIT_SPLIT (
        ch_reference
    )
    ch_versions = ch_versions.mix(SEQKIT_SPLIT.out.versions)

    // Align sequences using cawlign "-aligned.fasta" Adds metadata to the sequences
    CAWLIGN (
        SEQKIT_SPLIT.out.gene_fastas.flatten(),
        ch_unaligned
    )
    ch_versions = ch_versions.mix(CAWLIGN.out.versions)

    // Remove sequences with ambiguous bases "-clean.fasta"
    REMOVEAMBIGSEQS (
        CAWLIGN.out.aligned_seqs
    )
    ch_versions = ch_versions.mix(REMOVEAMBIGSEQS.out.versions)

    // Remove duplicate sequences and clean up sequence names "-nodups${in_msa.extension}"
    HYPHY_CLN (
        REMOVEAMBIGSEQS.out.no_ambigs
    )
    ch_versions = ch_versions.mix(HYPHY_CLN.out.versions)

    // check sequences for any outlier distances to other sequences, as a bad alignment QC step?

    // Generate phylogenetic tree with IQTree
    // -T [num_cpu_cores] when using multiple cores
    IQTREE (
        HYPHY_CLN.out.deduplicated_seqs
    )
    ch_out_tree = IQTREE.out.phylogeny
    ch_versions = ch_versions.mix(IQTREE.out.versions)

    // Label tree with foreground sequences
    if (params.foreground_regexp) {
        HYPHY_LABELTREE_REGEXP (
            IQTREE.out.phylogeny,
            ch_foreground_regexp
        )
        ch_out_tree = HYPHY_LABELTREE_REGEXP.out.labeled_tree
        ch_versions = ch_versions.mix(HYPHY_LABELTREE_REGEXP.out.versions)
    }
    if (params.foreground_list) {
        // clean up fasta IDs in list to match how hyphy_cln cleans up sequence IDs

        HYPHY_LABELTREE_LIST (
            IQTREE.out.phylogeny,
            ch_foreground_list
        )
        ch_out_tree = HYPHY_LABELTREE_LIST.out.labeled_tree
        ch_versions = ch_versions.mix(HYPHY_LABELTREE_LIST.out.versions)
    }

    // Check if the string "Foreground" is present in the tree file
    ch_out_tree
        .map { it ->
            def tree = it[1]
            if (tree.text.contains("Foreground")) {
                true
            } else {
                //println "[WARN] No internal branches were labeled in the tree file ${tree}. Check your foreground sequences."
                log.warn "No foreground branches were labeled in the tree file ${tree}."
            }
            if (tree.text.contains("Background")) {
                true
            } else {
                //println "[WARN] No internal branches were labeled in the tree file ${tree}. Check your foreground sequences."
                log.warn "No background branches were labeled in the tree file ${tree}. Your entire tree is being treated as foreground."
            }
        }

    emit:
    deduplicated  = HYPHY_CLN.out.deduplicated_seqs    // channel: [ val(meta), [ deduplicated_sequences ] ]
    tree          = ch_out_tree                        // channel: [ val(meta), [ phylogenetic_tree ] ]
    versions      = ch_versions                        // channel: [ versions.yml ]
}

