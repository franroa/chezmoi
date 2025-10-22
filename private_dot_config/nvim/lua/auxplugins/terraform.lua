-- https://www.pmareke.com/posts/terraform-nvim/
return {
  -- {
  --   "mvaldes14/terraform.nvim",
  --   ft = "terraform",
  --   opts = {
  --     program = "terraform",
  --     cmd = "grep",
  --   },
  --   config = function()
  --     vim.api.nvim_create_autocmd("BufWritePost", {
  --       pattern = { "*.tf" },
  --       callback = function()
  --         vim.cmd("TerraformValidate")
  --       end,
  --     })
  --   end,
  -- },
  {
    "hashivim/vim-terraform",
  },
  {
    "hashivim/vim-packer",
  },
  {
    "sontungexpt/url-open",
    branch = "main",
    event = "VeryLazy",
    cmd = "URLOpenUnderCursor",
    config = function()
      local status_ok, url_open = pcall(require, "url-open")
      if not status_ok then
        return
      end
      url_open.setup({
        extra_patterns = {
          {
            pattern = 'data ["]aws_([^%s]*)["]',
            prefix = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/",
            file_patterns = { ".*.tf" },
          },
        },
      })
    end,
  },
}
