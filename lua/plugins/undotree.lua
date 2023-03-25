vim.keymap.set("n", "<leader>t", vim.cmd.UndotreeToggle, { desc = "Undo tree" })

vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
return {
  "mbbill/undotree",
}
