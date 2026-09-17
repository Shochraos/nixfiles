{ lib }:
rec {
  pinnedGeometry =
    output:
    lib.optionalAttrs (output.mode != null) { inherit (output) mode; }
    // lib.optionalAttrs (output.position != null) { inherit (output) position; }
    // lib.optionalAttrs (output.scale != null) { inherit (output) scale; };

  monitorRules =
    outputs:
    lib.mapAttrsToList (name: output: { output = name; } // pinnedGeometry output) (
      lib.filterAttrs (_: output: pinnedGeometry output != { }) outputs
    );

  workspaceRules =
    outputs:
    builtins.concatLists (
      lib.mapAttrsToList (
        name: output:
        lib.imap0 (
          index: workspace:
          {
            workspace = toString workspace;
            monitor = name;
            persistent = true;
          }
          // lib.optionalAttrs (index == 0) { default = true; }
        ) output.workspaces
      ) outputs
    );

  barScreens =
    outputs:
    let
      primaryOutputs = builtins.attrNames (lib.filterAttrs (_: output: output.primary) outputs);
    in
    if builtins.length primaryOutputs > 1 then
      throw "dankshell: at most one host.outputs entry may set primary = true, got ${toString (builtins.length primaryOutputs)}"
    else if primaryOutputs == [ ] then
      [ "all" ]
    else
      primaryOutputs;

  streamingWindowRules =
    streaming:
    lib.optional (streaming.displays != { }) {
      match = {
        class = "^(gamescope)$";
      };
      fullscreen = true;
    };
  streamingEnsureScript =
    { pkgs, streaming }:
    let
      displays = builtins.attrValues streaming.displays;

      lines = builtins.concatStringsSep "\n" (
        map (
          entry:
          let
            geometry = lib.optionalString (entry.scale != null) ", scale = ${entry.scale}";
          in
          ''
            if ! hyprctl monitors -j 2>/dev/null | jq -r '.[].name' | grep -qxF "${entry.output}"; then
              hyprctl output create headless "${entry.output}" >/dev/null 2>&1 || true
            fi
            hyprctl eval 'hl.monitor({ output = "${entry.output}", mode = "${entry.mode}"${geometry} })' >/dev/null 2>&1 || true
          ''
        ) displays
      );
    in
    if displays == [ ] then
      null
    else
      pkgs.writeShellApplication {
        name = "streaming-displays";
        runtimeInputs = with pkgs; [
          gnugrep
          jq
        ];
        text = lines;
      };

  streamingLua =
    script:
    lib.optionalString (script != null) ''
      local function ensure_streaming_displays()
        hl.timer(function()
          hl.exec_cmd("${script}/bin/streaming-displays")
        end, {
          timeout = 500,
          type = "oneshot",
        })
      end

      hl.on("hyprland.start", ensure_streaming_displays)
      hl.on("config.reloaded", ensure_streaming_displays)
    '';

  streamingGeometry =
    display:
    let
      parts = lib.splitString "@" display.mode;
      dims = lib.splitString "x" (builtins.head parts);
    in
    if builtins.length parts != 2 || builtins.length dims != 2 then
      throw "streaming: mode `${display.mode}' must be WIDTHxHEIGHT@REFRESH, e.g. 2560x1440@120"
    else
      {
        width = builtins.elemAt dims 0;
        height = builtins.elemAt dims 1;
        refresh = builtins.elemAt parts 1;
      };

  hdrOutput =
    outputs:
    let
      hdrOutputs = builtins.attrNames (lib.filterAttrs (_: output: output.hdr) outputs);
    in
    if builtins.length hdrOutputs == 1 then
      builtins.head hdrOutputs
    else
      throw "hdr aspect: expected exactly one host.outputs entry with hdr = true, got ${toString (builtins.length hdrOutputs)}";
}
