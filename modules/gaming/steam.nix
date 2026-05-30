{
  username,
  inputs,
  pkgs,
  ...
}:
let
  proton-cachyos = inputs.nix-proton-cachyos.packages.${pkgs.system}.proton-cachyos;
in
{
  boot.kernelModules = [ "ntsync" ];

  nixpkgs.overlays = [ inputs.millennium.overlays.default ];
  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
    extraCompatPackages =
    [ 
      pkgs.proton-ge-bin
      proton-cachyos 
    ];
  };

  home-manager.users.${username} = {
    home.sessionVariables = {
      PROTON_DLSS_UPGRADE = "1";
      VKD3D_CONFIG = "descriptor_heap";
    };

    xdg.autostart = {
      entries = [
        "${pkgs.steam}/share/applications/steam.desktop"
      ];
    };
  };
}
