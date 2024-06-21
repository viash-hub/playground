workflow run_wf {
  take:
    input_ch

  main:
    mapping_ch = input_ch
      // untar input if needed
      | star_align_reads.run(
        //fromState: [
        //  "input": "input",
        //],
        //toState: { id, result, state ->
        //  state + ["input": result.output]
        //},
      )

  emit:
    output_ch
}
