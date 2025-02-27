## Install or use container?

Installation requires compilation: <https://www.htslib.org/download/>

Or, use a container:

```
quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1
```

This is one way to do it:

``` bash
docker run -it \
  -v `pwd`:`pwd` \
  -w `pwd` \
  quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1 \
  stat test.paired_end.sorted.bam
```

But:

- what if the container does not exist?
- need to remember the (technical) arguments for Docker
- need to remember the container pointer

