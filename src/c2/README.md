## Create a script?

Making it easier to run the tool, let's create a script:

``` bash
#!/bin/bash

docker run -it \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1 \
  stat "$1"
```

And yes, that works!

But:

- what if I need to add additional arguments?
- this is a tool that is relatively well supported, but what if this is a Python script?
