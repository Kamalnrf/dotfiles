-- Autocmds are automatically loaded on the VeryLazy event.
-- Add custom autocmds here.

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.breakindent = true
    vim.opt_local.linebreak = true
    vim.opt_local.relativenumber = false
    vim.opt_local.wrap = true
  end,
})
