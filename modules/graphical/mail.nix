{
  den.aspects.mail = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.tutanota-desktop ];
      };
  };
}
