return ---@module "lazy"
---@type LazySpec
{
  "afewyards/codereview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "CodeReview",
    "CodeReviewAI",
    "CodeReviewAIFile",
    "CodeReviewStart",
    "CodeReviewSubmit",
    "CodeReviewApprove",
    "CodeReviewOpen",
    "CodeReviewPipeline",
    "CodeReviewComments",
    "CodeReviewFiles",
    "CodeReviewToggleScroll",
    "CodeReviewCommits",
  },
  ---@module "codereview"
  ---@type codereview.Config
  opts = {},
}
