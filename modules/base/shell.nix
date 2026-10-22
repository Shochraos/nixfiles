{ inputs, config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.shell = _: {
    provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        btopConfig = fromTOML (builtins.readFile assets.btopConf);

        flyline = pkgs.callPackage "${inputs.flyline}/nix/package.nix" { };
      in
      {
        home.packages = with pkgs; [
          eza
          fd
          btop
        ];

        programs.bash = {
          enable = true;
          enableCompletion = true;

          historyFile = "${config.home.homeDirectory}/.histfile";
          historySize = 2000;
          historyFileSize = 3000;
          historyControl = [
            "ignoreboth"
            "erasedups"
          ];
          shellOptions = [
            "histappend"
            "checkwinsize"
            "autocd"
            "cdspell"
            "dirspell"
          ];

          shellAliases = {
            cp = "cp -i";
            mv = "mv -i";
            mkdir = "mkdir -p";

            ls = "eza -1 -h -l --icons --no-user --group-directories-first -F";
            la = "eza -1 -h -l --icons -a --no-user --group-directories-first -F";
            lr = "eza -1 -h -l --icons -a -R --no-user --group-directories-first -F";

            nh-switch = "nh os switch --ask";
            nh-boot = "nh os boot --ask";
            nh-update = "nh os boot -u --ask";

            copy = "dms cl copy";
            paste = "dms cl paste";
          };

          initExtra = ''
            [[ -t 0 ]] && stty -ixon
            bind '"\e[1;5D": backward-word'
            bind '"\e[1;5C": forward-word'
            bind 'set bell-style visible'
            bind 'set completion-ignore-case on'
            bind 'set show-all-if-ambiguous on'
            PROMPT_COMMAND+=('history -a')

            command -v trash >/dev/null 2>&1 && alias rm='trash -v'

            enable -f ${flyline}/lib/libflyline.so flyline
            flyline set-style inline-suggestion="dim italic"
            [ -r ~/.cache/flyline/matugen.sh ] && source ~/.cache/flyline/matugen.sh
            flyline set-cursor --backend terminal
          '';
        };

        programs.btop = {
          enable = true;
          settings = btopConfig;
        };

        programs.starship = {
          enable = true;
        };
      };
  };
}
