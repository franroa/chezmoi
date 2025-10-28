<p align="center">
<a href="https://github.com/nsidorenco/neotest-vstest/releases">
  <img alt="GitHub release (latest SemVer)" src="https://img.shields.io/github/v/release/nsidorenco/neotest-vstest?style=for-the-badge">
</a>
<a href="https://luarocks.org/modules/nsidorenco/neotest-vstest">
  <img alt="LuaRocks Package" src="https://img.shields.io/luarocks/v/nsidorenco/neotest-vstest?logo=lua&color=purple&style=for-the-badge">
</a>
</p>

<p align="center">
  <img
    width="923"
    alt="test discovery sample"
    src="https://github.com/user-attachments/assets/7e297d7a-f06d-44a9-adef-92131185e8ca" />
</p>


# Neotest VSTest

Neotest adapter for dotnet

- Based on the VSTest for dotnet allowing test functionality similar to those found in IDEs like Rider and Visual Studio.
  - Will use the new [Microsoft.Testing.Platform](https://learn.microsoft.com/en-us/dotnet/core/testing/microsoft-testing-platform-intro?tabs=dotnetcli) when available for newer projects.
- Supports all testing frameworks.
- DAP strategy for attaching debug adapter to test execution.
- Supports `C#` and `F#`.
- No external dependencies, only the `dotnet sdk` required.
- Can run tests on many groupings including:
  - All tests
  - Test projects
  - Test files
  - Test all methods in class
  - Test individual cases of parameterized tests

## Pre-requisites

neotest-vstest makes a number of assumptions about your environment:

1. The `dotnet sdk`, and the `dotnet` cli executable in the users runtime path.
2. (For Debugging) `netcoredbg` is installed and `nvim-dap` plugin has been configured for `netcoredbg` (see debug config for more details)
3. (recommended) treesitter parser for either `C#` or `F#` allowing run test in file functionality.
4. `neovim v0.10.0` or later

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```
{
  "nsidorenco/neotest-vstest"
}
```

## Usage

```lua
require("neotest").setup({
  adapters = {
    require("neotest-vstest")
  }
})
```

The adapter optionally supports extra settings:

```lua
require("neotest").setup({
  adapters = {
    require("neotest-vstest")({
      -- Path to dotnet sdk path.
      -- Used in cases where the sdk path cannot be auto discovered.
      sdk_path = "/usr/local/dotnet/sdk/9.0.101/",
      -- table is passed directly to DAP when debugging tests.
      dap_settings = {
        type = "netcoredbg",
      }
      -- If multiple solutions exists the adapter will ask you to choose one.
      -- If you have a different heuristic for choosing a solution you can provide a function here.
      solution_selector = function(solutions)
        return nil -- return the solution you want to use or nil to let the adapter choose.
      end
      build_opts = {
          -- Arguments that will be added to all `dotnet build` and `dotnet msbuild` commands
          additional_args = {}
      }
    })
  }
})
```

## Debugging adapter

- Install `netcoredbg` to a location of your choosing and configure `nvim-dap` to point to the correct path

This adapter uses that standard dap strategy in `neotest`. Run it like so:

- `lua require("neotest").run.run({strategy = "dap"})`

## Passing additional arguments to test execution

The adapter supports passing additional arguments to the test runner in multiple ways:

1. **Via adapter configuration** (applies to all test runs):
```lua
require("neotest").setup({
  adapters = {
    require("neotest-vstest")({
      run_opts = {
        additional_args = {
          "/p:CollectCoverage=true",
          "/p:CoverletOutputFormat=lcov",
        },
      },
    })
  }
})
```

2. **Via runtime arguments** (ad-hoc, for specific test runs):
Using `dotnet_additional_args`:
```lua
require("neotest").run.run({
  vim.fn.expand("%"),
  dotnet_additional_args = {
    "--no-build",
    "--filter FullyQualifiedName~TestClass",
    "/p:CollectCoverage=true",
    "/p:CoverletOutputFormat=lcov",
  },
})
```

Or using `additional_args`:
```lua
require("neotest").run.run({
  vim.fn.expand("%"),
  additional_args = {
    "/p:CollectCoverage=true",
    "/p:CoverletOutputFormat=lcov",
    "/p:CoverletOutput=" .. LazyVim.root.git() .. "/coverage/lcov.info",
  },
})
```

### Common arguments

- `--no-build`: Skip building the project before running tests
- `--filter <expression>`: Run only tests matching the filter expression (e.g., `FullyQualifiedName~TestMethod`)
- `/p:<property>=<value>`: Set MSBuild properties (e.g., `/p:CollectCoverage=true` for code coverage)
- `--logger <format>`: Specify test result logger format
- `--configuration Release`: Build in Release configuration

### Important notes

- Arguments containing spaces are automatically quoted, but avoid complex quoting or escaping within argument values
- Arguments are passed to the underlying dotnet test runner, so refer to [dotnet test documentation](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test) for complete list of available options
- Filter expressions should use the format expected by your test framework (MSTest, xUnit, NUnit, etc.)
- When both `dotnet_additional_args` and `additional_args` are provided, `dotnet_additional_args` takes precedence

## Acknowledgements

- [Issafalcon](https://github.com/Issafalcon) for the original [neotest-dotnet](https://github.com/Issafalcon/neotest-dotnet) adapter which inspired this adapter.
- [Wayne Bowie](https://github.com/waynebowie99) for helping test and troubleshoot the adapter.
- [Dynge](https://github.com/Dynge) for testing and contributing to the adapter.
