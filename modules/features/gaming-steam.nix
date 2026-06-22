{
  aspects.nixos.gaming =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      proton-cachyos = inputs.nix-proton-cachyos.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos;
      dw-proton = inputs.nix-dw-proton.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton;
    in
    {
      boot.kernelModules = [ "ntsync" ];

      nixpkgs.overlays = [ inputs.millennium.overlays.default ];
      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;
        extraCompatPackages = [
          proton-cachyos
          dw-proton
        ];
      };
    };

  aspects.home.gaming =
    { pkgs, ... }:
    {
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
