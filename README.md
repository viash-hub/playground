

# 🌱📦 playground

[![GitHub](https://img.shields.io/badge/GitHub-viash--hub%2Fplayground-blue.png)](https://github.com/viash-hub/playground)
[![GitHub
Issues](https://img.shields.io/github/issues/viash-hub/playground.png)](https://github.com/viash-hub/playground/issues)
[![Viash
version](https://img.shields.io/badge/Viash-v0.9.0--RC6-blue)](https://viash.io)

A collection of bioinformatics pipelines to illustrate the use of biobox
(and biotools).

## Quickstart

### Requirements

To run the components and workflows included in this repository, you
need to have the following software installed:

- Bash (\>= 3.2) or an equivalent shell
- Java Development Kit (\>= 12)
- Docker
- Viash (\>= 0.6.7)
- Nextflow (\>= 21.04)

### Cloning the repository

To clone this repository to your local machine, copy the URL of the
forked repository by clicking the green “Code” button and selecting
HTTPS or SSH. In your terminal or command prompt, navigate to the
directory where you want to clone the repository and enter the following
command:

``` bash
git clone <copied_url> playground
cd playground
```

### Test dataset

You will also need to download the test resources by running the
following command. From the repository root, run:

``` bash
./test_data.sh
```

This will create the `test_data` folder and a file called
`params_file.yaml`; the latter can be used to run the worklow with the
generated test data.

### Building

Before running the workflow, the viash components need to be build and
the docker images generated.

``` bash
viash ns build --parallel --setup cachedbuild
```

> [!NOTE]
>
> The `--setup cachedbuild` enables building the docker images.

You will now see a `target` folder inside the root of the repository.

### Testing the workflow

To use the workflow with test data, use the following command (from the
root of the repository):

``` bash
nextflow run . -main-script ./target/nextflow/mapping_and_qc/main.nf \
-params-file ./params_file.yaml \
-profile docker \
-c ./target/nextflow/mapping_and_qc/nextflow.config
```

The output will be written to the folder `test_run_output`, as specified
in the `publish_dir` argument in the `params_file.yaml`.

## Support and Community

For support, questions, or to join our community:

- **Issues**: Submit questions or issues via the [GitHub issue
  tracker](https://github.com/viash-hub/playground/issues).
- **Discussions**: Join our discussions via [GitHub
  Discussions](https://github.com/viash-hub/playground/discussions).
