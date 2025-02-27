## Add output argument
I want to run this in batch or use this as part of a workflow, output should be in a file. Let's add an output argument to the script:

``` bash
#!/bin/bash

docker run -it \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1 \
  stat "$1" >"$2"
```

But this is not very flexible, does not include validation or parameter checking. It also does not allow for additional arguments?!

```bash
❯ src/c3/samtools.sh test.paired_end.sorted.bam
src/c3/samtools.sh: line 3: : No such file or directory
```

