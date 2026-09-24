{
  nixpkgsPath ? <nixpkgs>,
  optionsPath,
  aiPath,
  audioPath,
  dankshellPath,
  hdrPath,
  hyprlandConfigPath,
  hyprlandRulesPath,
  streamingPath,
}:
let
  pkgs = import nixpkgsPath { };
  inherit (pkgs) lib;
  harness = import ./harness.nix { inherit lib pkgs; };
in
(import ./host-options.nix { inherit lib optionsPath; })
// (import ./dankshell.nix { inherit harness dankshellPath; })
// (import ./hdr.nix { inherit harness hdrPath; })
// (import ./hyprland.nix { inherit harness hyprlandConfigPath; })
// (import ./streaming.nix {
  inherit
    lib
    harness
    hyprlandRulesPath
    streamingPath
    ;
})
// (import ./guards.nix { inherit lib aiPath; })
// (import ./audio.nix { inherit lib harness audioPath; })
