return {
  {
    "AntonVanAssche/music-controls.nvim",
    dependencies = { "rcarriga/nvim-notify" },
  },
  {
    "KadoBOT/nvim-spotify",
    config = function()
      local function next_song()
        vim.fn.jobstart("spt playback --next", {
          on_exit = function()
            force_update()
          end,
        })
      end
      vim.api.nvim_set_keymap("n", "<leader>SS", "<Plug>(SpotifySkip)", { silent = true, desc = "Skip" }) -- Skip the current track
      vim.api.nvim_set_keymap("n", "<leader>SP", "<Plug>(SpotifyPause)", { silent = true, desc = "Pause" }) -- Pause/Resume the current track
      vim.api.nvim_set_keymap("n", "<leader>Ss", "<Plug>(SpotifySave)", { silent = true, desc = "Save" }) -- Add the current track to your library
      vim.api.nvim_set_keymap("n", "<leader>So", ":Spotify<CR>", { silent = true }) -- Open Spotify Search window
      vim.api.nvim_set_keymap("n", "<leader>Sd", ":SpotifyDevices<CR>", { silent = true }) -- Open Spotify Devices window
      vim.api.nvim_set_keymap("n", "<leader>Sp", "<Plug>(SpotifyPrev)", { silent = true, desc = "Previous Song" }) -- Go back to the previous track
      vim.api.nvim_set_keymap("n", "<leader>Sh", "<Plug>(SpotifyShuffle)", { silent = true, desc = "Shuffle" }) -- Toggles shuffle mode
      vim.keymap.set("n", "<leader>Sn", function()
        next_song()
      end, { silent = true, desc = "Next Song" })

      local spotify = require("nvim-spotify")
      spotify.setup({
        -- default opts
        status = {
          update_interval = 10000, -- the interval (ms) to check for what's currently playing
          format = "%s %t by %a", -- spotify-tui --format argument
        },
      })
    end,
    build = "make",
  },
}
