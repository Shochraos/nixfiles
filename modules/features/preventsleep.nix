{
  den.aspects.preventsleep.nixos =
    { ... }:
    {
      systemd.targets = {
        "suspend".enable = false;
        "hibernate".enable = false;
        "hybrid-sleep".enable = false;
        "suspend-then-hibernate".enable = false;
      };
    };
}
