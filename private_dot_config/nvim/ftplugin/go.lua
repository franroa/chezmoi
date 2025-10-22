local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

map("n", "<leader>La", "<cmd>GoCodeAction<cr>", { desc = "Go code action" })
map("n", "<leader>Le", "<cmd>GoIfErr<cr>", { desc = "Add if err" })

-- Helper
map("n", "<leader>Lha", "<cmd>GoAddTag<cr>", { desc = "Add tags to struct" })
map("n", "<leader>Lhr", "<cmd>GoRMTag<cr>", { desc = "Remove tag from struct" })
map("n", "<leader>Lhc", "<cmd>GoCoverage<cr>", { desc = "Test coverage" })
map("n", "<leader>Lhg", "<cmd>lua require('go.comment').gen()<cr>", { desc = "Generate comment" })
map("n", "<leader>Lhv", "<cmd>GoVet<cr>", { desc = "Go vet" })
map("n", "<leader>Lhr", "<cmd>GoModTidy<cr>", { desc = "Go mod tidy" })
map("n", "<leader>Lhj", "<cmd>GoModInit<cr>", { desc = "Go mod init" })

map("n", "<leader>Li", "<cmd>GoToggleInlay<cr>", { desc = "Toggle inlay" })
map("n", "<leader>Ll", "<cmd>GoLint<cr>", { desc = "Run linter" })
map("n", "<leader>Lo", "<cmd>GoPkgOutline<cr>", { desc = "Outline" })
map("n", "<leader>Lr", "<cmd>GoRun<cr>", { desc = "Run" })
map("n", "<leader>Ls", "<cmd>GoFillStruct<cr>", { desc = "Autofill struct" })

-- Tests
map("n", "<leader>Ltr", "<cmd>GoTest<cr>", { desc = "Run tests" })
map("n", "<leader>Lta", "<cmd>GoAlt!<cr>", { desc = "Open alt file" })
map("n", "<leader>LtS", "<cmd>GoAltS!<cr>", { desc = "Open alt file in split" })
map("n", "<leader>LtV", "<cmd>GoAltV!<cr>", { desc = "Open alt file in vertical split" })
map("n", "<leader>Ltu", "<cmd>GoTestFunc<cr>", { desc = "Run test for current function" })
map("n", "<leader>LtF", "<cmd>GoTestFile<cr>", { desc = "Run test for current file" })

-- Code Lens
map("n", "<leader>Lxl", "<cmd>GoCodeLenAct<cr>", { desc = "Toggle Lens" })
map("n", "<leader>Lxa", "<cmd>GoCodeAction<cr>", { desc = "Code Action" })

map("n", "<leader>Lj", "<cmd>'<,'>GoJson2Struct<cr>", { desc = "Json to struct" })

-- Debugging
map("n", "<leader>dT", function()
  require("dap-go").debug_test()
end, { desc = "debug closest test" })

-- Change window's working diretory for the go testing script to be able to work
vim.cmd("lcd %:p:h")

local vo = vim.opt_local
vo.tabstop = 4
vo.shiftwidth = 4
vo.softtabstop = 4

local wk = require("which-key").register({
  h = { name = "+helper" },
  x = { name = "+code lens" },
}, { prefix = "<leader>L" })
