{ inputs, lib, ... }:
{
  den.aspects.ai-stt = {
    nixos =
      { pkgs, ... }:
      let
        lua = lib.generators.mkLuaInline;
        voxtype = lib.getExe pkgs.voxtype-vulkan;
      in
      {
        host.hyprland.keybinds = [
          {
            _args = [
              "code:201"
              (lua "hl.dsp.exec_cmd('${voxtype} record start')")
            ];
          }
          {
            _args = [
              "code:201"
              (lua "hl.dsp.exec_cmd('${voxtype} record stop')")
              { release = true; }
            ];
          }
        ];

        host.dms.plugins.voxtypeActivityOverlay.enable = true;
      };

    provides.to-users.homeManager =
      { pkgs, ... }:
      let
        whisperModel = pkgs.fetchurl {
          url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin";
          hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
        };

        transcriptCapture = pkgs.writeShellApplication {
          name = "voxtype-transcript-capture";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/voxtype"
            mkdir -p "$state_dir"
            exec tee "$state_dir/activity-overlay-last.txt"
          '';
        };

        voxtypeSettings = (pkgs.formats.toml { }).generate "voxtype-config.toml" {
          hotkey.enabled = false;

          audio = {
            device = "default";
            sample_rate = 16000;
            max_duration_secs = 60;
          };

          whisper = {
            model = "${whisperModel}";
            language = [
              "en"
              "de"
            ];
            translate = false;
            context_window_optimization = false;
          };

          output = {
            mode = "type";
            fallback_to_clipboard = true;

            post_process = {
              command = lib.getExe transcriptCapture;
              timeout_ms = 2000;
            };
          };
        };

        overlayPlugin =
          inputs.dms-plugin-registry.packages.${pkgs.stdenv.hostPlatform.system}.voxtypeActivityOverlay;
      in
      {
        home.packages = [ pkgs.voxtype-vulkan ];

        xdg.configFile = {
          "voxtype/config.toml".source = voxtypeSettings;
          "cava/dms-voxtype-activity-overlay.ini".source =
            "${overlayPlugin}/config/cava/dms-voxtype-activity-overlay.ini";
        };

        systemd.user.services.voxtype = {
          Unit = {
            Description = "Voxtype push-to-talk voice-to-text daemon";
            PartOf = [ "graphical-session.target" ];
            Wants = [ "pipewire-pulse.service" ];
            After = [
              "graphical-session.target"
              "pipewire.service"
              "pipewire-pulse.service"
            ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${lib.getExe pkgs.voxtype-vulkan} -q -c ${voxtypeSettings} daemon";
            Restart = "on-failure";
            RestartSec = 5;
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
  };
}
