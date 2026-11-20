# Weekly flake updates

The weekly job updates `flake.lock` once, then checks the flake and builds the NixOS toplevels for Azazel, Solas, Seere and Sitri. It does not activate them. Pull requests still use the lightweight `check` workflow on GitHub-hosted runners.

The schedule is active once the workflow is merged into `main`. The automatic run starts every Monday at 05:00 UTC. No repository variable is required. To pause updates, disable **Weekly flake update** in the repository's Actions tab.

## Setup before the first run

- All workflow jobs run on GitHub-hosted `ubuntu-latest` runners; no self-hosted GitHub Actions build or notification runner is required. `Validate candidate` frees unused preinstalled SDKs before installing Nix and building the four host toplevels.
- Allow the trusted publisher job to fast-forward `main` with its job token; do not relax branch protection for it.
- Repair triggering runs locally on Astaroth instead of via a GitHub webhook or notification runner. No public webhook endpoint, Proton or UniFi port forward, extra Docker port, `hermes-notifier` runner, or GitHub `nix-update-notify` environment is required. Existing GitHub environment or secret settings from the retired notifier are not removed automatically; delete them manually in GitHub settings if no longer wanted.
- Give the `nix-update-repair` Hermes profile a separate identity that cannot update or merge to upstream `main`; for example, publish its repair branch in a bot-owned fork and open a PR upstream. Keep the local poller and the repair bot separate from the publisher's credentials.
- Optionally store a read-only fine-grained GitHub token (Actions read access on `Shochraos/nixfiles`) at `/opt/data/secrets/flake-repair-poller.token` with mode `600`. Because `Shochraos/nixfiles` is public, unauthenticated polling also works, but a shared VPN exit IP can hit GitHub's 60 requests/hour unauthenticated limit.
- A manual `workflow_dispatch` run on `main` uses the same checks and can publish a passing lock update; it is not a dry run.

## Local repair checker on Astaroth

The single-shot checker lives on Astaroth's persistent Hermes data mount at `/opt/data/scripts/flake-repair-poller.sh` and runs inside the `hermes` container. Because `hermes` shares `network_mode: "service:hermes-vpn"`, outbound GitHub API requests go through ProtonVPN rather than the Unraid host's default route, and Hermes is invoked locally without any inbound port.

Schedule it as a plain cron job in **Unraid User Scripts**:

```bash
#!/bin/bash
set -euo pipefail
docker exec -u hermes hermes /opt/data/scripts/flake-repair-poller.sh
```

Set the Unraid User Scripts custom cron schedule to **`0 9 * * 1`** (Monday 09:00 Europe/Berlin: 07:00 UTC in CEST and 08:00 UTC in CET). That gives the cold GitHub-hosted `ubuntu-latest` build two to three hours after the Monday 05:00 UTC start without running a polling retry loop.

The checker queries the GitHub Actions API once, verifies the repository, workflow path, `main` branch, event, run attempt and head SHA, and triggers `hermes --profile nix-update-repair chat --oneshot --quiet --format stream-json --query-file -` only if the completed **Validate candidate** job failed at the **Check and build all hosts** step. It passes only validated run metadata and makes no model calls when no eligible failure exists.

### State, logs and manual runs

- Attempt state and lock file live outside this repository at `/opt/data/state/flake-repair-poller/` (`poller.lock`, `attempts/<run-id>-<attempt>.json` and `logs/`).
- Each `(run_id, run_attempt)` is launched at most once. A launch that fails before Hermes creates a session is marked `failed` and can be retried; a crash or abnormal exit after a session was accepted (or an interrupted launch) is marked `uncertain` (exit code `4`) so retries do not duplicate repairs. Check `docker exec -u hermes hermes hermes --profile nix-update-repair sessions list`, and pass `--reconcile-retry` only if you confirmed no repair session started.
- To check a manual `workflow_dispatch` run on any day, or to re-check a Monday run that was still in progress (exit code `3`) or missed the 18-hour lookback window (exit code `2`):

```bash
docker exec -u hermes hermes /opt/data/scripts/flake-repair-poller.sh --run-id <RUN_ID>
```

- Pass `--dry-run` to verify a run and check deduplication state without writing state or launching Hermes, and `--attempt <N>` with `--run-id` to inspect a specific attempt.

## Reading a run

An unchanged lock file needs no build or publication. A changed lock reaches `main` only if the candidate passes every check. If `main` moved or GitHub rejected the push, the workflow does not force-push; inspect the rejection and start a fresh dispatch on the current `main` if appropriate. If you require every change to go through a PR, keep that protection and use a lock-only PR rather than granting the publisher a bypass.

A failed evaluation or build leaves the run logs and candidate available in Actions. The Astaroth checker inspects which step failed before starting **Nix Update Repair**. A checkout, artifact download, runner preflight or publication failure does not trigger repair. If a dependency fetch fails inside the build step, Hermes still receives the trigger and should report a network problem rather than change the flake. An accepted Hermes session means the repair bot started, not that it fixed the build. The repair PR is for human review.
