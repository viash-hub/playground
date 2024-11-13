#!/bin/bash

viash ns build --setup cb --parallel -q demultiplex_rnaseq

nextflow run . \
  -main-script target/nextflow/demultiplex_rnaseq/main.nf \
  --input "https://github.com/nf-core/test-datasets/raw/refs/heads/demultiplex/testdata/NovaSeq6000/200624_A00834_0183_BHMTFYDRXX.tar.gz" \
  --sample_sheet "https://raw.githubusercontent.com/nf-core/test-datasets/refs/heads/demultiplex/testdata/NovaSeq6000/SampleSheet.csv" \
  --fasta "https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2/genome/genome.fasta" \
  --gtf "https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2/genome/genome.gtf" \
  --transcript_fasta "https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2/genome/transcriptome.fasta" \
  --skip_bbsplit \
  --skip_pseudo_alignment \
  -profile docker \
  --publish_dir test_results \