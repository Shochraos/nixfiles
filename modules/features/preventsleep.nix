{
  aspects.nixos.preventsleep =
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
