workflow run_wf {
  take:
    input_ch

  main:
    output_ch = input_ch

      | demultiplex.run(
        fromState: [
            "input": "input",
            "run_information": "run_information",
            "demultiplexer": "demultiplexer"
        ],
        toState: [
            "output_falco": "output_falco",
            "output_multiqc": "output_multiqc",
            "output_demultiplexed": "output",
        ],
      )

      | flatMap { id, state ->
          def sample_sheet = file(state.run_information)
          def lines = sample_sheet.readLines()
          
          data_section = lines.findIndexOf { it.trim() =~ /\[\s*.*[dD][aA][tT][aA].*\s*\]/ }
          
          // Extract samples from data lines
          def samples = []
          for (int i = data_section + 2; i < lines.size(); i++) {
              def line = lines[i].trim()
              if (line.isEmpty() || line.startsWith("[")) break
              def columns = line.split(',')
              if (columns.size() > 0 && !columns[0].trim().isEmpty()) {
                  samples.add(columns[0].trim())
              }
          }
          
          println "Found ${samples.size()} samples: $samples"
          
          def output_dir = file(state.output_demultiplexed)
          println "Looking for files in: $output_dir"
          
          def all_files = output_dir.listFiles()
          println "Total files found: ${all_files.size()}"
          
          def processed_samples = []
          
          samples.each { sample_id ->
              def r1_files = all_files.findAll { 
                  it.name =~ /^${sample_id}_S\d+_R1_001\.fastq\.gz$/ 
              }.sort()
              
              def r2_files = all_files.findAll { 
                  it.name =~ /^${sample_id}_S\d+_R2_001\.fastq\.gz$/ 
              }.sort()
              
              println "Sample $sample_id: found ${r1_files.size()} R1 files and ${r2_files.size()} R2 files"
              
              if (!r1_files.isEmpty()) {
                  processed_samples << [sample_id, [
                      "id": sample_id,
                      "fastq_1": r1_files[0],
                      "fastq_2": r2_files ? r2_files[0] : null,
                      "_meta": ["join_id": id]
                  ] + state]
              }
          }
          
          println "Processed ${processed_samples.size()} samples successfully"
          return processed_samples
      }

      | htrnaseq.run(
        fromState: [
          "id": "id",
          "input_r1": "fastq_1",
          "input_r2": "fastq_2",
          "barcodesFasta": "barcodesFasta",
          "genomeDir": "genomeDir",
          "annotation": "annotation"
        ],
        toState: [
          "fastq_output_r1": "fastq_output_r1",
          "fastq_output_r2": "fastq_output_r2",
          "star_output": "star_output",
          "nrReadsNrGenesPerChrome": "nrReadsNrGenesPerChrome",
          "star_qc_metrics": "star_qc_metrics",
          "eset": "eset",
          "f_data": "f_data",
          "p_data": "p_data",
          "html_report": "html_report"
        ]
      )

      | map { id, state -> 
        def mod_state = state.findAll { key, value -> value instanceof java.nio.file.Path && value.exists() }
        [ id, mod_state + [ _meta: [join_id: "run"] ] ]
      }

      | setState(
        "fastq_output_r1": "fastq_output_r1",
        "fastq_output_r2": "fastq_output_r2",
        "star_output": "star_output",
        "nrReadsNrGenesPerChrome": "nrReadsNrGenesPerChrome",
        "star_qc_metrics": "star_qc_metrics",
        "eset": "eset",
        "f_data": "f_data",
        "p_data": "p_data",
        "html_report": "html_report",
        "output_falco": "output_falco",
        "output_multiqc": "output_multiqc",
        "_meta": "_meta"
      )

  emit:
    output_ch
}