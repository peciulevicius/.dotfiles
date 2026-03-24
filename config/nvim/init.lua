-- Neovim config — LazyVim distribution
-- Primary IDE: WebStorm. This is for terminal/SSH editing.
-- Docs: https://www.lazyvim.org

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- LazyVim setup
require('lazy').setup({
  spec = {
    { 'LazyVim/LazyVim', import = 'lazyvim.plugins' },

    -- Language extras (add what you need)
    { import = 'lazyvim.plugins.extras.lang.typescript' },
    { import = 'lazyvim.plugins.extras.lang.json' },
    { import = 'lazyvim.plugins.extras.lang.tailwind' },
    { import = 'lazyvim.plugins.extras.lang.docker' },
    { import = 'lazyvim.plugins.extras.lang.yaml' },
    { import = 'lazyvim.plugins.extras.lang.markdown' },

    -- Local plugin overrides
    { import = 'plugins' },
  },
  defaults = { lazy = false, version = false },
  change_detection = { notify = false },
})
