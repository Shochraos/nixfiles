{ pkgs, username, ... }:
{
  services.pipewire.pulse.enable = true;
  environment.systemPackages = with pkgs; [ pulseaudio ];
  
  home-manager.users.${username} =
  {
    wayland.windowManager.hyprland.settings = 
    {
      bind = 
      [
        ", XF86AudioRaiseVolume, exec, /home/${username}/Scripts/Pipewire/gamechat_game.sh"
        ", XF86AudioLowerVolume, exec, /home/${username}/Scripts/Pipewire/gamechat_chat.sh"
        "CTRL SHIFT, D, exec, /home/${username}/Scripts/Pipewire/gamechat_reset.sh"
      ];
    };
  };
}