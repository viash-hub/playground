#!/bin/bash

viash ns build --setup cb --parallel -q demultiplex_rnaseq

nextflow run . \
  -main-script target/nextflow/demultiplex_rnaseq/main.nf \
  -params-file example.yaml \
  -profile docker \
  --publish_dir test_results \