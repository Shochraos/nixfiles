{ ... }:
{
  programs.plasma = {
      enable = true;
      overrideConfig = true;
  };
  
  imports = 
  [
    ./modules/workspace.nix
    ./modules/window-rules.nix
    ./modules/shortcuts.nix
    ./modules/session.nix
    ./modules/power.nix
    ./modules/panels.nix
    ./modules/kwin.nix
    ./modules/input.nix
    ./modules/configs.nix
  ];
}