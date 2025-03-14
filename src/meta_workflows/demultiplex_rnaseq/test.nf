nextflow.enable.dsl=2
targetDir = params.rootDir + "/target"

include { demultiplex_rnaseq } from targetDir + "/nextflow/demultiplex_rnaseq/main.nf"

params.resources_test = "gs://viash-hub-resources/rnaseq/demultiplex_rnaseq_meta/"

workflow test_wf {

  resources_test_file = file(params.resources_test)

  output_ch = Channel.fromList([
      [
        id: "_test",
        input: resources_test_file.resolve("200624_A00834_0183_BHMTFYDRXX.tar.gz"),
        sample_sheet: resources_test_file.resolve("SampleSheet.csv"),
        fasta: resources_test_file.resolve("GCA_009858895.3_ASM985889v3_genomic.fna.gz"),
        gtf: resources_test_file.resolve("Sars_cov_2.ASM985889v3.101.gtf.gz"),
        skip_bbsplit: true,
        skip_alignment: true,
        skip_deseq2_qc: true,
        num_trimmed_reads: 5000,
        rseqc_modules: "bam_stat;infer_experiment;junction_saturation;read_distribution;read_duplication",
        multiqc_custom_config: resources_test_file.resolve("multiqc_config.yml")
      ]
    ])

    | map { state -> [state.id, state] }

    | demultiplex_rnaseq.run(
      fromState: { id, state -> state },
      toState: { id, output, state -> output }
    )

    | view { output ->
      assert output.size() == 2 : "Outputs should contain two elements; [id, state]"

      // check output
      def state = output[1]
      assert state instanceof Map : "State should be a map. Found: ${state}"
      assert state.containsKey("output_fasta") : "Output should contain key 'output_fasta'."
      assert state.output_fasta.isFile() : "'output_fasta' should be a file."
      assert state.containsKey("output_gtf") : "Output should contain key 'output_gtf'."
      assert state.output_gtf.isFile() : "'output_gtf' should be a file."

      "Output: $output"
    }
}