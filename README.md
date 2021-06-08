# Reverse-engineering Docker's exec

I find the documentation surrounding docker build "CMD", "ENTRYPOINT" etc. to
be incredibly vague. I just couldn't work out from the documentation what would
actually happen, given any particular input.  What would docker exec?  🤷

This, therefore, was me reverse-engineering the 'exec' logic: trying lots of
combinations of CMD, ENTRYPOINT, etc; seeing what happened; and then trying to
assemble a short set of rules which then matches the observed behaviour.

The result is [in this repository](https://github.com/rvedotrc/dockerfile-cmd-entrypoint/blob/master/docker_exec_predictor.rb).

And *those rules* are what should be in the documentation!

## Running the tests

```sh
bundle install

# Try all the different combinations and see what Docker actually does.
# This bit can take a while...
bundle exec ruby combos.rb

# Compare to the predictor:
bundle exec ruby reverse-engineer-rules.rb < o.json
```
