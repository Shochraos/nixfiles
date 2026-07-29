{ den, ... }:
let
  mp3tagOverlay = final: _prev: {
    mp3tag = final.callPackage ../../pkgs/mp3tag/package.nix { };
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
            icon = "${../../assets/icons/mp3tag.png}";
          };
        };
      };
  };
}
