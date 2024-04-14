{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib.options) mkOption mkEnableOption literalExpression;
  inherit (lib.lists) isList;
  inherit (lib.types) enum either package listOf str bool;
  inherit (lib.nvim.lua) expToLua;
  inherit (lib.nvim.types) diagnostics mkGrammarOption;

  cfg = config.vim.languages.bash;

  defaultServer = "bash-ls";
  servers = {
    bash-ls = {
      package = pkgs.nodePackages.bash-language-server;
      lspConfig = ''
        lspconfig.bashls.setup{
          capabilities = capabilities;
          on_attach = default_on_attach;
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''{"${cfg.lsp.package}/bin/bash-language-server",  "start"}''
        };
        }
      '';
    };
  };

  defaultFormat = "shfmt";
  formats = {
    shfmt = {
      package = pkgs.shfmt;
      nullConfig = ''
        table.insert(
          ls_sources,
          null_ls.builtins.formatting.shfmt.with({
            command = "${pkgs.shfmt}/bin/shfmt",
          })
        )
      '';
    };
  };

  defaultDiagnosticsProvider = ["shellcheck"];
  diagnosticsProviders = {
    shellcheck = {
      package = pkgs.shellcheck;
      nullConfig = pkg: ''
        table.insert(
          ls_sources,
          null_ls.builtins.diagnostics.shellcheck.with({
            command = "${pkg}/bin/shellcheck",
          })
        )
      '';
    };
  };
in {
  options.vim.languages.bash = {
    enable = mkEnableOption "Bash language support";

    treesitter = {
      enable = mkEnableOption "Bash treesitter" // {default = config.vim.languages.enableTreesitter;};
      package = mkGrammarOption pkgs "bash";
    };

    lsp = {
      enable = mkEnableOption "Enable Bash LSP support" // {default = config.vim.languages.enableLSP;};

      server = mkOption {
        description = "Bash LSP server to use";
        type = enum (attrNames servers);
        default = defaultServer;
      };

      package = mkOption {
        description = "bash-language-server package, or the command to run as a list of strings";
        example = literalExpression ''[lib.getExe pkgs.nodePackages.bash-language-server "start"]'';
        type = either package (listOf str);
        default = pkgs.nodePackages.bash-language-server;
      };
    };

    format = {
      enable = mkOption {
        description = "Enable Bash formatting";
        type = bool;
        default = config.vim.languages.enableFormat;
      };
      type = mkOption {
        description = "Bash formatter to use";
        type = enum (attrNames formats);
        default = defaultFormat;
      };

      package = mkOption {
        description = "Bash formatter package";
        type = package;
        default = formats.${cfg.format.type}.package;
      };
    };

    extraDiagnostics = {
      enable = mkEnableOption "extra Bash diagnostics" // {default = config.vim.languages.enableExtraDiagnostics;};
      types = diagnostics {
        langDesc = "Bash";
        inherit diagnosticsProviders;
        inherit defaultDiagnosticsProvider;
      };
    };
  };
}