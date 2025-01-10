#!/bin/bash

viash ns build --setup cb --parallel -q demultiplex_rnaseq

nextflow run . \
  -main-script target/nextflow/demultiplex_rnaseq/main.nf \
  -params-file src/meta_workflows/demultiplex_rnaseq/example.yaml \
  -profile docker \
  --publish_dir test_results \
  --resume 
