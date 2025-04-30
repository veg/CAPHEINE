// Subworkflow to process viral non-recombinant sequences

include { REMOVEAMBIGSEQS } from '../../../modules/local/removeambigseqs/main'
include { CAWLIGN         } from '../../../modules/local/cawlign/main'
include { REMOVEDUPS      } from '../../../modules/local/hyphy/removedups/main'
include { IQTREE          } from '../../../modules/local/iqtree/main'
include { LABELTREE       } from '../../../modules/local/hyphy/labeltree/main'

workflow PROCESS_VIRAL_NONRECOMBINANT {

    take:
    ch_unaligned      // channel: [ val(meta), [ unaligned_sequences ] ]
    ch_reference      // channel: [ val(meta), [ reference_gene ] ]
    ch_foreground     // channel: [ foreground_sequences_list ]

    main:

    ch_versions = Channel.empty()

    // Remove sequences with ambiguous bases
    REMOVEAMBIGSEQS (
        ch_unaligned
    )
    ch_versions = ch_versions.mix(REMOVEAMBIGSEQS.out.versions.first())

    // Align sequences using cawlign
    CAWLIGN (
        ch_reference,
        REMOVEAMBIGSEQS.out.cleaned_seqs
    )
    ch_versions = ch_versions.mix(CAWLIGN.out.versions.first())

    // Remove duplicate sequences
    REMOVEDUPS (
        CAWLIGN.out.aligned
    )
    ch_versions = ch_versions.mix(REMOVEDUPS.out.versions.first())

    // Generate phylogenetic tree with IQTree
    // -T [num_cpu_cores] when using multiple cores
    // [] is so we can avoid passing a guide tree to IQTree
    IQTREE (
        [REMOVEDUPS.out.deduplicated, []],
        -m GTR+I+G
    )
    ch_versions = ch_versions.mix(IQTREE.out.versions.first())

    // Label tree with foreground sequences
    LABELTREE (
        IQTREE.out.phylogeny,
        ch_foreground
    )
    ch_versions = ch_versions.mix(LABELTREE.out.versions.first())

    emit:
    aligned       = CAWLIGN.out.aligned            // channel: [ val(meta), [ aligned_sequences ] ]
    deduplicated  = REMOVEDUPS.out.deduplicated    // channel: [ val(meta), [ deduplicated_sequences ] ]
    tree          = IQTREE.out.phylogeny           // channel: [ val(meta), [ phylogenetic_tree ] ]
    labeled_tree  = LABELTREE.out.labeled_tree     // channel: [ val(meta), [ labeled_tree ] ]

    versions      = ch_versions                    // channel: [ versions.yml ]
}

