{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config) assets packageSources;

in
{
  den.aspects.ai-harness =
    _:
    let
      honchoServerOverlay = final: _prev: {
        honchoServer = final.callPackage packageSources.honchoServer { };
      };
    in
    {
      nixos =
        {
          config,
          user,
          pkgs,
          ...
        }:
        {
          nixpkgs.overlays = [ honchoServerOverlay ];

          sops.secrets."commandcode/api-key" = {
            owner = user.name;
          };

          sops.secrets."hermes/opencode-go-api-key" = {
            owner = user.name;
          };

          sops.secrets."opencode/opencode-go-api-key" = {
            owner = user.name;
          };
          sops.templates."hermes.env" = {
            owner = user.name;
            content = ''
              COMMANDCODE_API_KEY=${config.sops.placeholder."commandcode/api-key"}
              OPENCODE_GO_API_KEY=${config.sops.placeholder."hermes/opencode-go-api-key"}
            '';
          };

          services.postgresql = {
            enable = true;
            extensions = ps: [ ps.pgvector ];
            ensureDatabases = [ "honcho" ];
            ensureUsers = [
              {
                name = "honcho";
                ensureDBOwnership = true;
              }
            ];
          };

          users.users.honcho = {
            isSystemUser = true;
            group = "honcho";
          };
          users.groups.honcho = { };

          systemd.services.honcho-migrate = {
            description = "Honcho database migrations";
            after = [ "postgresql.service" ];
            requires = [ "postgresql.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "honcho";
              EnvironmentFile = config.sops.templates."honcho.env".path;
              WorkingDirectory = "${pkgs.honchoServer}/share/honcho";
            };
            environment.DB_CONNECTION_URI = "postgresql+psycopg://honcho@/honcho?host=/run/postgresql";
            path = [ pkgs.honchoServer ];
            script = ''
              exec ${pkgs.honchoServer}/bin/honcho-migrate
            '';
          };

          systemd.services.honcho-api = {
            description = "Honcho local memory server";
            after = [ "honcho-migrate.service" ];
            requires = [ "honcho-migrate.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              User = "honcho";
              EnvironmentFile = config.sops.templates."honcho.env".path;
              Restart = "on-failure";
            };
            environment = {
              DB_CONNECTION_URI = "postgresql+psycopg://honcho@/honcho?host=/run/postgresql";
              VECTOR_STORE_TYPE = "pgvector";
              AUTH_USE_AUTH = "false";
            };
            script = ''
              exec ${pkgs.honchoServer}/bin/honcho-api src.main:app --host 127.0.0.1 --port 8000
            '';
          };

          systemd.services.honcho-deriver = {
            description = "Honcho background deriver worker";
            after = [ "honcho-api.service" ];
            requires = [ "honcho-api.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              User = "honcho";
              EnvironmentFile = config.sops.templates."honcho.env".path;
              Restart = "on-failure";
            };
            environment.DB_CONNECTION_URI = "postgresql+psycopg://honcho@/honcho?host=/run/postgresql";
            script = ''
              exec ${pkgs.honchoServer}/bin/honcho-deriver
            '';
          };

          sops.templates."honcho.env" = {
            content = ''
              LLM_OPENAI_API_KEY=${config.sops.placeholder."hermes/opencode-go-api-key"}
              DERIVER_MODEL_CONFIG__TRANSPORT=openai
              DERIVER_MODEL_CONFIG__MODEL=muse-spark-1.3-contributor
              DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=https://opencode.ai/zen/go/v1
              DIALECTIC_MODEL_CONFIG__TRANSPORT=openai
              DIALECTIC_MODEL_CONFIG__MODEL=muse-spark-1.3-contributor
              DIALECTIC_MODEL_CONFIG__OVERRIDES__BASE_URL=https://opencode.ai/zen/go/v1
              SUMMARY_MODEL_CONFIG__TRANSPORT=openai
              SUMMARY_MODEL_CONFIG__MODEL=muse-spark-1.3-contributor
              SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL=https://opencode.ai/zen/go/v1
              DREAM_MODEL_CONFIG__TRANSPORT=openai
              DREAM_MODEL_CONFIG__MODEL=muse-spark-1.3-contributor
              DREAM_MODEL_CONFIG__OVERRIDES__BASE_URL=https://opencode.ai/zen/go/v1
              EMBEDDING_MODEL_CONFIG__TRANSPORT=openai
              EMBEDDING_MODEL_CONFIG__MODEL=text-embedding-3-small
              EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL=https://opencode.ai/zen/go/v1
              # LLM_OPENAI_API_KEY=${config.sops.placeholder."commandcode/api-key"}
              # DERIVER_MODEL_CONFIG__MODEL=meta/muse-spark-1.3-contributor
              # DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              # DIALECTIC_MODEL_CONFIG__MODEL=meta/muse-spark-1.3-contributor
              # DIALECTIC_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              # SUMMARY_MODEL_CONFIG__MODEL=meta/muse-spark-1.3-contributor
              # SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              # DREAM_MODEL_CONFIG__MODEL=meta/muse-spark-1.3-contributor
              # DREAM_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              # EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
            '';
          };
        };

      provides.to-users.homeManager =
        {
          osConfig,
          pkgs,
          ...
        }:
        let
          vendored-skills =
            inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.vendored-skills;

          shared-skills = inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.shared-skills;

          hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};

          hermesAutostart = lib.optional (builtins.elem "hermes" osConfig.host.autostart) "${hermes.desktop}/share/applications/hermes.desktop";

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
            "hermes-gif-search"
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
            "hermes-paper2agent"
            "hermes-hermes-agent"
            "hermes-opencode"
            "hermes-honcho"
            "hermes-scrapling"
            "hermes-rss-feeds"
            "hermes-research-paper-writing"
            "hermes-codebase-inspection"
            "hermes-dogfood"
            "hermes-github"
            "hermes-hermes-agent-skill-authoring"
            "hermes-inspecting-hermes-desktop-dom"
            "hermes-node-inspect-debugger"
            "hermes-python-debugpy"
            "hermes-requesting-code-review"
            "hermes-simplify-code"
            "hermes-spike"
            "hermes-systematic-debugging"
            "hermes-test-driven-development"
          ];

          scrapling-runtime =
            inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.scrapling-runtime;

          opencodeConfig = (pkgs.formats.json { }).generate "opencode.json" {
            "$schema" = "https://opencode.ai/config.json";
            model = "opencode-go/muse-spark-1.3-contributor";
            autoupdate = false;
            # provider.commandcode = {
            #   npm = "@ai-sdk/openai-compatible";
            #   name = "CommandCode";
            #   options = {
            #     baseURL = "https://api.commandcode.ai/provider/v1";
            #     apiKey = "{file:/run/secrets/commandcode/api-key}";
            #   };
            #   models."glm-5.3-flash".id = "z-ai/glm-5.3-flash";
            # };
            provider.opencode-go = {
              npm = "@ai-sdk/openai";
              name = "opencode-go";
              options = {
                baseURL = "https://opencode.ai/zen/go/v1";
                apiKey = "{file:/run/secrets/opencode/opencode-go-api-key}";
              };
              models."muse-spark-1.3-contributor".id = "muse-spark-1.3-contributor";
            };
          };

        in
        {
          home.packages = [
            pkgs.opencode
          ];

          xdg.autostart.entries = hermesAutostart;

          xdg.configFile = {
            "opencode/AGENTS.md".source = assets.opencodeRules + "/AGENTS.md";
            "opencode/opencode.json".source = opencodeConfig;
            "opencode/skills".source = vendored-skills;
          };

          home.sessionVariables.SUPERPOWERS_DISABLE_TELEMETRY = "1";

          imports = [ inputs.hermes-agent.homeManagerModules.default ];

          programs.hermes-agent.enable = true;
          programs.hermes-agent.desktop.enable = true;

          services.hermes-agent = {
            enable = true;
            package = hermes.minimal;
            environmentFiles = [ osConfig.sops.templates."hermes.env".path ];
            extraDependencyGroups = [ "honcho" ];
            hermesHomeFiles."SOUL.md" = assets.hermesSoul;
            hermesHomeFiles."honcho.json" = (pkgs.formats.json { }).generate "honcho.json" {
              hosts.hermes = {
                enabled = true;
                aiPeer = "hermes";
                peerName = "shochraos";
                workspace = "hermes";
                baseUrl = "http://localhost:8000";
              };
              recallMode = "hybrid";
              sessionStrategy = "per-directory";
            };
            mcpServers.ScraplingServer = {
              command = "${scrapling-runtime}/bin/scrapling-mcp";
            };
            settings = {
              agent.coding_context = "auto";
              agent.reasoning_effort = "high";
              browser.backend = "off";
              model = {
                provider = "opencode-go";
                default = "muse-spark-1.3-contributor";
              };
              # model = {
              #   provider = "commandcode";
              #   default = "zai-org/GLM-5.3";
              # };
              custom_providers = [
                {
                  name = "opencode-go";
                  base_url = "https://opencode.ai/zen/go/v1";
                  key_env = "OPENCODE_GO_API_KEY";
                  api_mode = "anthropic_messages";
                }
              ];
              skills = {
                create_dir = "";
                external_dirs = [
                  "${hermesSkills}"
                  "${shared-skills}"
                ];
              };
              terminal.cwd = ".";
              updates.check = false;
              timezone = "Europe/Berlin";
              delegation = {
                provider = "opencode-go";
                model = "muse-spark-1.3-contributor";
              };
              # delegation = {
              #   provider = "commandcode";
              #   model = "glm-5.3-flash";
              # };
              lsp.install_strategy = "manual";
              memory.provider = "honcho";
              curator.consolidate = true;
              compression = {
                enabled = true;
                threshold = 0.8;
                threshold_tokens = null;
                target_ratio = 0.2;
                tail_mode = "lean";
                protect_last_n = 20;
                min_tail_user_messages = 1;
                max_attempts = 3;
              };
            };
          };
        };
    };
}
