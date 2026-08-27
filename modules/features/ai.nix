{
  den,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (config) assets packageSources;
in
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

    provides.tools.provides.to-users.homeManager =
      { config, pkgs, ... }:
      let
        oh-my-pi = inputs.omp-nix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            if head -c 2 $out/bin/omp | grep -q '#!'; then
              echo "oh-my-pi override: omp-nix ships a wrapper again, so this override double-wraps it" >&2
              exit 1
            fi
            mkdir -p $out/libexec
            mv $out/bin/omp $out/libexec/omp
            makeWrapper $out/libexec/omp $out/bin/omp \
              --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}
          '';
        });

        superpowers-skills = pkgs.callPackage packageSources.superpowersSkills {
          src = inputs.superpowers;
        };

        vendored-skills = pkgs.callPackage packageSources.vendoredSkills {
          inherit (inputs) nixos-skill vercel-skills wshobson-agents;
        };

        overlay = (pkgs.formats.yaml { }).generate "oh-my-pi-config.yml" {
          modelRoles = {
            default = "openrouter/z-ai/glm-5.3-flash:max";
            advisor = "openrouter/moonshotai/kimi-k3:high";
            tiny = "openrouter/z-ai/glm-5.3-flash:low";
            smol = "openrouter/z-ai/glm-5.3-flash:low";
          };
          advisor.enabled = false;
          advisor.syncBacklog = "1";
          autolearn.enabled = true;
          memory.backend = "mnemopi";
          mnemopi.polyphonicRecall = true;
          mnemopi.enhancedRecall = true;
          mnemopi.autoRetain = false;
          mnemopi.recallLimit = 24;
          mnemopi.proactiveLinking = false;
          providers.memoryModel = "online";
          skills.customDirectories = [
            "${superpowers-skills}"
            "${vendored-skills}"
          ];
        };

        overlayPath = "${config.home.homeDirectory}/.omp/agent/nix-config.yml";

        rulesDir = assets.ompRules;

        ruleFiles =
          lib.mapAttrs'
            (name: _: {
              name = ".omp/agent/rules/${name}";
              value.source = rulesDir + "/${name}";
            })
            (
              lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
                builtins.readDir rulesDir
              )
            );
      in
      {
        home.packages = [
          oh-my-pi
        ];

        home.file = {
          ".omp/agent/nix-config.yml".source = overlay;
        }
        // ruleFiles;

        home.sessionVariables.PI_CONFIG_FILES = overlayPath;

        home.sessionVariables.SUPERPOWERS_DISABLE_TELEMETRY = "1";
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

    provides.local.includes = [
      (den.batteries.unfree [
        "cuda_cccl"
        "cuda_compat"
        "cuda_cudart"
        "cuda_nvcc"
        "cuda_nvrtc"
        "libcublas"
      ])
    ];

    provides.local.provides.to-users.homeManager =
      { lib, pkgs, ... }:
      let
        llama-cpp = pkgs.llama-cpp.override { cudaSupport = true; };

        qwenModel = pkgs.fetchurl {
          url = "https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-UD-Q4_K_S.gguf";
          hash = "sha256-dbycituihC5y8KtSAaqgcTPFAQtWYwXAkYf8vc02QBc=";
        };

        reasoningTokens = 65536;
        responseTokens = 32768;

        llamaServerArgs = [
          "--model ${qwenModel}"
          "--alias qwen3.8-27b"
          "--port 8080"
          "--jinja"
          "-ctk q5_1"
          "-ctv q5_1"
          "-c 196608"
          "-n ${toString (reasoningTokens + responseTokens)}"
          "--reasoning-budget ${toString reasoningTokens}"
          "--spec-type draft-mtp"
          "-ctkd q5_1"
          "-ctvd q5_1"
          "--temp 1.0"
          "--top-p 0.95"
          "--top-k 20"
          "--min-p 0.0"
          "--presence-penalty 0.0"
          "--repeat-penalty 1.0"
        ];
      in
      {
        home.packages = [ llama-cpp ];

        systemd.user.services.llama-server = {
          Unit = {
            Description = "LLaMA.cpp Inference Server";
            After = [ "network-online.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${lib.getExe' llama-cpp "llama-server"} ${lib.concatStringsSep " " llamaServerArgs}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
  };
}
