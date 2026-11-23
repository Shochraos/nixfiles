# Weekly flake updates

The weekly job updates `flake.lock` once, then checks the flake and builds the NixOS toplevels for Azazel, Solas, Seere and Sitri. It does not activate them. Pull requests still use the lightweight `check` workflow on GitHub-hosted runners.

Astaroth triggers the workflow via `workflow_dispatch` every Monday at 05:00 Europe/Berlin instead of using GitHub Actions' `schedule` trigger, which can lag by hours or drop queued runs. No repository variable is required. To pause updates, disable **weekly-flake-update** in the repository's Actions tab; the local dispatcher checks the workflow state first and exits cleanly when it is not active.

## Setup before the first run

- All workflow jobs run on GitHub-hosted `ubuntu-latest` runners; no self-hosted GitHub Actions build or notification runner is required. `Validate candidate` frees unused preinstalled SDKs before installing Nix and building the four host toplevels.
- Allow the trusted publisher job to fast-forward `main` with its job token; do not relax branch protection for it.
- Weekly dispatch and repair triggering run locally on Astaroth instead of via GitHub `schedule`, a webhook or a notification runner. No public webhook endpoint, Proton or UniFi port forward, extra Docker port, `hermes-notifier` runner, or GitHub `nix-update-notify` environment is required. Existing GitHub environment or secret settings from the retired notifier are not removed automatically; delete them manually in GitHub settings if no longer wanted.
- Give the `nix-update-repair` Hermes profile a separate identity that cannot update or merge to upstream `main`; for example, publish its repair branch in a bot-owned fork and open a PR upstream. Keep the local poller and the repair bot separate from the publisher's credentials.
- Store a fine-grained GitHub token scoped only to `Shochraos/nixfiles` with **Actions: Read and write** permission (no `Contents` or `Pull requests` access) at `/opt/data/secrets/flake-update-dispatch.token` with mode `600`, owned by `hermes`. Keep this dispatch token separate from both the poller and `nix-update-repair`.
- Optionally store a read-only fine-grained GitHub token (Actions read access on `Shochraos/nixfiles`) at `/opt/data/secrets/flake-repair-poller.token` with mode `600`. Because `Shochraos/nixfiles` is public, unauthenticated polling also works, but a shared VPN exit IP can hit GitHub's 60 requests/hour unauthenticated limit.
- A manual `workflow_dispatch` run on `main` uses the same checks and can publish a passing lock update; it is not a dry run.

## Local dispatch and repair checker on Astaroth

Both single-shot helpers live on Astaroth's persistent Hermes data mount (`/opt/data/scripts/flake-update-dispatch.sh` and `/opt/data/scripts/flake-repair-poller.sh`) and run inside the `hermes` container. Because `hermes` shares `network_mode: "service:hermes-vpn"`, outbound GitHub API requests go through ProtonVPN rather than the Unraid host's default route, and Hermes is invoked locally without any inbound port.

Configure two plain cron jobs in **Unraid User Scripts**:

1. **Weekly flake update dispatch** with custom cron schedule `0 5 * * 1` (Monday 05:00 Europe/Berlin):

```bash
#!/bin/bash
set -euo pipefail
docker exec -u hermes hermes /opt/data/scripts/flake-update-dispatch.sh
```

2. **Weekly flake repair and cache-warm checker** with custom cron schedule `0 9 * * 1` (Monday 09:00 Europe/Berlin):

```bash
#!/bin/bash
set -euo pipefail
docker exec -u hermes hermes /opt/data/scripts/flake-repair-poller.sh
```

Running both cron entries on Astaroth's local `Europe/Berlin` clock gives the cold GitHub-hosted `ubuntu-latest` build a consistent four-hour window across CET and CEST without a polling retry loop.

At 05:00, `flake-update-dispatch.sh` verifies that `weekly-flake-update` is `active`, skips if a non-cancelled `workflow_dispatch` or `schedule` run on `main` already started in the last 12 hours, and otherwise posts `workflow_dispatch` for `main`.

At 09:00, `flake-repair-poller.sh` queries the GitHub Actions API once, finds the latest `workflow_dispatch` (or `schedule`) run on `main` in the last 18 hours, and verifies the repository, workflow path, `main` branch, event, run attempt and head SHA. On a completed `success`, it builds all four host toplevels on `nix-workspace` over SSH to warm the Attic cache. If **Validate candidate** failed at **Check and build all hosts**, it triggers `hermes --profile nix-update-repair chat --oneshot --quiet --format stream-json --continue "Bot Chat" --query-file -` with validated run metadata only. Other outcomes make no model calls.

### State, logs and manual runs

- Dispatcher lock and receipt live at `/opt/data/state/flake-update-dispatch/` (`dispatch.lock` and `last-dispatch.json`). Pass `--dry-run` to verify the token, workflow state and 12-hour deduplication window without dispatching, `--dedupe-hours <N>` to change that window, or `--force` to dispatch despite a recent run.
- Poller attempt state and lock file live outside this repository at `/opt/data/state/flake-repair-poller/` (`poller.lock`, `attempts/<run-id>-<attempt>.json` and `logs/`).
- Each `(run_id, run_attempt)` is launched at most once. A launch that fails before Hermes creates a session (or a failed SSH cache-warm build) is marked `failed` and can be retried; a crash or abnormal exit after a session was accepted (or an interrupted launch) is marked `uncertain` (exit code `4`) so retries do not duplicate work. Check `docker exec -u hermes hermes hermes --profile nix-update-repair sessions list` (or active builds on `nix-workspace` for `cache_warm`), and pass `--reconcile-retry` only after confirming nothing is running.
- To check a specific run on any day, or to re-check a Monday run that was still in progress (exit code `3`) or fell outside the 18-hour lookback window (exit code `2`):

```bash
docker exec -u hermes hermes /opt/data/scripts/flake-repair-poller.sh --run-id <RUN_ID>
```

- Pass `--dry-run` to verify a run and check deduplication state without writing state or launching work, and `--attempt <N>` with `--run-id` to inspect a specific attempt.

## Reading a run

An unchanged lock file needs no build or publication. A changed lock reaches `main` only if the candidate passes every check. If `main` moved or GitHub rejected the push, the workflow does not force-push; inspect the rejection and start a fresh dispatch on the current `main` if appropriate. If you require every change to go through a PR, keep that protection and use a lock-only PR rather than granting the publisher a bypass.

A failed evaluation or build leaves the run logs and candidate available in Actions. The Astaroth checker inspects which step failed before starting **Nix Update Repair**. A checkout, artifact download, runner preflight or publication failure does not trigger repair. If a dependency fetch fails inside the build step, Hermes still receives the trigger and should report a network problem rather than change the flake. An accepted Hermes session means the repair bot started, not that it fixed the build. The repair PR is for human review.
