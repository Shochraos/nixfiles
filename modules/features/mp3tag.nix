{ den, config, ... }:
let
  inherit (config) assets;

  mp3tagOverlay = final: _prev: {
    mp3tag = final.callPackage config.packageSources.mp3tag { };
  };
in
{
  den.aspects.mp3tag = {
    includes = [ (den.batteries.unfree [ "mp3tag" ]) ];

    nixos.nixpkgs.overlays = [ mp3tagOverlay ];

    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mp3tag ];

        xdg.desktopEntries = {
          mp3tag = {
            name = "MP3Tag";
            exec = "mp3tag";
            terminal = false;
            startupNotify = false;
            icon = "${assets.mp3tagIcon}";
          };
        };
      };
  };
}
