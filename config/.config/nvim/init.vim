" ==========================================================
"                  MODULAR NEOVIM SETUP
" ==========================================================

" 1. Load Plugins
source ~/.config/nvim/core/plugins.vim

" 2. Core Settings & Keymaps
source ~/.config/nvim/core/settings.vim
source ~/.config/nvim/core/keymaps.vim

" 3. Plugin Configurations
source ~/.config/nvim/plugin_config/coc.vim
source ~/.config/nvim/plugin_config/telescope.vim
source ~/.config/nvim/plugin_config/nerdtree.vim

" 4. Load Generated Theme + hot-reload watcher
lua << EOF
pcall(function() require("theme") end)

-- File-watch: re-apply theme when theme.lua changes on disk.
-- The generator (flavors/generate.py) signals us via nvim RPC,
-- but FocusGained is a safety net for terminal re-focus.
local theme_file = vim.fn.stdpath("config") .. "/lua/theme.lua"
local last_mtime = 0

local function check_theme_change()
  local stat = vim.uv.fs_stat(theme_file)
  if not stat then return end
  local mtime = stat.mtime.sec
  if last_mtime > 0 and mtime ~= last_mtime then
    if _G.ReloadTheme then
      _G.ReloadTheme()
      vim.notify("theme flipped", vim.log.levels.INFO)
    end
  end
  last_mtime = mtime
end

-- Seed the mtime on startup
check_theme_change()

vim.api.nvim_create_augroup("OsyxThemeFlip", { clear = true })

-- When Neovim regains focus (e.g. Alt-Tab back from terminal)
vim.api.nvim_create_autocmd("FocusGained", {
  group = "OsyxThemeFlip",
  callback = check_theme_change,
})

-- Direct signal: the themes() function sends us a command via --remote-send
vim.api.nvim_create_user_command("OsyxFlip", function()
  check_theme_change()
end, { desc = "Re-read theme.lua from disk and apply" })
EOF
