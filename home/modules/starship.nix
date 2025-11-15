{pkgs, ...}:
{
  programs.starship = {
      enable = true;
      settings =
      {
            format = ''
            [╭╴](fg:arrow)$username$directory($git_branch$git_status)($nix_shell)($python$c$cpp)$cmd_duration
            [╰─](fg:arrow)$character
            '';

              add_newline = true;
              palette = "foo";

              palettes.foo = {
                arrow = "#353535";
                os = "#C60C34";
                directory = "#FF5B2E";
                git = "#B02B10";
                git_status = "#8B1D2C";
                python = "#F0B40F";
                clang = "#00599D";
                clangpp = "#00329D";
                nix_shell = "#2565BE";
                duration = "#64B5A5";
                text_color = "#EDF2F4";
                text_light = "#EDF2F4";
              };

            username = {
                format = "[]($style)[ shochraos](bg:$style fg:text_color)[]($style)";
                style_user = "os";
                show_always = true;
                disabled = false;
              };

              character = {
                success_symbol = "[󰍟](fg:arrow)";
                error_symbol = "[󰍟](fg:red)";
              };

            directory = {
                format = " [](fg:directory)[  $path ]($style)[$read_only]($read_only_style)[](fg:directory)";
                truncation_length = 3;
                style = "fg:text_color bg:directory";
                read_only_style = "fg:text_color bg:directory";
                before_repo_root_style = "fg:text_color bg:directory";
                truncation_symbol = "…/";
                truncate_to_repo = true;
                read_only = "  ";
              };

            git_branch = {
                format = " [](fg:git)[$symbol$branch](fg:text_light bg:git)[](fg:git)";
                symbol = " ";
              };

              git_status = {
                format = "([ ](fg:git_status)[ $all_status$ahead_behind ]($style)[](fg:git_status))";
                style = "fg:text_light bg:git_status";
              };

            cmd_duration = {
                format = " [](fg:duration)[ $duration]($style)[](fg:duration)";
                style = "fg:text_light bg:duration";
                min_time = 500;
              };

            python = {
                format = "[ ](fg:python)[$symbol$pyenv_prefix($version )(\($virtualenv\))]($style)[](fg:python)";
                symbol = " ";
                version_format = "$raw";
                style = "fg:text_light bg:python";
                disabled = false;
              };

              c = {
                format = "[ ](fg:clang)[$symbol($version(-$name) )](bg:clang fg:text_color)[](fg:clang)";
                symbol = " ";
                version_format = "$raw";
                disabled = false;
              };

              cpp = {
                format = "[ ](fg:clangpp)[$symbol($version(-$name) )](bg:clangpp fg:text_color)[](fg:clangpp)";
                symbol = " ";
                disabled = false;
              };

              nix_shell = {
                  format = "[ ](fg:nix_shell)[ ($name)]($style)[](fg:nix_shell)";
                  style = "bg:nix_shell fg:text_color";
                  disabled = false;
                };
      };
};
}