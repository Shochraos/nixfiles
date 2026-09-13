{
  nixpkgsPath ? <nixpkgs>,
  optionsPath,
  displayPath,
  aiPath,
  audioPath,
}:
let
  pkgs = import nixpkgsPath { };
  inherit (pkgs) lib;
in
(import ./host-options.nix { inherit lib optionsPath; })
// (import ./display.nix { inherit lib displayPath; })
// (import ./guards.nix { inherit lib aiPath; })
// (import ./audio.nix { inherit lib audioPath; })
