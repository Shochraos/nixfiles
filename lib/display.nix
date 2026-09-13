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
