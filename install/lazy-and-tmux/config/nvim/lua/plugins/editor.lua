return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      transparent = false,
      styles = {
        comments = { italic = true },
        keywords = { italic = false },
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      keymap = { preset = "super-tab" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        virtual_text = {
          spacing = 2,
          source = "if_many",
          prefix = "●",
        },
      },
      servers = {
        bashls = {},
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = true },
      picker = { enabled = true },
      terminal = { enabled = true },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = true,
        diagnostics = "nvim_lsp",
      },
    },
  },
}
