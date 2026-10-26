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
    { host, ... }:
    let
      commandcodeSecret = "commandcode/api-keys/${lib.toLower host.name}";
      exaSecret = "exa/api-key";
      honchoServerOverlay = final: _prev: {
        honchoAi = final.callPackage packageSources.honchoAi { };
        honchoServer = final.callPackage packageSources.honchoServer { };
        rea = final.callPackage packageSources.rea { };
        reaPython = final.callPackage packageSources.reaPython { };
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

          sops.secrets.${commandcodeSecret} = {
            owner = user.name;
            path = "/run/secrets/commandcode/api-key";
          };
          sops.secrets.${exaSecret} = {
            owner = user.name;
          };
          sops.templates."hermes.env" = {
            owner = user.name;
            content = ''
              COMMANDCODE_API_KEY=${config.sops.placeholder.${commandcodeSecret}}
              EXA_API_KEY=${config.sops.placeholder.${exaSecret}}
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

          services.ollama = {
            enable = true;
            package = pkgs.ollama-cpu;
            loadModels = [ "bge-m3" ];
          };

          systemd.services.honcho-embedding-dims = {
            description = "Align Honcho pgvector columns with the local embedding model";
            after = [
              "postgresql.service"
              "honcho-migrate.service"
            ];
            requires = [ "honcho-migrate.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "honcho";
            };
            path = [ config.services.postgresql.package ];
            script = ''
              psql -d honcho -v ON_ERROR_STOP=1 <<'SQL'
              DO $$
              DECLARE current_type text;
              BEGIN
                SELECT format_type(atttypid, atttypmod) INTO current_type
                  FROM pg_attribute
                 WHERE attrelid = 'message_embeddings'::regclass AND attname = 'embedding' AND attnum > 0;
                IF current_type IS DISTINCT FROM 'vector(1024)' THEN
                  ALTER TABLE message_embeddings ALTER COLUMN embedding TYPE vector(1024);
                END IF;

                SELECT format_type(atttypid, atttypmod) INTO current_type
                  FROM pg_attribute
                 WHERE attrelid = 'documents'::regclass AND attname = 'embedding' AND attnum > 0;
                IF current_type IS DISTINCT FROM 'vector(1024)' THEN
                  ALTER TABLE documents ALTER COLUMN embedding TYPE vector(1024);
                END IF;
              END $$;
              SQL
            '';
          };

          systemd.services.honcho-api = {
            description = "Honcho local memory server";
            after = [
              "honcho-embedding-dims.service"
              "honcho-migrate.service"
              "ollama.service"
            ];
            requires = [
              "honcho-embedding-dims.service"
              "honcho-migrate.service"
            ];
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
              LLM_OPENAI_API_KEY=${config.sops.placeholder.${commandcodeSecret}}
              DERIVER_MODEL_CONFIG__TRANSPORT=openai
              DERIVER_MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DERIVER_MODEL_CONFIG__THINKING_EFFORT=high
              DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              DIALECTIC_LEVELS__minimal__MODEL_CONFIG__TRANSPORT=openai
              DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DIALECTIC_LEVELS__minimal__MODEL_CONFIG__THINKING_EFFORT=high
              DIALECTIC_LEVELS__minimal__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              DIALECTIC_LEVELS__low__MODEL_CONFIG__TRANSPORT=openai
              DIALECTIC_LEVELS__low__MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DIALECTIC_LEVELS__low__MODEL_CONFIG__THINKING_EFFORT=high
              DIALECTIC_LEVELS__low__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              DIALECTIC_LEVELS__medium__MODEL_CONFIG__TRANSPORT=openai
              DIALECTIC_LEVELS__medium__MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DIALECTIC_LEVELS__medium__MODEL_CONFIG__THINKING_EFFORT=high
              DIALECTIC_LEVELS__medium__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              DIALECTIC_LEVELS__high__MODEL_CONFIG__TRANSPORT=openai
              DIALECTIC_LEVELS__high__MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DIALECTIC_LEVELS__high__MODEL_CONFIG__THINKING_EFFORT=high
              DIALECTIC_LEVELS__high__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              DIALECTIC_LEVELS__max__MODEL_CONFIG__TRANSPORT=openai
              DIALECTIC_LEVELS__max__MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DIALECTIC_LEVELS__max__MODEL_CONFIG__THINKING_EFFORT=high
              DIALECTIC_LEVELS__max__MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              SUMMARY_MODEL_CONFIG__TRANSPORT=openai
              SUMMARY_MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              SUMMARY_MODEL_CONFIG__THINKING_EFFORT=low
              SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              SUMMARY_MAX_TOKENS_SHORT=2000
              SUMMARY_MAX_TOKENS_LONG=6000
              DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT=openai
              DREAM_DEDUCTION_MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DREAM_DEDUCTION_MODEL_CONFIG__THINKING_EFFORT=high
              DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT=openai
              DREAM_INDUCTION_MODEL_CONFIG__MODEL=deepseek/deepseek-v4.1-flash
              DREAM_INDUCTION_MODEL_CONFIG__THINKING_EFFORT=high
              DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL=https://api.commandcode.ai/provider/v1
              EMBEDDING_MODEL_CONFIG__TRANSPORT=openai
              EMBEDDING_MODEL_CONFIG__MODEL=bge-m3
              EMBEDDING_MODEL_CONFIG__DIMENSIONS_MODE=never
              EMBEDDING_MODEL_CONFIG__ENCODING_FORMAT_MODE=float
              EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL=http://127.0.0.1:11434/v1
              EMBEDDING_MODEL_CONFIG__OVERRIDES__API_KEY=ollama
              EMBEDDING_VECTOR_DIMENSIONS=1024
            '';
          };
        };

      provides.to-users.homeManager =
        {
          lib,
          osConfig,
          pkgs,
          ...
        }:
        let
          vendored-skills =
            inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.vendored-skills;

          shared-skills = inputs.agent-skills-nix.packages.${pkgs.stdenv.hostPlatform.system}.shared-skills;

          hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};

          hermesDesktopApplications = hermes.desktop + "/share/applications";

          hermesDesktopEntries = map (name: hermesDesktopApplications + ("/" + name)) (
            builtins.attrNames (
              lib.filterAttrs (name: _: lib.hasSuffix ".desktop" name) (
                builtins.readDir hermesDesktopApplications
              )
            )
          );

          hermesAutostart = lib.optionals (builtins.elem "hermes" osConfig.host.autostart) hermesDesktopEntries;

          honchoPluginSrc = pkgs.fetchFromGitHub {
            owner = "plastic-labs";
            repo = "honcho";
            rev = "e2d2aba182862deeb846e5cd4a30a41bce0ed82a";
            hash = "sha256-EZWqItroZopzw1c0nSyujPWpsN5OAUG3TpQmTdYAAsY=";
          };

          honchoPlugin = pkgs.runCommand "hermes-honcho-plugin" { } ''
            mkdir -p $out
            cp -r ${honchoPluginSrc}/hermes-plugin-honcho/. $out/
            ${pkgs.gnused}/bin/sed -i \
              -e 's@^from __future__ import annotations$@&\n\nimport sys as _honcho_sys\n_honcho_sys.path.append("${pkgs.honchoAi}/lib/python3.14/site-packages")@' \
              $out/__init__.py
            grep -q '_honcho_sys.path.append' $out/__init__.py || {
              echo "honcho-ai sys.path injection did not apply; __init__.py anchor changed" >&2
              exit 1
            }
          '';

          hermesSkills = inputs.agent-skills-nix.lib.${pkgs.stdenv.hostPlatform.system}.mkSkillset [
            "vendored-avoid-ai-writing"
            "shared-cloudflare-bypass"
            "hermes-architecture-diagram"
            "hermes-ascii-video"
            "hermes-baoyu-infographic"
            "hermes-claude-design"
            "hermes-design-md"
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
            model = "commandcode/deepseek-v4.1-flash";
            autoupdate = false;
            provider.commandcode = {
              npm = "@ai-sdk/openai-compatible";
              name = "CommandCode";
              options = {
                baseURL = "https://api.commandcode.ai/provider/v1";
                apiKey = "{file:/run/secrets/commandcode/api-key}";
              };
              models."deepseek-v4.1-flash" = {
                id = "deepseek/deepseek-v4.1-flash";
                options.reasoningEffort = "xhigh";
              };
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

          imports = [ inputs.hermes-agent.homeManagerModules.default ];

          programs.hermes-agent.enable = true;
          programs.hermes-agent.desktop.enable = true;

          services.hermes-agent = {
            enable = true;
            package = hermes.minimal;
            environmentFiles = [ osConfig.sops.templates."hermes.env".path ];
            hermesHomeFiles."SOUL.md" = assets.hermesSoul;
            hermesHomeFiles."honcho.json" = (pkgs.formats.json { }).generate "honcho.json" {
              hosts.hermes = {
                enabled = true;
                aiPeer = "hermes";
                peerName = "shochraos";
                pinUserPeer = true;
                workspace = "hermes";
                baseUrl = "http://localhost:8000";
              };
              recallMode = "hybrid";
              sessionStrategy = "per-directory";
            };
            mcpServers.ScraplingServer = {
              command = "${scrapling-runtime}/bin/scrapling-mcp";
            };
            mcpServers.rea = {
              command = "${pkgs.rea}/bin/rea";
              args = [ "mcp" ];
              timeout = 1800;
              env = {
                GHIDRA_INSTALL_DIR = "${pkgs.ghidra}/lib/ghidra";
                REA_BINWALK_COMMAND = "${pkgs.binwalk}/bin/binwalk";
                REA_CAPINFOS_COMMAND = "${pkgs.tshark}/bin/capinfos";
                REA_FIRMWARE_PRLIMIT_COMMAND = "${pkgs.util-linux}/bin/prlimit";
                REA_GHIDRA_STARTUP_TIMEOUT_MS = "1800000";
                REA_PWNTOOLS_PYTHON = "${pkgs.reaPython}/bin/python3";
                REA_TSHARK_COMMAND = "${pkgs.tshark}/bin/tshark";
                REA_TSHARK_PRLIMIT_COMMAND = "${pkgs.util-linux}/bin/prlimit";
              };
            };
            settings = {
              agent.coding_context = "auto";
              agent.reasoning_effort = "xhigh";
              browser.backend = "off";
              checkpoints.enabled = true;
              model = {
                provider = "commandcode";
                default = "deepseek/deepseek-v4.1-flash";
              };
              custom_providers = [
                {
                  name = "commandcode";
                  base_url = "https://api.commandcode.ai/provider/v1";
                  key_env = "COMMANDCODE_API_KEY";
                }
              ];
              skills = {
                create_dir = "";
                external_dirs = [
                  "${hermesSkills}"
                  "${shared-skills}"
                  "${pkgs.rea.skills}/share/hermes/skills"
                ];
              };
              terminal.cwd = ".";
              timeouts = {
                tools.sequential_call = 1900;
                tools.concurrent_batch = 1900;
              };
              updates.check = false;
              timezone = "Europe/Berlin";
              web = {
                search_backend = "exa";
                extract_backend = "firecrawl";
              };
              delegation = {
                provider = "commandcode";
                model = "deepseek/deepseek-v4.1-flash";
              };
              auxiliary.vision = {
                provider = "commandcode";
                model = "z-ai/glm-5.3-flash";
                extra_body.reasoning_effort = "low";
              };
              lsp.install_strategy = "manual";
              memory.provider = "honcho";
              curator.consolidate = true;
              compression = {
                enabled = true;
                threshold = 0.5;
                threshold_tokens = null;
                target_ratio = 0.2;
                tail_mode = "lean";
                protect_last_n = 20;
                min_tail_user_messages = 1;
                max_attempts = 3;
              };
            };
          };

          home.activation.hermesHonchoProvider = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p "$HOME/.hermes/plugins"
            run ln -sfn ${honchoPlugin} "$HOME/.hermes/plugins/honcho"
          '';
        };
    };
}
