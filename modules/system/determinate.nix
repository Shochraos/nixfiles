{
  aspects.nixos.determinate =
    { inputs, ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      nix.settings.lazy-trees = true;
      nix.settings.eval-cores = 0;

      environment.etc."determinate/config.json".text = builtins.toJSON {
        garbageCollector.strategy = "automatic";
      };
    };
}
