local Hydra = require("hydra")
local dap = require("dap")

local hint = [[
        _n_: step over       _s_: Continue/Start     _b_: Breakpoint     _e_: Eval
        _i_: step into       _x_: Quit               _c_: to cursor      _W_: scopes
        _o_: step out        _X_: Stop               _R_: Toggle REPL    _C_: Breakpoint Condition   ^ ^
        _B_: Step Back       _U_: ToggleUI           _T_: Terminate      _t_: Debug Nearest Test
        _P_: Pause           _S_: Session            _r_: Run Default Configuration
        ^
        ^ ^              _q_: exit
       ]]

local dap_hydra = Hydra({
  hint = hint,
  config = {
    color = "pink",
    invoke_on_body = true,
    hint = {
      position = "bottom-left",
    },
  },
  name = "dap",
  mode = { "n", "x" },
  body = "<leader>dh",
  heads = {
    { "n", dap.step_over, { silent = true } },
    { "i", dap.step_into, { silent = true } },
    { "B", dap.step_back, { silent = true } },
    { "o", dap.step_out, { silent = true } },
    { "c", dap.run_to_cursor, { silent = true } },
    {
      "C",
      function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      { silent = true },
    },
    { "s", dap.continue, { silent = true } },
    {
      "r",
      function()
        local extension = vim.fn.expand("%:e")
        dap.run(dap.configurations[extension][1])
      end,
      { silent = true },
    },
    {
      "x",
      function()
        require("dap").disconnect({ terminateDebuggee = false })
      end,
      { exit = true, silent = true },
    },
    { "X", dap.close, { silent = true } },
    {
      "U",
      function()
        require("dapui").toggle()
        vim.cmd("DapVirtualTextForceRefresh")
      end,
      { silent = true },
    },
    { "b", dap.toggle_breakpoint, { silent = true } },
    {
      "e",
      function()
        require("dap.ui.widgets").hover()
      end,
      { silent = true },
    },
    {
      "W",
      function()
        require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes)
      end,
      { silent = true },
    },
    {
      "t",
      function()
        require("neotest").run.run({ strategy = "dap" })
      end,
      { exit = true, nowait = true },
    },
    -- {
    --   "<C-j>",
    --   function()
    --     require("dap").down()
    --   end,
    --   { exit = true, nowait = true },
    -- },
    -- {
    --   "<C-k>",
    --   function()
    --     require("dap").up()
    --   end,
    --   { exit = true, nowait = true },
    -- },
    {
      "P",
      function()
        require("dap").pause()
      end,
      { exit = true, nowait = true },
    },
    {
      "R",
      function()
        require("dap").repl.toggle()
      end,
      { exit = true, nowait = true },
    },
    {
      "T",
      function()
        require("dap").terminate()
      end,
      { exit = true, nowait = true },
    },
    {
      "S",
      function()
        require("dap").session()
      end,
      { exit = true, nowait = true },
    },
    { "q", nil, { exit = true, nowait = true } },
  },
})
--
--
--
--
--
--
--

--   local dap = require("dap")
--   --
--   -- Run last: https://github.com/mfussenegger/nvim-dap/issues/1025
--   local last_config = nil
--   ---@param session Session
--   dap.listeners.after.event_initialized["store_config"] = function(session)
--     last_config = session.config
--   end
--
--   local function debug_run_last()
--     if last_config then
--       dap.run(last_config)
--     else
--       dap.continue()
--     end
--   end
--
--   local Hydra = require("hydra")
--
--   local hint = [[
--      ^ ^Step^ ^ ^      ^ ^     Action
--  ----^-^-^-^--^-^----  ^-^-------------------
--      ^ ^back^ ^ ^      _z_: toggle breakpoint
--      ^ ^ _K_^ ^         _Z_: Set conditional breakpoint
--  out _H_ ^ ^ _L_ into   _>_: Continue
--      ^ ^ _J_ ^ ^        _X_: Terminate
--      ^ ^over ^ ^      ^^_s_: open scope
--                   _U_: UI toggle
--                   _g?_: Hydra hint
--                   _gl_: Run last configuration
--                   _*_: Run to cursor
--
--      ^ ^  _<Esc>_: Normal mode
-- ]]
--
--   dap_hydra = Hydra({
--     name = "dap",
--     hint = hint,
--     config = {
--       color = "pink",
--       desc = "Debug mode",
--       invoke_on_body = true,
--       hint = {
--         float_opts = {
--           border = "rounded",
--         },
--         hide_on_load = true,
--         show_name = false,
--       },
--     },
--
--     mode = "n",
--     body = "<Leader>d",
--     heads = {
--       {
--         "U",
--         function()
--           require("dapui").toggle()
--         end,
--       },
--       {
--         "z",
--         function()
--           require("dap").toggle_breakpoint()
--         end,
--       },
--       {
--         "Z",
--         function()
--           require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
--         end,
--       },
--       {
--         ">",
--         function()
--           if vim.bo.filetype ~= "dap-float" then
--             require("dap").continue()
--           end
--         end,
--       },
--       {
--         "K",
--         function()
--           if vim.bo.filetype ~= "dap-float" then
--             require("dap").step_back()
--           end
--         end,
--       },
--       {
--         "H",
--         function()
--           if vim.bo.filetype ~= "dap-float" then
--             require("dap").step_out()
--           end
--         end,
--       },
--       {
--         "J",
--         function()
--           if vim.bo.filetype ~= "dap-float" then
--             print(vim.bo.filetype)
--             require("dap").step_over()
--           end
--         end,
--       },
--       {
--         "L",
--         function()
--           if vim.bo.filetype ~= "dap-float" then
--             require("dap").step_into()
--           end
--         end,
--       },
--       {
--         "gl",
--         function()
--           debug_run_last()
--         end,
--       },
--       {
--         "X",
--         function()
--           require("dap").terminate()
--         end,
--       },
--       {
--         "*",
--         function()
--           require("dap").run_to_cursor()
--         end,
--       },
--       {
--         "s",
--         function()
--           if vim.bo.filetype ~= "dap-float" then
--             require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes)
--           end
--         end,
--       },
--       {
--         "g?",
--         function()
--           if DapHydra.hint.win then
--             DapHydra.hint:close()
--           else
--             DapHydra.hint:show()
--           end
--         end,
--       },
--       { "<Esc>", nil, { exit = true, nowait = true } },
--     },
--   })

Hydra.spawn = function(head)
  if head == "dap-hydra" then
    dap_hydra:activate()
  end
end
