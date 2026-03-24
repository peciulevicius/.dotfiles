-- Local overrides for LazyVim defaults
return {
  -- Use Catppuccin theme (matches tmux)
  {
    'LazyVim/LazyVim',
    opts = { colorscheme = 'catppuccin-mocha' },
  },

  -- Disable plugins you don't need (uncomment to disable)
  -- { 'folke/flash.nvim', enabled = false },
  -- { 'folke/noice.nvim', enabled = false },
}
