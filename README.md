# Reverse-engineering Docker's exec

I find the documentation surrounding docker build "CMD", "ENTRYPOINT" etc. to
be incredibly vague. I just couldn't work out from the documentation what would
actually happen, given any particular input. What would docker exec? 🤷

This, therefore, was me reverse-engineering the 'exec' logic: trying lots of
combinations of CMD, ENTRYPOINT, etc; seeing what happened; and then trying to
assemble a short set of rules which then matches the observed behaviour.

The result is [in this repository](https://github.com/rvedotrc/dockerfile-cmd-entrypoint/blob/master/docker_exec_predictor.rb).

And _those rules_ are what should be in the documentation!

## Version

Last tested with `Docker version 28.3.3, build 980b856816`.

## Running the tests

```sh
bundle install

# Build the test docker image (will be tagged as "bare-image:latest")
./build-image.sh

# Try all the different combinations and see what Docker actually does
bundle exec ruby combos.rb
# (this produces "actuals.json")

# Compare to the predictor:
bundle exec ruby reverse-engineer-rules.rb < actuals.json
```
