{ inputs, config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.shell = _: {
    provides.to-users.homeManager =
      { pkgs, ... }:
      let
        btopConfig = fromTOML (builtins.readFile assets.btopConf);

        flyline = pkgs.callPackage "${inputs.flyline}/nix/package.nix" { };
      in
      {
        home.packages = with pkgs; [
          eza
          fd
          btop
        ];

        programs.bash = {
          enable = true;

          shellAliases = {
            ls = "eza -1 -h -l --icons --no-user --group-directories-first -F";
            la = "eza -1 -h -l --icons -a --no-user --group-directories-first -F";
            lr = "eza -1 -h -l --icons -a -R --no-user --group-directories-first -F";

            nh-switch = "nh os switch --ask";
            nh-boot = "nh os boot --ask";
            nh-update = "nh os boot -u --ask";

            copy = "dms cl copy";
            paste = "dms cl paste";
          };

          initExtra = ''
            enable -f ${flyline}/lib/libflyline.so flyline
            flyline set-style inline-suggestion="dim italic"
          '';
        };

        programs.btop = {
          enable = true;
          settings = btopConfig;
        };

        programs.starship = {
          enable = true;
        };
      };
  };
}
