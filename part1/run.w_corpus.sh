#!/bin/bash
set -euo pipefail

# CREATE A WORKING DIRECTORY
export WORKDIR="$(mktemp -d)"
echo "Using temp directory: $WORKDIR"
cd "$WORKDIR"

# configure the script
export PROJECT=libpng
export CORPUS="$WORKDIR/build/out/corpus"
export HARNESS=libpng_read_fuzzer
export REPOSITORY=git@github.com:hamzaremmal/fuzz-libpng.git
export DURATION=1m

# Make sure the corpus directory exists
echo "Making sure the corpus directory exists"
mkdir -p "$CORPUS"

# clone the oss-fuzz repository with corpus
echo "Cloning the oss-fuzz tree from $REPOSITORY"
git clone "$REPOSITORY" -b oss-fuzz/with-corpus oss-fuzz
cd oss-fuzz
# build the image for libpng
echo "Building images for project: $PROJECT"
python3 infra/helper.py build_image --no-pull "$PROJECT"
# build the fuzzers for libpng
echo "Building fuzzers for project: $PROJECT"
python3 infra/helper.py build_fuzzers --clean "$PROJECT"
# run the fuzzer for 4 hours
echo "Running fuzzer for project '$PROJECT' with harness '$HARNESS'"
timeout --preserve-status "$DURATION" python3 infra/helper.py run_fuzzer "$PROJECT" "$HARNESS" --corpus-dir "$CORPUS"
# build the fuzzer for coverage
echo "Building the coverage fuzzer for project: $PROJECT"
python3 infra/helper.py build_fuzzers --sanitizer coverage "$PROJECT"
# build the coverage
echo "Building the coverage for project '$PROJECT' for harness '$HARNESS'"
python3 infra/helper.py coverage "$PROJECT" --corpus-dir "$CORPUS" --fuzz-target "$HARNESS"
