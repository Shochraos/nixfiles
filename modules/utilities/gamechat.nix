{ pkgs, username, ... }:
let
  gamechat_mix = pkgs.writeShellScript "gamechat_mix.sh" (builtins.readFile ../../assets/scripts/gamechat_mix.sh);
  gamechat_chat = pkgs.writeShellScript "gamechat_chat.sh" (builtins.readFile ../../assets/scripts/gamechat_chat.sh);
  gamechat_game = pkgs.writeShellScript "gamechat_game.sh" (builtins.readFile ../../assets/scripts/gamechat_game.sh);
  gamechat_reset = pkgs.writeShellScript "gamechat_reset.sh" (builtins.readFile ../../assets/scripts/gamechat_reset.sh);
in
{
  services.pipewire.pulse.enable = true;
  environment.systemPackages = with pkgs; [ pulseaudio ];
  
  home-manager.users.${username} =
  {
    wayland.windowManager.hyprland.settings = 
    {
      bind = 
      [
        ", XF86AudioRaiseVolume, exec, ${gamechat_game}"
        ", XF86AudioLowerVolume, exec, ${gamechat_chat}"
        "CTRL SHIFT, D, exec, ${gamechat_reset}"
      ];
    };
    
    xdg.autostart.entries = 
    [
      "${pkgs.makeDesktopItem 
      {
        name = "gamechat_mix";
        desktopName = "GameChat-Mix";
        exec = "${gamechat_mix}";
        noDisplay = true;
      }
      }/share/applications/gamechat_mix.desktop"
    ];
  };
}