# Contributing

Any help on this plugin would is much appreciated.

## First steps

If you have a use case that the adapter isn't quite able to cover, a more detailed understanding of why can be achieved by following these steps:

1. Setting the `loglevel` property in your `neotest` setup config to `1` to reveal all the debug logs from neotest-vstest
2. Open up your tests file and do what your normally do to run the tests
3. Look through the neotest log files for logs prefixed with `neotest-vstest` (can be found by running the command `echo stdpath("log")`)

The general flow for test discovery and execution is as follows:

1. Spawn VSTest instance at start-up.
2. On test discovery: Send list of files to VSTest instance.
   - VSTest write the discovered test cases to a file.
3. Read result file and parse tests.
4. Use treesitter to determine line ranges for test cases.
5. On test execution: Send list of test ids to VSTest instance.
   - Once test results are in the VSTest instance will write the results to a file.
6. Read test result file and parse results.

## Running tests

To run the tests from CLI, make sure that `luarocks` is installed and executable.
Then, Run `luarocks test` from the project root.

If you see a module 'busted.runner' not found error you need to update your `LUA_PATH`:

```sh
eval $(luarocks path --no-bin)
```
