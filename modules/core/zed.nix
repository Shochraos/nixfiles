{  pkgs, username, systemname, ...}:
{
  programs.nix-ld.enable = true;
  
  home-manager.users.${username} = 
  {
    programs.zed-editor = 
    {
      enable = true;
      extensions = [ "nix" ];
      extraPackages = with pkgs; [ nixd ];
      userSettings = 
      {
        lsp = 
        {
          nixd = 
          {
            settings = 
            {
              nixpkgs = 
              {
                expr = "import (builtins.getFlake \"/home/${username}/nixfiles\").inputs.nixpkgs";
              };
              options =
              {
                nixos = 
                {
                  expr = "(builtins.getFlake \"/home/${username}/nixfiles\").nixosConfigurations.${systemname}.options";
                };
                home-manager =
                {
                  expr = "(builtins.getFlake \"/home/${username}/nixfiles\").nixosConfigurations.${systemname}.options.home-manager.users.type.getSubOptions []";
                };
              };
            };
          };
        };
        
        auto_update = false;
        telemetry = 
        {
          diagnostics = false;
          metrics = false;
        };
            
        load_direnv = "shell_hook";
        base_keymap = "VSCode";
  
        vim_mode = false;
        autosave = { after_delay = { milliseconds = 1000; }; };
  
        show_whitespaces = "all";
        
        languages = 
        {
          Nix = 
          {
            language_servers = ["nixd" "!nil"];
            tab_size = 2;
          };
        };
      };
    };
  };
}
