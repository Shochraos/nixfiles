{pkgs, ...}:
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" ];
    extraPackages = with pkgs; [ nixd ];
    userSettings = {
      theme = {
        mode = "system";
        dark = "Zedokai Darker (Filter Spectrum)";
        light = "Zedokai Darker (Filter Spectrum)";
      };

      lsp = {
        nixd = {
          settings = { 
            autoArchive = true; 
            flakes = {
              autoEvalInputs = true;
            };
          };
        };
      };

      auto_update = false;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
          
      load_direnv = "shell_hook";
      base_keymap = "VSCode";

      vim_mode = false;
      autosave = { after_delay = { milliseconds = 1000; }; };

      show_whitespaces = "all";
      ui_font_size = 14;
      buffer_font_family = "FiraCode Nerd Font Mono";
      buffer_font_size = 14;
      
      languages = {
        Nix = {
          language_servers = ["nixd" "!nil"];
          tab_size = 2;
        };
      };
    };
  };
}