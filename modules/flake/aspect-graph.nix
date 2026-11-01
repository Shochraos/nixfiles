{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      regenerate = pkgs.writeShellApplication {
        name = "aspect-graph";
        runtimeInputs = [
          pkgs.git
          pkgs.python3
        ];
        text = ''
          root=$(git rev-parse --show-toplevel)
          python3 "$root/assets/scripts/draw-aspects.py" 820 >/dev/null
          if ! git -C "$root" diff --quiet -- assets/aspect-graph.svg; then
            echo "aspect-graph: assets/aspect-graph.svg changed; review and stage it explicitly" >&2
            exit 1
          fi
        '';
      };
    in
    {
      pre-commit.settings.hooks.aspect-graph = {
        enable = true;
        name = "aspect graph";
        description = "Regenerate assets/aspect-graph.svg without changing the Git index";
        entry = lib.getExe regenerate;
        language = "system";
        files = "^(modules/.*\\.nix|assets/scripts/draw-aspects\\.py)$";
        pass_filenames = false;
      };

      checks.aspect-graph =
        pkgs.runCommand "aspect-graph-current"
          {
            nativeBuildInputs = [
              pkgs.git
              pkgs.python3
            ];
          }
          ''
            cp -r ${self} src
            chmod -R u+w src
            cd src
            python3 assets/scripts/draw-aspects.py 820 >/dev/null
            if ! diff -u "${self}/assets/aspect-graph.svg" assets/aspect-graph.svg; then
              echo "aspect-graph: assets/aspect-graph.svg is stale — regenerate it and commit the result" >&2
              exit 1
            fi
            touch "$out"
          '';
    };
}
