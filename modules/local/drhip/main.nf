process DRHIP {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/drhip:0.1.3--pyhdfd78af_0':
        'biocontainers/drhip:0.1.3--pyhdfd78af_0' }"

    input:
    val fel_results
    val meme_results
    val prime_results
    val busted_results
    val contrastfel_results
    val relax_results

    output:
    path "combined_summary.csv",              emit: summary_csv
    path "combined_sites.csv",                emit: sites_csv
    path "combined_comparison_summary.csv",   optional: true, emit: comparison_summary_csv
    path "combined_comparison_site.csv",      optional: true, emit: comparison_site_csv
    path "versions.yml",                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def fel_files = fel_results.join(' ')
    def meme_files = meme_results.join(' ')
    def prime_files = prime_results.join(' ')
    def busted_files = busted_results.join(' ')
    def contrastfel_files = contrastfel_results != null ? contrastfel_results.join(' ') : ''
    def relax_files = relax_results != null ? relax_results.join(' ') : ''


    """
    # Build expected hyphy directory structure for drhip
    mkdir -p hyphy/{FEL,MEME,PRIME,BUSTED}

    cp -L ${fel_files}      hyphy/FEL/
    cp -L ${meme_files}     hyphy/MEME/
    cp -L ${prime_files}    hyphy/PRIME/
    cp -L ${busted_files}   hyphy/BUSTED/

    # Optional comparisons
    if [[ -n "${contrastfel_files}" ]]; then
        mkdir -p hyphy/CONTRASTFEL
        cp -L ${contrastfel_files} hyphy/CONTRASTFEL/
    fi
    if [[ -n "${relax_files}" ]]; then
        mkdir -p hyphy/RELAX
        cp -L ${relax_files} hyphy/RELAX/
    fi

    # Run drhip on the assembled folder
    drhip \\
        --input hyphy \\
        --output .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drhip: \$(drhip --version | sed 's/drhip //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch combined_summary.csv
    touch combined_sites.csv
    touch combined_comparison_summary.csv
    touch combined_comparison_site.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drhip: \$(drhip --version | sed 's/drhip //g')
    END_VERSIONS
    """
    }
