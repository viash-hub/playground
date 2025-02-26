#!/bin/bash

set -e

samtools stats \
  "$par_input" \
  >"$par_output"

exit 0
