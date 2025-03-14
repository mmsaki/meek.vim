return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "neovim/nvim-lspconfig",
    { "folke/neoconf.nvim" },
    "saghen/blink.cmp",
    {
      "creativenull/efmls-configs-nvim",
      version = "v1.x.x", -- version is optional, but recommended
    },
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {
        library = {
          -- See the configuration section for more details
          -- Load luvit types when the `vim.uv` word is found
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },
  },
  config = function()
    require("neoconf").setup({})
    local mason = require("mason")
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",
        "rust_analyzer",
        "ts_ls",
        "ruff",
        "pyright",
        "html",
        "cssls",
        "tailwindcss",
        "solidity_ls",
        "solidity_ls_nomicfoundation",
      },
    })
    local blink = require("blink.cmp")
    local capabilities = blink.get_lsp_capabilities()
    require("lspconfig").lua_ls.setup({ capabilities = capabilities })
    require("lspconfig").ts_ls.setup({ capabilities = capabilities })
    require("lspconfig").tailwindcss.setup({ capabilities = capabilities })
    require("lspconfig").rust_analyzer.setup({ capabilities = capabilities })
    require("lspconfig").ruff.setup({ capabilities = capabilities })
    require("lspconfig").pyright.setup({ capabilities = capabilities })
    require("lspconfig").cssls.setup({ capabilities = capabilities })
    -- require("lspconfig").solidity_ls.setup({})
    require("lspconfig").solidity_ls_nomicfoundation.setup({})

    -- vim.api.nvim_create_autocmd("FileType", {
    -- 	-- This handler will fire when the buffer's 'filetype' is "python"
    -- 	pattern = "solidity",
    -- 	callback = function(args)
    -- 		vim.lsp.start({
    -- 			name = "@msaki Wake solidity lsp server",
    -- 			cmd = { "nc", "localhost", "65432" }, -- NOTE: should be started manually
    -- 			-- cmd = { "solc", "--lsp", "--base-path", ".", "--include-paths", "./lib/" },
    -- 			-- Set the "root directory" to the parent directory of the file in the
    -- 			-- current buffer (`args.buf`) that contains either a "setup.py" or a
    -- 			-- "pyproject.toml" file. Files that share a root directory will reuse
    -- 			-- the connection to the same LSP server.
    -- 			root_dir = vim.fs.root(args.buf, { "foundry.toml", ".git" }),
    -- 			settings = {
    -- 				wake = {
    -- 					configuration = {
    -- 						use_toml_if_present = true,
    -- 						toml_path = "wake.toml",
    -- 					},
    -- 					lsp = {
    -- 						compilation_delay = 0,
    -- 						find_references = {
    -- 							include_declarations = true,
    -- 						},
    -- 						code_lens = {
    -- 							enable = false,
    -- 						},
    -- 						detectors = {
    -- 							enable = true,
    -- 						},
    -- 					},
    -- 				},
    -- 			},
    -- 		})
    -- 	end,
    -- })
    -- Register linters and formatters per language
    local languages = {
      javascript = {
        require("efmls-configs.linters.eslint"),
        require("efmls-configs.formatters.prettier"),
      },
      javascriptreact = {
        require("efmls-configs.linters.eslint"),
        require("efmls-configs.formatters.prettier"),
      },
      typescript = {
        require("efmls-configs.linters.eslint"),
        require("efmls-configs.formatters.prettier"),
      },
      typescriptreact = {
        require("efmls-configs.linters.eslint"),
        require("efmls-configs.formatters.prettier"),
      },
      solidity = {
        require("efmls-configs.linters.solhint"),
        require("efmls-configs.formatters.forge_fmt"),
      },
      lua = {
        require("efmls-configs.formatters.stylua"),
      },
      python = {
        require("efmls-configs.linters.ruff"),
        require("efmls-configs.formatters.ruff"),
      },
      rust = {
        require("efmls-configs.formatters.rustfmt"),
      },
      json = {
        require("efmls-configs.linters.jq"),
        require("efmls-configs.formatters.jq"),
      },
      markdown = {
        require("efmls-configs.linters.markdownlint"),
        require("efmls-configs.formatters.mdformat"),
      },
    }

    -- Or use the defaults provided by this plugin
    -- check doc/SUPPORTED_LIST.md for all the defaults provided
    --
    -- local languages = require('efmls-configs.defaults').languages()

    local efmls_config = {
      filetypes = vim.tbl_keys(languages),
      settings = {
        rootMarkers = { ".git/" },
        languages = languages,
      },
      init_options = {
        documentFormatting = true,
        documentRangeFormatting = true,
        hover = true,
        completion = true,
        codeAction = true,
        documentSymbol = true,
      },
    }

    require("lspconfig").efm.setup(vim.tbl_extend("force", efmls_config, {
      -- Pass your cutom config below like on_attach and capabilities
      --
      -- on_attach = on_attach,
      -- capabilities = capabilities,
    }))
    -- on lsp attach
    local vim_fmt_autogroup = vim.api.nvim_create_augroup("LspFormattingGroup", { clear = false })
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim_fmt_autogroup,
      callback = function(args)
        vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client.supports_method("textDocument/implementation", args.buf) then
          -- Create a keymap for vim.lsp.buf.implementation
          local function on_list(options)
            vim.fn.setqflist({}, " ", options)
            vim.cmd.cfirst()
          end

          vim.lsp.buf.implementation({ on_list = on_list })
        end

        if client.supports_method("textDocument/completion", args.buf) then
          -- Enable auto-completion
          vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end

        if client.supports_method("textDocument/formatting", args.buf) then
          -- Format the current buffer on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = args.buf,
            callback = function()
              local efm = vim.lsp.get_clients({ name = "efm" })

              if vim.tbl_isempty(efm) then
                return
              end

              vim.lsp.buf.format({ name = "efm", async = true, bufnr = args.buf, id = client.id })
            end,
          })
        end
      end,
    })
  end,
}
