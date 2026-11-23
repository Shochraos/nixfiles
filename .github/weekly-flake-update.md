# Weekly flake updates

The weekly job updates `flake.lock` once, then checks the flake and builds the NixOS toplevels for Azazel, Solas, Seere and Sitri. It does not activate them. Pull requests still use the lightweight `check` workflow on GitHub-hosted runners.

Astaroth triggers the workflow via `workflow_dispatch` every Monday at 05:00 Europe/Berlin instead of using GitHub Actions' `schedule` trigger, which can lag by hours or drop queued runs. No repository variable is required. To pause updates, disable **weekly-flake-update** in the repository's Actions tab; the local dispatcher checks the workflow state first and exits cleanly when it is not active.

## Setup before the first run

- All workflow jobs run on GitHub-hosted `ubuntu-latest` runners; no self-hosted GitHub Actions build or notification runner is required. `Validate candidate` frees unused preinstalled SDKs before installing Nix and building the four host toplevels.
- Allow the trusted publisher job to fast-forward `main` with its job token; do not relax branch protection for it.
- Weekly dispatch and repair triggering run locally on Astaroth instead of via GitHub `schedule`, a webhook or a notification runner. No public webhook endpoint, Proton or UniFi port forward, extra Docker port, `hermes-notifier` runner, or GitHub `nix-update-notify` environment is required. Existing GitHub environment or secret settings from the retired notifier are not removed automatically; delete them manually in GitHub settings if no longer wanted.
- Give the `nix-update-repair` Hermes profile a separate identity that cannot update or merge to upstream `main`; for example, publish its repair branch in a bot-owned fork and open a PR upstream. Keep the local poller and the repair bot separate from the publisher's credentials.
- Create a fine-grained GitHub token for `Shochraos/nixfiles` with **Actions: Read and write**. Do not grant Contents or Pull requests access. Store the token outside Hermes, as described below.
- Optionally store a read-only fine-grained GitHub token (Actions read access on `Shochraos/nixfiles`) at `/opt/data/secrets/flake-repair-poller.token` with mode `600`. Because `Shochraos/nixfiles` is public, unauthenticated polling also works, but a shared VPN exit IP can hit GitHub's 60 requests/hour unauthenticated limit.
- A manual `workflow_dispatch` run on `main` uses the same checks and can publish a passing lock update; it is not a dry run.

## Local dispatch and repair checker on Astaroth

The dispatcher runs in a disposable container using the local `hermes` image. It uses the running `hermes` container's network namespace without mounting its data or sharing its process namespace. The existing poller keeps running inside `hermes` without the dispatch token mounted there.

### Set up the 05:00 dispatcher

On Astaroth, copy the reviewed [dispatcher script](scripts/flake-update-dispatch.sh) to `/mnt/user/appdata/flake-update-dispatch/dispatch.sh`. Keep that directory and its `state/` subdirectory root-owned with mode `700`. Save the token in `token` in the same directory, owned by root with mode `600`. Use a private host path outside any share or bind mount accessible to Hermes. Check mount sources with `docker inspect --format '{{range .Mounts}}{{println .Source}}{{end}}' hermes`. Do not run the host job from the shared project checkout.

Add the following as **Weekly flake update dispatch** in **Unraid User Scripts**. Leave its schedule disabled while testing:

```bash
#!/bin/bash
set -euo pipefail
root=/mnt/user/appdata/flake-update-dispatch
image=$(docker inspect --type container --format '{{.Image}}' hermes)
docker run --rm --pull never --network container:hermes --no-healthcheck \
  --read-only --cap-drop ALL --security-opt no-new-privileges \
  --user 0:0 --entrypoint /bin/bash \
  --mount "type=bind,source=$root/dispatch.sh,target=/run/flake-update-dispatch/dispatch.sh,readonly" \
  --mount "type=bind,source=$root/token,target=/run/flake-update-dispatch/token,readonly" \
  --mount "type=bind,source=$root/state,target=/run/flake-update-dispatch/state" \
  "$image" /run/flake-update-dispatch/dispatch.sh
```

Before switching, confirm the token directory is not exposed to `hermes` and test with `--dry-run` appended to the final line. This checks the container, token authentication and workflow reads, not Actions write permission. Then run it once without `--dry-run` outside the Monday schedule window and confirm the matching run appears in GitHub Actions. That test is a live update and can publish a passing `flake.lock`.

Only after the live test creates a run, merge the workflow change to remove GitHub's old schedule, then set the Astaroth User Script to `0 5 * * 1` (Monday 05:00 Europe/Berlin). Make the switch between Monday run windows. Do not enable both schedules for the same Monday: the local dispatch comes before GitHub's old 05:00 UTC slot.

### Keep the 09:00 poller

Keep the existing repair and cache-warm checker in **Unraid User Scripts** at `0 9 * * 1` (Monday 09:00 Europe/Berlin):

```bash
#!/bin/bash
set -euo pipefail
docker exec -u hermes hermes /opt/data/scripts/flake-repair-poller.sh
```

Running both cron entries on Astaroth's local `Europe/Berlin` clock gives the cold GitHub-hosted `ubuntu-latest` build a consistent four-hour window across CET and CEST without a polling retry loop.

At 05:00, the dispatcher checks that `weekly-flake-update` is active. It skips if it already attempted a dispatch in the last 12 hours or GitHub shows a recent `workflow_dispatch` or `schedule` run on `main` that was not cancelled or skipped.

At 09:00, `flake-repair-poller.sh` finds the latest non-cancelled, non-skipped `workflow_dispatch` or `schedule` run on `main` in the last 18 hours. It verifies the repository, workflow path, branch, event, run attempt and head SHA. On success, it builds all four host toplevels on `nix-workspace` to warm the Attic cache. If **Validate candidate** failed at **Check and build all hosts**, it starts **Nix Update Repair** with verified run metadata. Other outcomes make no model calls.

### State, logs and manual runs

- The dispatcher writes `state/last-dispatch.json` before asking GitHub to start a run. If GitHub's response is lost, it won't retry within 12 hours. Check GitHub Actions before starting another run. `--dry-run` checks GitHub without changing or consulting the local receipt.
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
