# NixVim configuration — LazyVim-inspired IDE setup
{ pkgs, config, ... }:

let
  theme = import ./theme.nix;
  current = theme.${theme.active};
in
{
  stylix.targets.nixvim.enable = false;
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    colorscheme = current.neovim.colorscheme;
    extraPlugins = [ pkgs.vimPlugins.${current.neovim.plugin} ];

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      wrap = false;
      ignorecase = true;
      smartcase = true;
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      scrolloff = 8;
      updatetime = 250;
      clipboard = "unnamedplus";
      mouse = "a";
      undofile = true;
      splitright = true;
      splitbelow = true;
      # Hide cmdline when not in use — noice shows it in a floating window,
      # which is the signature LazyVim look.
      cmdheight = 0;
    };

    highlight.IblIndent = {
      # base01 is "lighter background" in base16 — perfect for subtle guides
      fg = "#${config.lib.stylix.colors.base01}";
      nocombine = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    plugins = {
      # Icons (required by telescope, neo-tree, bufferline, lualine, etc.)
      web-devicons.enable = true;

      # Statusline
      lualine.enable = true;

      # Buffer tabs
      bufferline.enable = true;

      # File explorer
      neo-tree.enable = true;

      # Fuzzy finder
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = {
            action = "find_files";
            options.desc = "Find files";
          };
          "<leader>fg" = {
            action = "live_grep";
            options.desc = "Live grep";
          };
          "<leader>fb" = {
            action = "buffers";
            options.desc = "Buffers";
          };
          "<leader>fh" = {
            action = "help_tags";
            options.desc = "Help tags";
          };
          "<leader>fr" = {
            action = "oldfiles";
            options.desc = "Recent files";
          };
          "<leader>fd" = {
            action = "diagnostics";
            options.desc = "Diagnostics";
          };
        };
      };

      # Treesitter — include parsers required by noice
      treesitter = {
        enable = true;
        settings.highlight.enable = true;
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          bash
          lua
          nix
          markdown
          markdown_inline
          vim
          vimdoc
          regex
          python
          javascript
          typescript
          json
          yaml
        ];
      };

      # ── LazyVim UI additions ──────────────────────────────────────────────

      # Dashboard start screen — theme = "dashboard" gives nixvim a valid
      # initial setup call; extraConfigLua below overrides with our custom
      # NixOS snowflake header and buttons.
      alpha = {
        enable = true;
        theme = "dashboard";
      };

      # Notification backend — noice routes vim.notify through this
      notify = {
        enable = true;
        settings = {
          render = "compact";
          stages = "fade";
        };
      };

      # Noice — replaces cmdline, search, and messages with floating windows.
      # This is the single biggest visual difference vs plain neovim.
      noice = {
        enable = true;
        settings = {
          lsp = {
            override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
          };
          presets = {
            bottom_search = true; # classic bottom search bar
            command_palette = true; # cmdline + popup centred on screen
            long_message_to_split = true; # long messages go to a split
            inc_rename = false;
            lsp_doc_border = true; # border on LSP hover/signature docs
          };
        };
      };

      # Highlight TODO / FIXME / NOTE / HACK comments
      todo-comments.enable = true;

      # Flash — enhanced f/t/s jump navigation (LazyVim default).
      # Overrides s → jump, S → treesitter select. Use cl/cc instead of s/S.
      flash.enable = true;

      # ── LSP ──────────────────────────────────────────────────────────────

      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true; # Nix
          hls = {
            # Haskell
            enable = true;
            installGhc = false; # GHC managed in home.packages
          };
          texlab.enable = true; # LaTeX
        };
        keymaps = {
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gi" = "implementation";
            "gr" = "references";
            "K" = "hover";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
          };
          diagnostic = {
            "[d" = "goto_prev";
            "]d" = "goto_next";
          };
        };
      };

      # ── Completion ───────────────────────────────────────────────────────

      cmp = {
        enable = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          mapping = {
            __raw = ''
              cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
              })
            '';
          };
        };
      };
      cmp-nvim-lsp.enable = true;
      cmp-buffer.enable = true;
      cmp-path.enable = true;
      cmp_luasnip.enable = true;
      luasnip.enable = true;

      # ── Editing ──────────────────────────────────────────────────────────

      gitsigns.enable = true;
      comment.enable = true;
      nvim-autopairs.enable = true;
      which-key.enable = true;
      indent-blankline.enable = true;

      # mini.surround — gz prefix avoids conflict with flash's s mapping
      mini = {
        enable = true;
        modules.surround = {
          mappings = {
            add = "gza";
            delete = "gzd";
            find = "gzf";
            find_left = "gzF";
            highlight = "gzh";
            replace = "gzr";
            update_n_lines = "gzn";
          };
        };
      };
    };

    extraConfigLua = ''
      -- Alpha dashboard — NixOS snowflake header with LazyVim-style buttons
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        "          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖          ",
        "          ▜███▙       ▜███▙  ▟███▛           ",
        "           ▜███▙       ▜███▙▟███▛            ",
        "            ▜███▙       ▜██████▛             ",
        "     ▟█████████████████▙ ▜████▛     ▟▙       ",
        "    ▟███████████████████▙ ▜███▙    ▟██▙      ",
        "           ▄▄▄▄▖           ▜███▙  ▟███▛      ",
        "          ▟███▛             ▜██▛ ▟███▛       ",
        "         ▟███▛               ▜▛ ▟███▛        ",
        "▟███████████▛                  ▟██████████▙  ",
        "▜██████████▛                  ▟███████████▛  ",
        "      ▟███▛ ▟▙               ▟███▛           ",
        "     ▟███▛ ▟██▙             ▟███▛            ",
        "    ▟███▛  ▜███▙           ▝▀▀▀▀             ",
        "    ▜██▛    ▜███▙ ▜██████████████████▛       ",
        "     ▜▛     ▟████▙ ▜████████████████▛        ",
        "           ▟██████▙       ▜███▙              ",
        "          ▟███▛▜███▙       ▜███▙             ",
        "         ▟███▛  ▜███▙       ▜███▙            ",
        "         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘            ",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find File",   ":Telescope find_files<CR>"),
        dashboard.button("n", "  New File",    ":ene<CR>"),
        dashboard.button("r", "  Recent",      ":Telescope oldfiles<CR>"),
        dashboard.button("g", "  Grep Text",   ":Telescope live_grep<CR>"),
        dashboard.button("q", "  Quit",        ":qa<CR>"),
      }
      require("alpha").setup(dashboard.config)

      -- Which-key group names (replaces "+N keymaps" with readable labels)
      require('which-key').add({
        { "<leader>f", group = "Find" },
        { "<leader>c", group = "Code" },
        { "<leader>r", group = "Refactor" },
        { "<leader>s", group = "Search" },
        { "<leader>x", group = "Diagnostics" },
        { "<leader>g", group = "Git" },
      })

      -- VS Code: use ASCII separators (status bar can't render Nerd Font icons)
      if vim.g.vscode then
        require('lualine').setup({
          options = {
            icons_enabled = false,
            section_separators = { left = "", right = "" },
            component_separators = { left = "|", right = "|" },
          },
        })
      end
    '';

    keymaps = [
      # ── File explorer ─────────────────────────────────────────────────
      {
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Toggle file explorer";
        mode = "n";
      }

      # ── Buffer navigation ─────────────────────────────────────────────
      {
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Previous buffer";
        mode = "n";
      }
      {
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options.desc = "Next buffer";
        mode = "n";
      }

      # ── Window navigation ─────────────────────────────────────────────
      {
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Move to left window";
        mode = "n";
      }
      {
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Move to lower window";
        mode = "n";
      }
      {
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Move to upper window";
        mode = "n";
      }
      {
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Move to right window";
        mode = "n";
      }

      # ── Search ────────────────────────────────────────────────────────
      {
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
        options.desc = "Clear search highlight";
        mode = "n";
      }

      # ── Flash navigation ──────────────────────────────────────────────
      {
        key = "s";
        action.__raw = "function() require('flash').jump() end";
        options.desc = "Flash jump";
        mode = [
          "n"
          "x"
          "o"
        ];
      }
      {
        key = "S";
        action.__raw = "function() require('flash').treesitter() end";
        options.desc = "Flash treesitter select";
        mode = [
          "n"
          "x"
          "o"
        ];
      }
      {
        key = "r";
        action.__raw = "function() require('flash').remote() end";
        options.desc = "Flash remote";
        mode = "o";
      }
      {
        key = "<C-s>";
        action.__raw = "function() require('flash').toggle() end";
        options.desc = "Toggle flash search";
        mode = "c";
      }

      # ── TODO comments ─────────────────────────────────────────────────
      {
        key = "]t";
        action.__raw = "function() require('todo-comments').jump_next() end";
        options.desc = "Next TODO";
        mode = "n";
      }
      {
        key = "[t";
        action.__raw = "function() require('todo-comments').jump_prev() end";
        options.desc = "Prev TODO";
        mode = "n";
      }
      {
        key = "<leader>xt";
        action = "<cmd>TodoTelescope<cr>";
        options.desc = "TODOs";
        mode = "n";
      }

      # ── Noice ─────────────────────────────────────────────────────────
      {
        key = "<leader>sn";
        action = "<cmd>Noice<cr>";
        options.desc = "Noice messages";
        mode = "n";
      }
    ];
  };
}
