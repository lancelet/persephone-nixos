# NixVim configuration — full IDE-like setup
{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # General options
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
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    plugins = {
      # Icons (required by telescope, neo-tree, bufferline)
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
          "<leader>ff" = { action = "find_files"; options.desc = "Find files"; };
          "<leader>fg" = { action = "live_grep"; options.desc = "Live grep"; };
          "<leader>fb" = { action = "buffers"; options.desc = "Buffers"; };
          "<leader>fh" = { action = "help_tags"; options.desc = "Help tags"; };
        };
      };

      # Treesitter
      treesitter = {
        enable = true;
        settings.highlight.enable = true;
      };

      # LSP
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;   # Nix
          hls = {                 # Haskell
            enable = true;
            installGhc = false;   # GHC managed in home.packages
          };
          texlab.enable = true;   # LaTeX
          # Lean 4: leanls not yet ported to neovim's built-in LSP API;
          # use VS Code or add lean.nvim when upstream support lands.
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

      # Completion
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

      # Git
      gitsigns.enable = true;

      # Editing
      comment.enable = true;
      nvim-autopairs.enable = true;
      which-key.enable = true;
      indent-blankline.enable = true;
    };

    # Keymaps
    keymaps = [
      { key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "Toggle file explorer"; mode = "n"; }
      { key = "<S-h>"; action = "<cmd>bprevious<cr>"; options.desc = "Previous buffer"; mode = "n"; }
      { key = "<S-l>"; action = "<cmd>bnext<cr>"; options.desc = "Next buffer"; mode = "n"; }
      { key = "<C-h>"; action = "<C-w>h"; options.desc = "Move to left window"; mode = "n"; }
      { key = "<C-j>"; action = "<C-w>j"; options.desc = "Move to lower window"; mode = "n"; }
      { key = "<C-k>"; action = "<C-w>k"; options.desc = "Move to upper window"; mode = "n"; }
      { key = "<C-l>"; action = "<C-w>l"; options.desc = "Move to right window"; mode = "n"; }
      { key = "<Esc>"; action = "<cmd>nohlsearch<cr>"; options.desc = "Clear search highlight"; mode = "n"; }
    ];
  };
}
