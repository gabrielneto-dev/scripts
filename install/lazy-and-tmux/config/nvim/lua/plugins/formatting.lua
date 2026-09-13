return {
  {
    "stevearc/conform.nvim",
    opts = {
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        bash = { "shfmt" },
        sh = { "shfmt" },
        lua = { "stylua" },
        php = { "php_cs_fixer" },
        python = { "ruff_format" },
        sql = { "sql_formatter" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        bash = { "shellcheck" },
        sh = { "shellcheck" },
        dockerfile = { "hadolint" },
        php = { "phpcs" },
      },
    },
  },
}
