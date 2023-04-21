return {
  colorscheme = "catppuccin",
  lsp = {
    servers = {
      "solidity"
    },
    config = {
      solidity = function()
        return {
          cmd = { 'nomicfoundation-solidity-language-server', '--stdio' },
          filetypes = { 'solidity' },
          single_file_support = true,
          root_dir = require("lspconfig.util").root_pattern("hardhat.config.js", "hardhat.config.ts");
        }
      end,
    },
    setup_handlers = {
      -- add custom handler
      rust_analyzer = function(_, opts) 
        local rt = require "rust-tools"

        local extension_path = vim.env.HOME .. '/.vscode/extensions/vadimcn.vscode-lldb-1.9.0/'
        local codelldb_path = extension_path .. 'adapter/codelldb'
        local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'  -- MacOS: This may be .dylib

        local dap = {
          adapter = require('rust-tools.dap').get_codelldb_adapter(
          codelldb_path, liblldb_path)
        }

        rt.setup { 
          hover_actions = {
            auto_focues = true,
          },
          dap = dap, 
          server = opts,
        } 
        vim.keymap.set("n", "<Leader>rg", rt.code_action_group.code_action_group, { buffer = bufnr, desc = "Open Action Group" })
        vim.keymap.set("n", "<Leader>ra", rt.hover_actions.hover_actions, { buffer = bufnr, desc = "Open Hover Actions" })
      end,
      tsserver = function(_, opts) require("typescript").setup { server = opts } end,
      gopls = function(_, opts) 
        require('go').setup { lsp_cfg = opts }
        local cfg = require'go.lsp'.config() -- config() return the go.nvim gopls setup

        require('lspconfig').gopls.setup(cfg)
      end,
    },
  },
  plugins = {
    "jose-elias-alvarez/typescript.nvim", -- add lsp plugin
    "simrat39/rust-tools.nvim", -- add lsp plugin
    "ray-x/go.nvim",
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
        ensure_installed = { "rust_analyzer", "tsserver", "gopls" },
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
          suggestion = { enabled = false },
          panel = { enabled = false },
        })
      end,
    },
    {
      "zbirenbaum/copilot-cmp",
      config = function(_, opts)
        local copilot_cmp = require "copilot_cmp"
        local opts = {
          formatters = {
            label = require("copilot_cmp.format").format_label_text,
            insert_text = require("copilot_cmp.format").remove_existing,
            preview = require("copilot_cmp.format").deindent,
          },
        }
        copilot_cmp.setup(opts)
      end
    },
    {
      "hrsh7th/nvim-cmp",
      dependencies = { "zbirenbaum/copilot.lua" },
      opts = function(_, opts)
        local cmp, copilot = require "cmp", require "copilot.suggestion"
        local function has_words_before()
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
        end
        if not opts.mapping then opts.mapping = {} end
        -- opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
        --   if copilot.is_visible() then
        --     copilot.accept()
        --   elseif cmp.visible() then
        --     cmp.select_next_item()
        --   elseif luasnip.expand_or_jumpable() then
        --     luasnip.expand_or_jump()
        --   elseif has_words_before() then
        --     cmp.complete()
        --   else
        --     fallback()
        --   end
        -- end, { "i", "s" })
        opts.mapping["<Tab>"] = vim.schedule_wrap(function(fallback)
          if cmp.visible() and has_words_before() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end 
        end)
        opts.mapping["<CR>"] = cmp.mapping.confirm {
			    behavior = cmp.ConfirmBehavior.Replace,
			    select = true,
		    }
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
        opts.sources = {
          { name = "copilot", priority = 1250, group_index = 2 },
          { name = "nvim_lsp", priority = 1000, group_index = 2  },
          { name = "luasnip", priority = 750, group_index = 2  },
          { name = "buffer", priority = 500, group_index = 2 },
          { name = "path", priority = 250, group_index = 2  },
        }

        local lspkind_comparator = function(conf)
          local lsp_types = require('cmp.types').lsp
          return function(entry1, entry2)
            if entry1.source.name ~= 'nvim_lsp' then
              if entry2.source.name == 'nvim_lsp' then
                return false
              else
                return nil
              end
            end
            local kind1 = lsp_types.CompletionItemKind[entry1:get_kind()]
            local kind2 = lsp_types.CompletionItemKind[entry2:get_kind()]

            local priority1 = conf.kind_priority[kind1] or 0
            local priority2 = conf.kind_priority[kind2] or 0
            if priority1 == priority2 then
              return nil
            end
            return priority2 < priority1
          end
        end
        opts.sorting = {
          priority_weight = 2,
          comparators = {
            require("copilot_cmp.comparators").prioritize,
            -- Below is the default comparitor list and order for nvim-cmp
            cmp.config.compare.offset,
            -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
            cmp.config.compare.exact,
            cmp.config.compare.score,
            lspkind_comparator({
              kind_priority = {
                Copilot = 13,
                Field = 12,
                Property = 11,
                Constant = 10,
                Enum = 10,
                EnumMember = 10,
                Event = 10,
                Function = 10,
                Method = 10,
                Operator = 10,
                Reference = 10,
                Struct = 10,
                Variable = 12,
                File = 8,
                Folder = 8,
                Class = 5,
                Color = 5,
                Module = 5,
                Keyword = 2,
                Constructor = 1,
                Interface = 1,
                Snippet = 0,
                Text = 1,
                TypeParameter = 1,
                Unit = 1,
                Value = 1,
              },
            }),
            cmp.config.compare.kind,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        }
        local lspkind = require("lspkind")
        lspkind.symbol_map["Copilot"] = ""
        vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {fg ="#6CC644"})
        
        return opts
      end,
    },
  },
}
