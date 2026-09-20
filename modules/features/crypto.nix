{
  den.aspects.crypto = {
    nixos =
      { ... }:
      {
        services.tor = {
          enable = true;
          client = {
            enable = true;
            socksListenAddress.port = 9050;
          };
        };
      };

    provides.to-users.homeManager =
      { lib, pkgs, ... }:
      let
        featherLocalTor =
          pkgs.runCommandLocal "feather-local-tor"
            {
              nativeBuildInputs = [ pkgs.makeWrapper ];
            }
            ''
              makeWrapper ${lib.getExe pkgs.feather} $out/bin/feather --add-flags --use-local-tor
              cp -r ${pkgs.feather}/share $out/share
            '';
      in
      {
        home.packages = [
          pkgs.electrum
          featherLocalTor
        ];
      };
  };
}
