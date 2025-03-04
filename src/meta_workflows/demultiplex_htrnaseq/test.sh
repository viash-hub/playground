#!/bin/bash

viash ns build --setup cb --parallel -q demultiplex_htrnaseq

nextflow run . \
  -main-script target/nextflow/demultiplex_htrnaseq/main.nf \
  -params-file src/meta_workflows/demultiplex_htrnaseq/example.yaml \
  -profile docker \
  -latest \
  -resume \
  --publish_dir test_results \