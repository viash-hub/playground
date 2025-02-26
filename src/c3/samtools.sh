#!/bin/bash

docker run -it \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1 \
  stat "$1" >"$2"
