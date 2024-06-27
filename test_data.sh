#/usr/bin/env bash

# ensure that the command below is run from the root of the repository
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

TEST_DATA_DIR="test_data"
mkdir -p "$TEST_DATA_DIR"
docker run -t --rm -v $PWD:/output:rw -w /output/test_data ncbi/sra-tools fasterq-dump -e 2 -p SRR1569895
docker run -t --rm -v $PWD:/output:rw -w /output/test_data ncbi/sra-tools fasterq-dump -e 2 -p SRR1570800	

wget http://sgd-archive.yeastgenome.org/sequence/S288C_reference/genome_releases/S288C_reference_genome_Current_Release.tgz \
-O "$TEST_DATA_DIR/S288C_reference_genome_Current_Release.tgz"

export NXF_SCM_FILE="$TEST_DATA_DIR/scm.config"

cat > $NXF_SCM_FILE << EOF
providers {
    vsh {
        platform = 'gitlab'
        server = 'https://viash-hub.com/'
    }
}
EOF

nextflow run vsh/craftbox -hub vsh -r main -main-script target/nextflow/untar/main.nf \
--input "$TEST_DATA_DIR/S288C_reference_genome_Current_Release.tgz" \
--output "S288C_reference_genome_Current_Release" \
--publish_dir "$TEST_DATA_DIR"

gunzip "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/S288C_reference_sequence_R64-5-1_20240529.fsa.gz"
gunzip "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/saccharomyces_cerevisiae_R64-5-1_20240529.gff.gz"
sed -i -e 's/^.*chromosome=\(.*\)\]$/>chr\1/' "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/S288C_reference_sequence_R64-5-1_20240529.fsa"

nextflow run vsh/biobox -hub vsh -r main -main-script target/nextflow/star/star_genome_generate/main.nf \
-profile docker \
--genomeFastaFiles "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/S288C_reference_sequence_R64-5-1_20240529.fsa" \
--sjdbGTFfile "$TEST_DATA_DIR/S288C_reference_genome_Current_Release/saccharomyces_cerevisiae_R64-5-1_20240529.gff" \
--sjdbGTFtagExonParentTranscript Parent \
--sjdbOverhang 100 \
--publish_dir "$TEST_DATA_DIR" \
--sjdbGTFfeatureExon noncoding_exon \
--index S288C_reference_genome_Current_Release_STAR 

PARAMS_FILE=params_file.yaml
cat > $PARAMS_FILE << EOF
param_list:
  - id: SRR1569895
    input_r1: $TEST_DATA_DIR/SRR1569895_1.fastq
    input_r2: $TEST_DATA_DIR/SRR1569895_2.fastq
  - id: SRR1570800
    input_r1: $TEST_DATA_DIR/SRR1570800_1.fastq
    input_r2: $TEST_DATA_DIR/SRR1570800_2.fastq
publish_dir: foo
reference: $TEST_DATA_DIR/S288C_reference_genome_Current_Release_STAR
EOF