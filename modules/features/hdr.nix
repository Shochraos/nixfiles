{ config, lib, ... }:
let
  hdrOutputFor =
    outputs:
    let
      hdrOutputs = builtins.attrNames (lib.filterAttrs (_: output: output.hdr) outputs);
    in
    if builtins.length hdrOutputs == 1 then
      builtins.head hdrOutputs
    else
      throw "hdr aspect: expected exactly one host.outputs entry with hdr = true, got ${toString (builtins.length hdrOutputs)}";
in
{
  den.aspects.hdr.provides.to-users.homeManager =
    {
      osConfig,
      pkgs,
      ...
    }:
    let
      hdrOutput = hdrOutputFor osConfig.host.outputs;

      hdr-set = pkgs.writeShellApplication {
        name = "hdr-set";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.diffutils
          pkgs.hyprland
          pkgs.jq
          pkgs.util-linux
        ];
        text = ''
          exec ${pkgs.runtimeShell} ${config.assets.hdrStateScript} --output ${lib.escapeShellArg hdrOutput} "$@"
        '';
      };
    in
    {
      wayland.windowManager.hyprland.extraConfig = ''
        local hdr_state = os.getenv("XDG_RUNTIME_DIR") .. "/nixfiles-hdr/state.lua"
        local hdr_loader = loadfile(hdr_state)
        if hdr_loader then hdr_loader() end
      '';

      systemd.user.services.hdr-state = {
        Unit = {
          Description = "Reap HDR leases whose owner process has exited";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe hdr-set} refresh";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
      systemd.user.timers.hdr-state = {
        Unit.PartOf = [ "graphical-session.target" ];
        Timer.OnUnitActiveSec = "30s";
        Install.WantedBy = [ "graphical-session.target" ];
      };

      home.packages = [
        hdr-set
        (pkgs.writeShellApplication {
          name = "hdr";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.libnotify
            pkgs.util-linux
            hdr-set
          ];
          text = ''
            exec ${pkgs.runtimeShell} ${config.assets.hdrRunScript} "$@"
          '';
        })
      ];
    };
}
