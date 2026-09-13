local tools = {
  "bash-language-server",
  "basedpyright",
  "docker-compose-language-service",
  "dockerfile-language-server",
  "eslint-lsp",
  "hadolint",
  "intelephense",
  "json-lsp",
  "lua-language-server",
  "php-cs-fixer",
  "phpcs",
  "prettier",
  "prisma-language-server",
  "ruff",
  "shellcheck",
  "shfmt",
  "sql-formatter",
  "sqls",
  "stylua",
  "tailwindcss-language-server",
  "vtsls",
  "yaml-language-server",
}

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = tools,
      auto_update = false,
      run_on_start = true,
      start_delay = 500,
      debounce_hours = 24,
    },
  },
}
