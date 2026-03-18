{ config, inputs, pkgs, username, ... }:
{
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; 
    [
      xdg-desktop-portal-gtk
    ];
  
    config = 
    {
      hyprland =
      {
        default = [ "hyprland" "gtk" ];
      };
    };
  };
    
  programs.hyprland = 
  {
   enable = true; 
   withUWSM = true;
  };
  
  programs.dconf.enable = true;
  
  environment.systemPackages = with pkgs; 
  [ 
    playerctl
  ];
  
  home-manager.users.${username} = 
  {
    imports = [ inputs.dms.homeModules.dank-material-shell ];
    
    xdg.configFile."uwsm/env".source = "${config.home-manager.users.${username}.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"; 
    
    home.sessionVariables = 
    {
      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland,x11,*";
      SDL_VIDEODRIVER = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };
    
    programs.dank-material-shell = 
    {
      enable = true;
      
      systemd = 
      {
          enable = true;
          restartIfChanged = true;
      };
      
      # Core features
      enableSystemMonitoring = true; 
      enableVPN = true; 
      enableDynamicTheming = false;
      enableAudioWavelength = true;
      enableCalendarEvents = true; 
      
      settings = 
      {
        dynamicTheming = false;
      };
    };
    
    wayland.windowManager.hyprland = 
    {
        enable = true;
        systemd.enable = false;
        
        settings = 
        {       
          misc = 
          {
            middle_click_paste = false;
          };
          
          input = 
          {
            kb_layout = "de"; 
            kb_variant = "nodeadkeys";
          };
          
          general = 
          {
            gaps_in = 5;
            gaps_out = 5;
            border_size = 0;
        
            #"col.active_border" = "rgba(707070ff)";
            #"col.inactive_border" = "rgba(d0d0d0ff)";
        
            layout = "dwindle";
          };
        
          decoration = {
            rounding = 12;
        
            active_opacity = 1.0;
            inactive_opacity = 0.9;
        
            shadow = {
              enabled = true;
              range = 30;
              render_power = 5;
              
              offset = "0 5";
              color = "rgba(00000070)";
            };
          };
          
          workspace = 
          [
              "1, persistent:true"
              "2, persistent:true"
              "3, persistent:true"
          ];
          
          exec-once = 
          [                   
            "bash -c 'wl-paste --watch cliphist store &'"
          ];
          
          layerrule = 
          [
            #"noanim, ^(dms)$"
          ];

          windowrule = 
          [
            #"match:app-id ^(org.quickshell)$, float on"
            
            "match:class ^(discord)$, workspace 2"
            "match:class ^(spotify)$, workspace 2"
            
            "match:class ^(zen-beta)$, workspace 3"
            "match:class ^(steam)$, workspace 3"
            
            "match:class ^(Discord)$, float on"
            # Arknights Endfield
            "match:class ^(endfield.exe)$, match:title ^(Form)$, float on, suppress_event maximize fullscreen activatefocus, fullscreen_state 0 0, workspace 3 silent"
          ];
          
          dwindle = 
          {
            force_split = 2;
            preserve_split = true;
          };
          
          bezier = 
          [
                  "snappy, 0.05, 0.9, 0.1, 1.05"
          ];
          
          source = 
          [
            "~/.config/hypr/dms/colors.conf"
            "~/.config/hypr/dms/layout.conf"
            "~/.config/hypr/dms/outputs.conf"
          ];
          
          "$mod" = "SUPER";
          bind = 
          [
            "$mod, Return, exec, ghostty"
            "$mod SHIFT, M, exit"
            "$mod, Q, killactive"
            
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"
    
            "$mod SHIFT, left, movewindow, l"
            "$mod SHIFT, right, movewindow, r"
            "$mod SHIFT, up, movewindow, u"
            "$mod SHIFT, down, movewindow, d"
            
            "$mod CTRL, left, workspace, m-1"
            "$mod CTRL, right, workspace, m+1"
            
            "$mod, L, exec, dms ipc call lock lock"
            
            "$mod, F, exec, dolphin"
            
            "$mod, Space, exec, dms ipc call spotlight toggle"
            
            # Application specific binds
            ", F6, sendshortcut, CTRL SHIFT, M, class:^(discord)$"
            ", F7, sendshortcut, CTRL SHIFT, D, class:^(discord)$"
            ", F8, exec, playerctl --player=spotify previous"
            ", F9, exec, playerctl --player=spotify play-pause"
            ", F10, exec, playerctl --player=spotify next"
            ", F11, exec, playerctl --player=spotify volume 0.05-"
            ", F12, exec, playerctl --player=spotify volume 0.05+"
          ];
        };
    };
  };
}