{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config) assets;

in
{
  den.aspects.ai-harness = {
    nixos =
      { config, user, ... }:
      {
        sops.secrets."commandcode/api-key" = {
          owner = user.name;
        };

        sops.templates."hermes.env" = {
          owner = user.name;
          content = ''
            COMMANDCODE_API_KEY=${config.sops.placeholder."commandcode/api-key"}
          '';
        };
      };

    provides.to-users.homeManager =
      {
        config,
        osConfig,
        pkgs,
        ...
      }:
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

        superpowers-skills =
          inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.superpowers-skills;

        vendored-skills =
          inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.vendored-skills;

        managed-skills =
          inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.omp-managed-skills;

        shared-skills = inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.shared-skills;

        hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};

        hermesSkills = inputs.agent-skills-nix.lib.${pkgs.stdenv.hostPlatform.system}.mkSkillset [
          "vendored-avoid-ai-writing"
          "shared-cloudflare-bypass"
          "hermes-architecture-diagram"
          "hermes-ascii-video"
          "hermes-baoyu-infographic"
          "hermes-claude-design"
          "hermes-design-md"
          "hermes-humanizer"
          "hermes-manim-video"
          "hermes-p5js"
          "hermes-popular-web-designs"
          "hermes-songwriting-and-ai-music"
          "hermes-gif-search"
          "hermes-songsee"
          "hermes-youtube-content"
          "hermes-arxiv"
          "hermes-competitor-news-monitor"
          "hermes-grounded-citations"
          "hermes-llm-wiki"
          "hermes-blocked-page-recovery"
          "hermes-docx"
          "hermes-pdf"
          "hermes-xlsx"
          "hermes-latex-writing"
          "hermes-hermes-agent"
        ];

        hermesManagedSkills =
          inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.hermes-managed-skills;

        scrapling-runtime =
          inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.scrapling-runtime;

        mcp-config = (pkgs.formats.json { }).generate "mcp.json" {
          "$schema" =
            "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
          mcpServers.ScraplingServer = {
            type = "stdio";
            command = "${scrapling-runtime}/bin/scrapling-mcp";
            timeout = 120000;
          };
        };

        overlaySettings = {
          modelRoles = {
            default = "commandcode/deepseek/deepseek-v4.1-flash";
            tiny = "commandcode/deepseek/deepseek-v4.1-flash";
            smol = "commandcode/deepseek/deepseek-v4.1-flash";
            vision = "commandcode/z-ai/glm-5.3-flash";
          };
          autolearn.enabled = true;
          memory.backend = "mnemopi";
          mnemopi.polyphonicRecall = true;
          mnemopi.enhancedRecall = true;
          mnemopi.autoRetain = false;
          mnemopi.recallLimit = 24;
          mnemopi.proactiveLinking = false;
          mnemopi.workingMemoryTtlHours = 876000;
          mnemopi.workingMemoryLimit = 1000000;
          providers.memoryModel = "online";
          startup.checkUpdate = false;
          ttsr.repeatMode = "after-gap";
          skills.customDirectories = [
            "${superpowers-skills}"
            "${vendored-skills}"
            "${managed-skills}"
            "${shared-skills}"
          ];
        };

        overlay = (pkgs.formats.yaml { }).generate "oh-my-pi-config.yml" overlaySettings;

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
          ".omp/agent/mcp.json".source = mcp-config;
        }
        // ruleFiles;

        home.sessionVariables.PI_CONFIG_FILES = overlayPath;

        home.sessionVariables.SUPERPOWERS_DISABLE_TELEMETRY = "1";

        imports = [ inputs.hermes-agent.homeManagerModules.default ];

        programs.hermes-agent.enable = true;

        services.hermes-agent = {
          enable = true;
          package = hermes.minimal;
          environmentFiles = [ osConfig.sops.templates."hermes.env".path ];
          hermesHomeFiles."SOUL.md" = assets.hermesSoul;
          mcpServers.ScraplingServer = {
            command = "${scrapling-runtime}/bin/scrapling-mcp";
          };
          settings = {
            agent.coding_context = "off";
            browser.backend = "off";
            model = {
              provider = "commandcode";
              default = "Qwen/Qwen3.8-Omni-Flash";
            };
            skills = {
              create_dir = "${config.home.homeDirectory}/Repositories/nix/agent-skills-nix/skills/hermes-managed";
              external_dirs = [
                "${hermesSkills}"
                "${hermesManagedSkills}"
              ];
            };
            updates.check = false;
          };
        };
      };
  };
}
