{
  den.aspects.crypto = {
    nixos = _: {
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
      {
        home.packages = [
          pkgs.electrum
          #featherLocalTor
        ];
      };
  };
}
