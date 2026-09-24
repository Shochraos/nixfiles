{
  den.aspects.pdfpc = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.pdfpc ];
      };
  };
}
