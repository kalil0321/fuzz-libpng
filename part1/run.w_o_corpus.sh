# configure the script
export PROJECT=libpng
export CORPUS=build/out/corpus
export HARNESS=libpng_read_fuzzer
export REPOSITORY=https://github.com/hamzaremmal/fuzz-libpng.git

# clone the oss-fuzz repository with corpus
git clone $REPOSITORY -b oss-fuzz/without-corpus oss-fuzz
# operate on the oss-fuzz repository
cd oss-fuzz
# build the image for libpng
python3 infra/helper.py build_image --no-pull $PROJECT
# build the fuzzers for libpng
python3 infra/helper.py build_fuzzers --no-pull $PROJECT
# run the fuzzer for 4 hours
timeout --preserve-status 4h python3 infra/helper.py run_fuzzer $PROJECT $HARNESS --corpus-dir $CORPUS
# build the fuzzer for coverage
python3 infra/helper.py build_fuzzers --sanitizer coverage $PROJECT
# build the coverage
python3 infra/helper.py coverage $PROJECT --corpus-dir $CORPUS --fuzz-target $HARNESS
