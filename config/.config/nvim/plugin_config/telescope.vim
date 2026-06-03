lua << EOF
local ok_telescope, telescope = pcall(require, "telescope")
if not ok_telescope then
  return
end

local actions = require("telescope.actions")
local ok_fb, fb_actions = pcall(require, "telescope._extensions.file_browser.actions")

telescope.setup({
  defaults = {
    vimgrep_arguments = { "rg", "--hidden", "--glob", "!.git/*", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
    sorting_strategy = "ascending",
    layout_config = { prompt_position = "top" },
    mappings = { i = { ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist }, n = { ["q"] = actions.close } },
  },
  pickers = { live_grep = { only_sort_text = true }, grep_string = { only_sort_text = true } },
  extensions = ok_fb and {
    file_browser = {
      hijack_netrw = true,
      grouped = true,
      hidden = true,
      respect_gitignore = false,
      mappings = {
        ["n"] = { ["a"] = fb_actions.create, ["r"] = fb_actions.rename, ["d"] = fb_actions.remove, ["m"] = fb_actions.move, ["y"] = fb_actions.copy },
        ["i"] = { ["<C-n>"] = fb_actions.create, ["<C-r>"] = fb_actions.rename, ["<C-d>"] = fb_actions.remove, ["<C-m>"] = fb_actions.move, ["<C-y>"] = fb_actions.copy },
      },
    },
  } or {},
})

pcall(function() telescope.load_extension("file_browser") end)
EOF

nnoremap <leader>f :Telescope file_browser path=%:p:h<CR>
nnoremap <silent> <leader>r <cmd>Telescope live_grep<cr>
nnoremap <silent> <leader>R <cmd>Telescope grep_string<cr>
