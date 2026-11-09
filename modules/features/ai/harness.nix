{ config, inputs, ... }:
{
  den.aspects.ai-harness.nixos.programs.ydotool.enable = true;

  den.aspects.ai-harness.provides.to-users.nixos =
    { config, user, ... }:
    {
      users.users.${user.name}.extraGroups = [ config.programs.ydotool.group ];
    };

  den.aspects.ai-harness.provides.to-users.homeManager =
    hm@{
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};

      compatiblePatchelf =
        dependency:
        if (dependency.pname or "") == "patchelf" && (dependency.version or "") == "0.15.2" then
          dependency.overrideAttrs (previous: {
            patches = lib.filter (
              patch:
              !(
                builtins.isAttrs patch && (patch.name or "") == "patchelf-fix-executable-header-load-overlap.patch"
              )
            ) (previous.patches or [ ]);
          })
        else
          dependency;

      hermesPackage = hermes.default.override (previous: {
        pmPackages = lib.mapAttrs (
          _: package:
          package.overrideAttrs (old: {
            nativeBuildInputs = map compatiblePatchelf (old.nativeBuildInputs or [ ]);
          })
        ) previous.pmPackages;
      });

      hermesAutostart = lib.optional (builtins.elem "hermes" osConfig.host.autostart) "${hm.config.programs.hermes-agent.desktop.package}/share/applications/com.nousresearch.hermes.desktop";

    in
    {
      home.packages = [ (pkgs.callPackage config.packageSources.rea { }) ];

      xdg.autostart.entries = hermesAutostart;

      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      services.hermes-agent.package = hermesPackage;
      programs.hermes-agent.desktop.enable = true;

    };
}
