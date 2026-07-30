{
  inputs,
  lib,
  den,
  ...
}:
{
  den.aspects.ai = {
    __functor =
      self: args:
      let
        allowed = [
          "local"
          "stt"
        ];
        unknown = if builtins.isAttrs args then builtins.attrNames (removeAttrs args allowed) else [ ];
      in
      if !builtins.isAttrs args then
        throw "den.aspects.ai must be called with an argument set, e.g. (ai { stt = true; })"
      else if unknown != [ ] then
        throw "den.aspects.ai: unknown argument(s) ${lib.concatStringsSep ", " unknown} — expected only ${lib.concatStringsSep ", " allowed}"
      else
        {
          includes = [
            self.tools
          ]
          ++ lib.optional (args.local or false) self.local
          ++ lib.optional (args.stt or false) self.stt;
        };

    provides.tools.includes = [ (den.batteries.unfree [ "claude-code" ]) ];

    provides.tools.provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        oh-my-pi = inputs.omp-nix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.patchelf ];
          dontFixup = true;
          postInstall = (old.postInstall or "") + ''
            unwrapped=$(sed -n "s/^export BUN_SELF_EXE='\(.*\)'$/\1/p" $out/bin/omp)
            test -x "$unwrapped" || {
              echo "oh-my-pi override: could not locate the unwrapped binary in the omp-nix wrapper" >&2
              exit 1
            }
            rm $out/bin/omp
            install -Dm755 "$unwrapped" $out/libexec/omp
            patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/libexec/omp
            makeWrapper $out/libexec/omp $out/bin/omp \
              --set BUN_SELF_EXE $out/libexec/omp \
              --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}
          '';
        });

        overlay = (pkgs.formats.yaml { }).generate "oh-my-pi-config.yml" {
          modelRoles = {
            default = "anthropic/claude-opus-5:high";
            advisor = "anthropic/claude-opus-4-6:high";
            tiny = "anthropic/claude-haiku-4-5:medium";
            smol = "anthropic/claude-haiku-4-5:medium";
          };
          advisor.enabled = true;
          advisor.syncBacklog = "1";
          autolearn.enabled = true;
          memory.backend = "mnemopi";
          mnemopi.polyphonicRecall = true;
          mnemopi.enhancedRecall = true;
          mnemopi.autoRetain = false;
          mnemopi.recallLimit = 24;
          mnemopi.proactiveLinking = false;
          providers.memoryModel = "online";
        };

        overlayPath = "${config.home.homeDirectory}/.omp/agent/nix-config.yml";
      in
      {
        home.packages = [
          oh-my-pi
        ];

        home.file.".omp/agent/nix-config.yml".source = overlay;

        home.sessionVariables.PI_CONFIG_FILES = overlayPath;
      };

    provides.stt.nixos =
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

    provides.stt.provides.to-users.homeManager =
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

    provides.local.provides.to-users.homeManager =
      { lib, pkgs, ... }:
      let
        llama-cpp = pkgs.llama-cpp.override { cudaSupport = true; };

        qwenModel = pkgs.fetchurl {
          url = "https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen3.6-35B-A3B-UD-Q5_K_XL.gguf";
          hash = lib.fakeHash;
        };
      in
      {
        home.packages = [ llama-cpp ];

        systemd.user.services = {
          llama-server = {
            Unit = {
              Description = "LLaMA.cpp Inference Server";
              After = [ "network-online.target" ];
              PartOf = [ "llama-stack.target" ];
            };
            Service = {
              Type = "simple";
              ExecStart = "${lib.getExe' llama-cpp "llama-server"} --model ${qwenModel} --port 8081 --jinja -ctk q8_0 -ctv q8_0 -c 262144 -n 32768 --temp 0.6 --top-p 0.95 --top-k 20 --presence-penalty 0.0 --min-p 0.0";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };

          openwebui = {
            Unit = {
              Description = "Open WebUI";
              After = [ "network-online.target" ];
              PartOf = [ "llama-stack.target" ];
            };
            Service = {
              Type = "simple";
              StateDirectory = "open-webui";
              Environment = "DATA_DIR=%S/open-webui";
              ExecStart = "${lib.getExe pkgs.open-webui} serve";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
        };

        systemd.user.targets.llama-stack = {
          Unit = {
            Description = "LLaMA Stack";
            Requires = [
              "llama-server.service"
              "openwebui.service"
            ];
            After = [
              "llama-server.service"
              "openwebui.service"
            ];
          };
        };
      };
  };
}
