{ pkgs, username, ... }: {

  # --- NixOS Ebene (Systemweit) ---
  environment.systemPackages = with pkgs; [
    kitty
    direnv
  ];

  # --- Home-Manager Ebene (User-spezifisch) ---
  home-manager.users.${username} = {
    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
      };
    };

    # Home-Manager State Version (muss in jedem HM-Profil stehen)
    home.stateVersion = "25.05";
  };
}