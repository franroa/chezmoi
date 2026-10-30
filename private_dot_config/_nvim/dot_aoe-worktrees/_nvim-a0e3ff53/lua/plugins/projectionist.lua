return {
  {
    "tpope/vim-projectionist",
    config = function()
      vim.g.projectionist_heuristics = {
        ["*"] = {
          ["src/Gims/Gims.API/Controllers/*CommandController.cs"] = {
            alternate = {
              "src/Gims/Gims.API.Application/Rules/Commands/Insert/Insert{basename}Command.cs",
              "test/Gims/Gims.API.Test/Controllers/{}CommandControllerTest.cs",
              "../../requests/{}.http",
            },
            type = "controller",
          },
          ["src/Gims/Gims.API.Application/**/Commands/Insert/Insert*Command.cs"] = {
            alternate = "test/Gims/Gims.API.Test/Controllers/{}CommandControllerTest.cs",
            type = "insert",
          },
          ["test/Gims/Gims.API.Test/Controllers/*CommandControllerTest.cs"] = {
            alternate = "src/Gims/Gims.API/Controllers/{}CommandController.cs",
            type = "controllertest",
          },
          ["../../requests/*.http"] = {
            alternate = "src/Gims/Gims.API/Controllers/{}CommandController.cs",
            type = "requests",
          },
        },
        --   [".csproj"] = {
        --     ["src/*.cs"] = {
        --       type = "source",
        --       alternate = {
        --         "test/{}.cs",
        --         "docs/{}.md",
        --         "config/{}.json",
        --         "src/Controllers/{}.cs",
        --         "src/Handlers/{}.cs",
        --       },
        --       template = {
        --         "using System;",
        --         "namespace {namespace}",
        --         "{",
        --         "    public class {basename}",
        --         "    {",
        --         "    }",
        --         "}",
        --       },
        --     },
        --     ["test/*.cs"] = {
        --       type = "test",
        --       alternate = "src/{}.cs",
        --       template = {
        --         "using Xunit;",
        --         "namespace {namespace}",
        --         "{",
        --         "    public class {basename}Tests",
        --         "    {",
        --         "        [Fact]",
        --         "        public void Test1()",
        --         "        {",
        --         "        }",
        --         "    }",
        --         "}",
        --       },
        --     },
        --     ["docs/*.md"] = {
        --       type = "docs",
        --       alternate = "src/{}.cs",
        --       template = {
        --         "# {basename}",
        --         "",
        --         "Documentation for {basename}.",
        --       },
        --     },
        --     ["config/*.json"] = {
        --       type = "config",
        --       alternate = "src/{}.cs",
        --       template = {
        --         "{",
        --         '  "name": "{basename}",',
        --         '  "description": "Configuration for {basename}"',
        --         "}",
        --       },
        --     },
        --     ["src/Controllers/*.cs"] = {
        --       type = "controller",
        --       alternate = "src/{}.cs",
        --       template = {
        --         "using Microsoft.AspNetCore.Mvc;",
        --         "namespace {namespace}.Controllers",
        --         "{",
        --         "    [ApiController]",
        --         '    [Route("api/[controller]")]',
        --         "    public class {basename}Controller : "
        --           .. (vim.g.uses_basecontroller and "BaseController" or "ControllerBase"),
        --         "    {",
        --         "    }",
        --         "}",
        --       },
        --     },
        --     ["src/Handlers/*.cs"] = {
        --       type = "handler",
        --       alternate = "src/{}.cs",
        --       template = {
        --         "using System.Threading.Tasks;",
        --         "namespace {namespace}.Handlers",
        --         "{",
        --         "    public class {basename}Handler",
        --         "    {",
        --         "        public Task HandleAsync()",
        --         "        {",
        --         "            // Handler logic here",
        --         "        }",
        --         "    }",
        --         "}",
        --       },
        --     },
        --   },
      }
    end,
    -- event = "User AstroFile",
  },
}
