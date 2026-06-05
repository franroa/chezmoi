return {
  "aldevv/md-preview.nvim",
  ft = { "markdown" },
  build = ":MdPreviewInstall",
  config = function()
    require("md-preview").setup()
  end,
}
