// Subworkflow to process viral non-recombinant sequences

include { REMOVEAMBIGSEQS } from '../../../modules/local/removeambigseqs/main'
include { CAWLIGN         } from '../../../modules/local/cawlign/main'
include { HYPHY_CLN       } from '../../../modules/local/hyphy/cln/main'
include { IQTREE          } from '../../../modules/local/iqtree/main'
include { HYPHY_LABELTREE_LIST       } from '../../../modules/local/hyphy/labeltree/main'
include { HYPHY_LABELTREE_REGEXP     } from '../../../modules/local/hyphy/labeltree/main'

workflow PROCESS_VIRAL_NONRECOMBINANT {

    take:
    ch_unaligned      // channel: [ val(meta), [ unaligned_sequences ] ]
    ch_reference      // channel: [ val(meta), [ reference_gene ] ]
    ch_foreground_seqs     // channel: [ path(foreground_sequences_list) ]
    ch_foreground_regexp   // channel: [ val('regexp') ]

    main:
    ch_versions = Channel.empty()
    ch_out_tree = Channel.empty()

    // Remove sequences with ambiguous bases "-clean.fasta"
    REMOVEAMBIGSEQS (
        ch_unaligned
    )
    ch_versions = ch_versions.mix(REMOVEAMBIGSEQS.out.versions.first())

    // Align sequences using cawlign "-aligned.fasta"
    CAWLIGN (
        ch_reference,
        REMOVEAMBIGSEQS.out.cleaned_seqs
    )
    ch_versions = ch_versions.mix(CAWLIGN.out.versions.first())

    // Remove duplicate sequences and clean up sequence names "-nodups${in_msa.extension}"
    HYPHY_CLN (
        CAWLIGN.out.aligned_seqs
    )
    ch_versions = ch_versions.mix(HYPHY_CLN.out.versions.first())


    // Generate phylogenetic tree with IQTree
    // -T [num_cpu_cores] when using multiple cores
    IQTREE (
        HYPHY_CLN.out.deduplicated_seqs
    )
    ch_out_tree = IQTREE.out.phylogeny
    ch_versions = ch_versions.mix(IQTREE.out.versions.first())

    // Label tree with foreground sequences
    if (ch_foreground_regexp) {
        HYPHY_LABELTREE_REGEXP (
            IQTREE.out.phylogeny,
            ch_foreground_regexp
        )
        ch_out_tree = HYPHY_LABELTREE_REGEXP.out.labeled_tree
        ch_versions = ch_versions.mix(HYPHY_LABELTREE_REGEXP.out.versions.first())
    }
    if (ch_foreground_seqs) {
        HYPHY_LABELTREE_LIST (
            IQTREE.out.phylogeny,
            ch_foreground_seqs
        )
        ch_out_tree = HYPHY_LABELTREE_LIST.out.labeled_tree
        ch_versions = ch_versions.mix(HYPHY_LABELTREE_LIST.out.versions.first())
    }

    // Check if the string "Foreground" is present in the tree file
    ch_out_tree
        .map { it ->
            def tree = it[1]
            if (tree.text.contains("Foreground")) {
                true
            } else {
                println "[WARN] No internal branches were labeled in the tree file ${tree}. Check your foreground sequences."
                log.warn "No internal branches were labeled in the tree file ${tree}. Check your foreground sequences."
            }
        }
    

    emit:
    deduplicated  = HYPHY_CLN.out.deduplicated_seqs    // channel: [ val(meta), [ deduplicated_sequences ] ]
    tree          = ch_out_tree                        // channel: [ val(meta), [ phylogenetic_tree ] ]
    versions      = ch_versions                        // channel: [ versions.yml ]
}

