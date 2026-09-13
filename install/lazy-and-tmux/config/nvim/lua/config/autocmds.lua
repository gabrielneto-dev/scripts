local autosave_group = vim.api.nvim_create_augroup("DevKitAutoSave", { clear = true })

local function save_if_needed(args)
  if vim.g.devkit_autosave_disabled then
    return
  end

  local buffer = args.buf
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  if vim.bo[buffer].buftype ~= "" or not vim.bo[buffer].modifiable then
    return
  end
  if vim.bo[buffer].readonly or not vim.bo[buffer].modified then
    return
  end
  if vim.api.nvim_buf_get_name(buffer) == "" then
    return
  end

  pcall(vim.api.nvim_buf_call, buffer, function()
    vim.cmd("silent update")
  end)
end

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  group = autosave_group,
  callback = save_if_needed,
  desc = "Salvamento automático moderado",
})

vim.api.nvim_create_autocmd("FileType", {
  group = autosave_group,
  pattern = { "python", "php" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
  end,
  desc = "Indentação de quatro espaços para Python e PHP",
})
