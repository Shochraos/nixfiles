{ config, inputs, ... }:
{
  den.aspects.ai-harness.nixos.programs.ydotool.enable = true;

  den.aspects.ai-harness.provides.to-users.nixos =
    { config, user, ... }:
    {
      users.users.${user.name}.extraGroups = [ config.programs.ydotool.group ];
    };

  den.aspects.ai-harness.provides.to-users.homeManager =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};

      hermesAutostart = lib.optional (builtins.elem "hermes" osConfig.host.autostart) "${hermes.desktop}/share/applications/com.nousresearch.hermes.desktop";

    in
    {
      home.packages = [ (pkgs.callPackage config.packageSources.rea { }) ];

      xdg.autostart.entries = hermesAutostart;

      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      programs.hermes-agent.desktop.enable = true;

    };
}
