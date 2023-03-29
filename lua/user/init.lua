return {
  colorscheme = "catppuccin",
  lsp = {
    setup_handlers = {
      -- add custom handler
      rust_analyzer = function(_, opts) require("rust-tools").setup { server = opts } end,
      tsserver = function(_, opts) require("typescript").setup { server = opts } end
    },
  },
  plugins = {
    "jose-elias-alvarez/typescript.nvim", -- add lsp plugin
    "simrat39/rust-tools.nvim", -- add lsp plugin
    {
      "ggandor/leap.nvim",
      event = "UIEnter",
      config = function()
        require("leap").add_default_mappings()
      end,
    },
    {
      "williamboman/mason-lspconfig.nvim",
      opts = {
        ensure_installed = { "rust_analyzer", "tsserver" },
      },
    },
    {
      "catppuccin/nvim",
      as = "catppuccin",
      config = function()
        require("catppuccin").setup {}
      end,
    },
    {
      "zbirenbaum/copilot.lua",
      event = "UIEnter",
      dependencies = {
        "zbirenbaum/copilot-cmp"
      },
      config = function()
        require("copilot").setup({
          suggestion = { auto_trigger = true, debounce = 150 },
        })
      end,
    },
    {
      "hrsh7th/nvim-cmp",
      dependencies = { "zbirenbaum/copilot.lua" },
      opts = function(_, opts)
        local cmp, copilot = require "cmp", require "copilot.suggestion"
        local snip_status_ok, luasnip = pcall(require, "luasnip")
        if not snip_status_ok then return end
        local function has_words_before()
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
        end
        if not opts.mapping then opts.mapping = {} end
        opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
          if copilot.is_visible() then
            copilot.accept()
          elseif cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" })
        opts.mapping["<C-e>"] = cmp.mapping {
          i = function(fallback)
            if copilot.is_visible() then
              copilot.dismiss()
            elseif not cmp.abort() then
              fallback()
            end
          end,
          c = function(fallback)
            if copilot.is_visible() then
              copilot.dismiss()
            elseif not cmp.close() then
              fallback()
            end
          end,
        }

        return opts
      end,
    },
  },
}
