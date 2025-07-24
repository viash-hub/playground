#!/bin/bash

export NXF_VER=24.04.6 # to be removed when htrnaseq is updated to use latest dependencies

viash ns build --setup cb --parallel -q demultiplex_htrnaseq

nextflow run . \
  -main-script target/nextflow/demultiplex_htrnaseq/main.nf \
  -params-file src/meta_workflows/demultiplex_htrnaseq/example.yaml \
  -profile docker \
  -latest \
  -resume \
  --publish_dir test_results \