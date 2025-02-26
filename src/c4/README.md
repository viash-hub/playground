## Add argument parsing

The script is error-prone now, input is not checked at all. At a minimum, we would need to have something like:
``` bash
#!/bin/bash

usage() {
  echo "Usage: $0 -i <input file> -o <output file>" 1>&2
  exit 1
}

while getopts ":i:o:" arg; do
  case "${arg}" in
  i)
    i=${OPTARG}
    ;;
  o)
    o=${OPTARG}
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${i}" ] || [ -z "${o}" ]; then
  usage
fi

docker run -it \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  quay.io/biocontainers/samtools:1.19.2--h50ea8bc_1 \
  stat "$i" >"$o"
```

This is not fun anymore. With the help of some coding AI, it's not necessarily hard but not fun.

But:

- What about additional arguments?!
- What if you want to check if file exists, argument is integer, ... ?
