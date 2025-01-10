  // Helper function to create identity mappings for state
  def createIdentityMap(keys) {
      return keys.collectEntries { [(it): it] }
  }

workflow run_wf {
    take:
        input_ch

    main:
        // Define the required input and output keys
        def rnaseqInputKeys = [
            "id", "fastq_1", "fastq_2", "fasta", "gtf", "gff", "transcript_fasta",
            "additional_fasta", "gene_bed", "gencode", "skip_fastqc", "skip_trimming",
            "trimmer", "min_trimmed_reads", "skip_bbsplit", "bbsplit_fasta_list",
            "remove_ribo_rna", "ribo_database_manifest", "with_umi", "umitools_extract_method",
            "umitools_bc_pattern", "umi_discard_read", "skip_alignment", "skip_pseudo_alignment",
            "aligner", "pseudo_aligner", "min_mapped_reads", "skip_qc", "skip_preseq",
            "skip_deseq2_qc", "skip_dupradar", "skip_qualimap", "skip_rseqc",
            "skip_multiqc", "rseqc_modules", "multiqc_custom_config"
        ]
        
        def rnaseqOutputKeys = [
            "output_fasta", "output_gtf", "output_transcript_fasta", "output_gene_bed",
            "output_bbsplit_index", "output_star_index", "output_salmon_index",
            "output_kallisto_index", "fastqc_html_1", "fastqc_html_2", "fastqc_zip_1",
            "fastqc_zip_2", "output_fastq_1", "output_fastq_2", "trim_log_1", "trim_log_2",
            "trim_zip_1", "trim_zip_2", "trim_html_1", "trim_html_2", "sortmerna_log",
            "star_log", "genome_bam_sorted", "genome_bam_index", "genome_bam_stats",
            "genome_bam_flagstat", "genome_bam_idxstats", "transcriptome_bam",
            "transcriptome_bam_index", "transcriptome_bam_stats", "transcriptome_bam_flagstat",
            "transcriptome_bam_idxstats", "salmon_quant_results", "pseudo_quant_results",
            "markduplicates_metrics", "stringtie_transcript_gtf", "stringtie_coverage_gtf",
            "stringtie_abundance", "stringtie_ballgown", "featurecounts",
            "featurecounts_summary", "featurecounts_multiqc", "featurecounts_rrna_multiqc",
            "bedgraph_forward", "bedgraph_reverse", "bigwig_forward", "bigwig_reverse",
            "preseq_output", "bamstat_output", "strandedness_output",
            "inner_dist_output_stats", "inner_dist_output_dist", "inner_dist_output_freq",
            "inner_dist_output_plot", "inner_dist_output_plot_r",
            "junction_annotation_output_log", "junction_annotation_output_plot_r",
            "junction_annotation_output_junction_bed",
            "junction_annotation_output_junction_interact",
            "junction_annotation_output_junction_sheet",
            "junction_annotation_output_splice_events_plot",
            "junction_annotation_output_splice_junctions_plot",
            "junction_saturation_output_plot_r", "junction_saturation_output_plot",
            "read_distribution_output", "read_duplication_output_duplication_rate_plot_r",
            "read_duplication_output_duplication_rate_plot",
            "read_duplication_output_duplication_rate_mapping",
            "read_duplication_output_duplication_rate_sequence", "tin_output_summary",
            "tin_output_metrics", "dupradar_output_dupmatrix",
            "dupradar_output_dup_intercept_mqc", "dupradar_output_duprate_exp_boxplot",
            "dupradar_output_duprate_exp_densplot",
            "dupradar_output_duprate_exp_denscurve_mqc",
            "dupradar_output_expression_histogram", "dupradar_output_intercept_slope",
            "qualimap_output_dir", "qualimap_output_pdf", "tpm_gene", "counts_gene",
            "counts_gene_length_scaled", "counts_gene_scaled", "tpm_transcript",
            "counts_transcript", "quant_merged_summarizedexperiment", "deseq2_output",
            "pseudo_tpm_gene", "pseudo_counts_gene", "pseudo_counts_gene_length_scaled",
            "pseudo_counts_gene_scaled", "pseudo_tpm_transcript", "pseudo_counts_transcript",
            "pseudo_lengths_gene", "pseudo_lengths_transcript",
            "pseudo_quant_merged_summarizedexperiment", "deseq2_output_pseudo",
            "multiqc_report", "multiqc_data", "multiqc_plots"
        ]

        output_ch = input_ch
            | demultiplex.run(
                fromState: [
                    "input": "input",
                    "sample_sheet": "sample_sheet"
                ],
                toState: [
                    "output_demultiplexed": "output"
                ]
            )

            | flatMap { id, state ->
                println "Processing sample sheet: $state.sample_sheet"
                def sample_sheet = file(state.sample_sheet)
                def original_id = id
                def lines = sample_sheet.readLines()

                // Extract Sample_IDs
                if (lines.indexOf('[Data]') < 0) {
                    println "Data section not found"
                    return
                }
                def data_lines = lines.drop(lines.indexOf('[Data]') + 2)
                def samples = data_lines.collect { line ->
                    def columns = line.split(',')
                    return columns.size() > 1 ? columns[1].trim() : null
                }.findAll { it != null }

                println "Looking for fastq files in ${state.output_demultiplexed}."
                processed_samples = samples.collect { sample_id ->
                    def forward_regex = ~/^${sample_id}_S(\d+)_(L(\d+)_)?R1_(\d+)\.fastq\.gz$/
                    def reverse_regex = ~/^${sample_id}_S(\d+)_(L(\d+)_)?R2_(\d+)\.fastq\.gz$/
                    def forward_fastq = state.output_demultiplexed.listFiles().findAll{it.isFile() && it.name ==~ forward_regex}
                    def reverse_fastq = state.output_demultiplexed.listFiles().findAll{it.isFile() && it.name ==~ reverse_regex}
                    reverse_fastq = !reverse_fastq.isEmpty() ? reverse_fastq[0] : null
                    def fastqs_state = [
                        "id": sample_id,
                        "fastq_1": forward_fastq[0],
                        "fastq_2": reverse_fastq,
                        "_meta": [ "join_id": original_id ]
                    ]
                    [sample_id, fastqs_state + state]
                }
                println "Finished processing sample sheet."
                return processed_samples
            }

            | rnaseq.run(
                fromState: createIdentityMap(rnaseqInputKeys),
                toState: createIdentityMap(rnaseqOutputKeys)
            )

            | map { id, state -> 
                def mod_state = state.findAll { key, value -> 
                    value instanceof java.nio.file.Path && value.exists() 
                }
                [ id, mod_state + [ _meta: [join_id: "run"] ] ]
            }

            | setState(createIdentityMap(rnaseqOutputKeys + ["_meta"]))

    emit:
        output_ch
}