local map = vim.keymap.set

map({ "n", "i", "v" }, "<C-s>", "<cmd>write<cr>", { desc = "Salvar arquivo" })
map("n", "<leader>W", "<cmd>wall<cr>", { desc = "Salvar todos os arquivos" })
map("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Explorador de arquivos" })
map("n", "<leader>tt", function()
  Snacks.terminal()
end, { desc = "Terminal flutuante" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Sair do modo terminal" })
map("n", "<leader>uA", function()
  vim.g.devkit_autosave_disabled = not vim.g.devkit_autosave_disabled
  vim.notify("Salvamento automático: " .. (vim.g.devkit_autosave_disabled and "desativado" or "ativado"))
end, { desc = "Alternar salvamento automático" })
