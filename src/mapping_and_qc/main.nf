workflow run_wf {
  take:
    input_ch

  main:
    output_ch = input_ch
      | falco.run(
        fromState: {id, state -> 
          def input_list = [state.input_r1, state.input_r2]
          [
            "input": input_list,
            "outdir": "\$id.falco",
            "report_filename": null,
            "data_filename": null,
            "summary_filename": null,
          ]
        },
        toState: [
          "output_falco": "outdir",
        ],
        directives: [label: ["lowmem", "lowcpu"]]
      )
      | niceView()
      | cutadapt.run(
        fromState: {id, state ->
          [
            "input": state.input_r1,
            "input_r2": state.input_r2,
            "quality_cutoff": "30", // Could make this a parameter
            "quality_cutoff_r2": "30", // Could make this a parameter
            "minimum_length": "60:60", // Could make this a parameter
            "adapter": "CTGTCTCTTATACACATCT", // Could make this a parameter
            "adapter_r2": "CTGTCTCTTATACACATCT", // Could make this a parameter
            "output": "*.fastq",
          ]
        },
        toState: {id, output_state, state -> 
          def newKeys = [
            "trimmed_r1": output_state["output"][0],
            "trimmed_r2": output_state["output"][1],
          ]
          def new_state = state + newKeys
          return new_state
        },
        directives: [label: ["midmem", "midmem"]]
      )
      | star_align_reads.run(
        fromState: [
          "input": "trimmed_r1",
          "input_r2": "trimmed_r2",
          "genome_dir": "reference",
        ],
        toState: [
          "output_star": "aligned_reads",
        ],
        directives: [label: ["highmem", "midcpu"]]

      )
      | samtools_stats.run(
        fromState: [
          "input": "output_star",
        ],
        toState: [
          "output_samtools_stats": "output",
        ],
        directives: [label: ["midmem", "lowcpu"]]

      )
      | toSortedList()
      | map { events ->
        def new_id = "multiqc"
        def join_id = events[0][0]
        def bam_samtools_stats_dirs = events.collect{it[1].output_samtools_stats.getParent()}
        def falco_dirs = events.collect{it[1].output_falco}
        return [new_id, ["input": bam_samtools_stats_dirs + falco_dirs, "_meta": ["join_id": join_id]]]
      }
      | multiqc.run(
        fromState: [
          "input": "input",
          "output_report": "multiqc_output",
        ],
        toState: [
          "multiqc_output": "output_report",
        ],
        directives: [label: ["midmem", "lowcpu"]]

      )
      | setState(["multiqc_output", "_meta"])

  emit:
    output_ch
}
