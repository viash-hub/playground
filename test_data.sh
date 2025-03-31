#/usr/bin/env bash

set -eo pipefail

# ensure that the command below is run from the root of the repository
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

TEST_DATA_DIR="test_data"
mkdir -p "$TEST_DATA_DIR"
if [ ! -f "$TEST_DATA_DIR/SRR1569895_1.fastq" ] || [ ! -f "$TEST_DATA_DIR/SRR1569895_2.fastq" ]; then
  docker run -t --rm -v $PWD:/output:rw -w /output/test_data ncbi/sra-tools fasterq-dump -e 2 -p SRR1569895
fi
if [ ! -f "$TEST_DATA_DIR/SRR1570800_1.fastq" ] || [ ! -f "$TEST_DATA_DIR/SRR1570800_2.fastq" ]; then
  docker run -t --rm -v $PWD:/output:rw -w /output/test_data ncbi/sra-tools fasterq-dump -e 2 -p SRR1570800
fi

head -n 10000 "$TEST_DATA_DIR/SRR1569895_1.fastq" >"$TEST_DATA_DIR/SRR1569895_1_subsample.fastq"
head -n 10000 "$TEST_DATA_DIR/SRR1569895_2.fastq" >"$TEST_DATA_DIR/SRR1569895_2_subsample.fastq"
head -n 10000 "$TEST_DATA_DIR/SRR1570800_1.fastq" >"$TEST_DATA_DIR/SRR1570800_1_subsample.fastq"
head -n 10000 "$TEST_DATA_DIR/SRR1570800_2.fastq" >"$TEST_DATA_DIR/SRR1570800_2_subsample.fastq"

export NXF_SCM_FILE="$TEST_DATA_DIR/scm.config"

cat >$NXF_SCM_FILE <<EOF
providers {
    vsh {
        platform = 'gitlab'
        server = 'https://packages.viash-hub.com/'
    }
}
EOF

if [ ! -f "$TEST_DATA_DIR/S288C_reference_genome_Current_Release.tgz" ]; then
  wget http://sgd-archive.yeastgenome.org/sequence/S288C_reference/genome_releases/S288C_reference_genome_Current_Release.tgz \
    -O "$TEST_DATA_DIR/S288C_reference_genome_Current_Release.tgz"
fi

if [ ! -d "$TEST_DATA_DIR/S288C_reference_genome_Current_Release" ]; then
  nextflow run vsh/craftbox -hub vsh -r main -main-script target/nextflow/untar/main.nf \
    -profile docker \
    --input "$TEST_DATA_DIR/S288C_reference_genome_Current_Release.tgz" \
    --output "S288C_reference_genome_Current_Release" \
    --publish_dir "$TEST_DATA_DIR"
fi

gunzip -c "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/S288C_reference_sequence_R64-5-1_20240529.fsa.gz" >"$TEST_DATA_DIR/S288C_reference_genome_Current_Release/S288C_reference_sequence_R64-5-1_20240529.fsa"
gunzip -c "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/saccharomyces_cerevisiae_R64-5-1_20240529.gff.gz" >"$TEST_DATA_DIR/S288C_reference_genome_Current_Release/saccharomyces_cerevisiae_R64-5-1_20240529.gff"
sed -i -e 's/^.*chromosome=\(.*\)\]$/>chr\1/' "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/S288C_reference_sequence_R64-5-1_20240529.fsa"

if [ ! -d "$TEST_DATA_DIR/S288C_reference_genome_Current_Release_STAR" ]; then
  nextflow run vsh/biobox -hub vsh -r main -main-script target/nextflow/star/star_genome_generate/main.nf \
    -profile docker \
    --genome_fasta_files "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/S288C_reference_sequence_R64-5-1_20240529.fsa" \
    --sjdb_gtf_file "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/saccharomyces_cerevisiae_R64-5-1_20240529.gff" \
    --sjdb_gtf_tag_exon_parent_transcript Parent \
    --sjdb_overhang 100 \
    --publish_dir "$TEST_DATA_DIR" \
    --sjdb_gtf_feature_exon noncoding_exon \
    --index S288C_reference_genome_Current_Release_STAR
fi

PARAMS_FILE=params_file.yaml
cat >$PARAMS_FILE <<EOF
param_list:
  - id: SRR1569895
    input_r1: $TEST_DATA_DIR/SRR1569895_1_subsample.fastq
    input_r2: $TEST_DATA_DIR/SRR1569895_2_subsample.fastq
  - id: SRR1570800
    input_r1: $TEST_DATA_DIR/SRR1570800_1_subsample.fastq
    input_r2: $TEST_DATA_DIR/SRR1570800_2_subsample.fastq
publish_dir: foo
reference: $TEST_DATA_DIR/S288C_reference_genome_Current_Release_STAR
EOF
