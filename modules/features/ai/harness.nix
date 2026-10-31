{ config, inputs, ... }:
{
  den.aspects.ai-harness.provides.to-users.homeManager =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};

      hermesDesktopApplications = hermes.desktop + "/share/applications";

      hermesDesktopEntries = map (name: hermesDesktopApplications + ("/" + name)) (
        builtins.attrNames (
          lib.filterAttrs (name: _: lib.hasSuffix ".desktop" name) (
            builtins.readDir hermesDesktopApplications
          )
        )
      );

      hermesAutostart = lib.optionals (builtins.elem "hermes" osConfig.host.autostart) hermesDesktopEntries;

    in
    {
      home.packages = [ (pkgs.callPackage config.packageSources.rea { }) ];

      xdg.autostart.entries = hermesAutostart;

      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      programs.hermes-agent.desktop.enable = true;

    };
}
