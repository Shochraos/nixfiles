#!/usr/bin/env bash
set -euo pipefail
umask 077

fail() {
  printf 'flake-update-dispatch: %s\n' "$1" >&2
  exit "${2:-1}"
}

case $#:${1-} in
0: | 1:--dry-run) ;;
*) fail 'Usage: flake-update-dispatch.sh [--dry-run]' ;;
esac

state_dir=/run/flake-update-dispatch/state
if [[ -v FLAKE_UPDATE_GITHUB_API_BASE ]]; then
  if [[ ! $FLAKE_UPDATE_GITHUB_API_BASE =~ ^http://127\.0\.0\.1:[1-9][0-9]{0,4}$ ||
    -z ${FLAKE_UPDATE_STATE_DIR:-} || -z ${FLAKE_UPDATE_TOKEN_FILE:-} ]]; then
    fail 'Fixture overrides require a loopback API, token file and state directory.'
  fi
  state_dir=$FLAKE_UPDATE_STATE_DIR
fi

if (($# == 0)); then
  { exec 9<"$state_dir"; } 2>/dev/null || fail 'Cannot open the private state directory.'
  flock -n -E 5 9 || {
    if [[ $? == 5 ]]; then fail 'Another dispatcher holds the state lock.' 5; fi
    fail 'Cannot lock the private state directory.'
  }
fi

exec node - "$state_dir" "$@" <<'NODE'
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const [stateDir, dryRun] = process.argv.slice(2);
const fixtureApi = process.env.FLAKE_UPDATE_GITHUB_API_BASE;
const dry = dryRun === '--dry-run';
const tokenFile = fixtureApi ? process.env.FLAKE_UPDATE_TOKEN_FILE : '/run/flake-update-dispatch/token';
const repo = 'Shochraos/nixfiles';
const branch = 'main';
const workflowPath = '.github/workflows/weekly-flake-update.yml';
const workflow = `/workflows/${path.basename(workflowPath)}`;
const api = `${fixtureApi ?? 'https://api.github.com'}/repos/${repo}/actions`;
const receiptFile = path.join(stateDir, 'last-dispatch.json');
const windowMs = 12 * 60 * 60 * 1000;
const events = ['schedule', 'workflow_dispatch'];
const reconcile = 'Reconcile in GitHub Actions; no automatic retry within 12h.';
const validId = (value) => Number.isSafeInteger(value) && value > 0;
const log = (message) => console.log(`flake-update-dispatch: ${message}`);

function readToken() {
  try {
    const fd = fs.openSync(tokenFile, fs.constants.O_RDONLY | fs.constants.O_NOFOLLOW | fs.constants.O_NONBLOCK);
    try {
      const stat = fs.fstatSync(fd);
      if (!stat.isFile() || stat.uid !== process.getuid() || (stat.mode & 0o077) || stat.size > 1024) throw new Error();
      const token = fs.readFileSync(fd, 'utf8').replace(/\r?\n$/, '');
      if (!token || /[^A-Za-z0-9_]/.test(token) || (fixtureApi && !token.startsWith('fixture_'))) throw new Error();
      return token;
    } finally {
      fs.closeSync(fd);
    }
  } catch {
    throw new Error('Cannot read a valid private token file. Provision an owner-only file (chmod 600) with Actions write for Shochraos/nixfiles.');
  }
}

function readReceipt() {
  const state = fs.lstatSync(stateDir, { throwIfNoEntry: false });
  const lock = fs.fstatSync(9);
  if (!state?.isDirectory() || state.uid !== process.getuid() || (state.mode & 0o777) !== 0o700 ||
      state.dev !== lock.dev || state.ino !== lock.ino) {
    throw new Error('State must be a private owner-managed directory (chmod 700).');
  }
  try {
    const receipt = JSON.parse(fs.readFileSync(receiptFile, 'utf8'));
    if (!validId(receipt?.attempted_at_ms) || !['pending', 'accepted'].includes(receipt.status) ||
        (receipt.workflow_run_id !== null && !validId(receipt.workflow_run_id))) throw new Error();
    return receipt;
  } catch (error) {
    if (error.code === 'ENOENT') return null;
    throw new Error('Cannot read a valid dispatch receipt. Reconcile in GitHub Actions before clearing it.');
  }
}

function saveReceipt(receipt) {
  const temporary = `${receiptFile}.${randomUUID()}`;
  try {
    const fd = fs.openSync(temporary, 'wx', 0o600);
    try {
      fs.writeFileSync(fd, JSON.stringify(receipt) + '\n');
      fs.fsyncSync(fd);
    } finally {
      fs.closeSync(fd);
    }
    fs.renameSync(temporary, receiptFile);
    fs.fsyncSync(9);
  } finally {
    fs.rmSync(temporary, { force: true });
  }
}

function httpError(status) {
  return `HTTP ${status}${[401, 403].includes(status) ? ': check the token grants Actions write' : ''}`;
}

async function request(token, endpoint, payload) {
  const headers = {
    Accept: 'application/vnd.github+json',
    Authorization: `Bearer ${token}`,
    'User-Agent': 'flake-update-dispatch',
    'X-GitHub-Api-Version': '2022-11-28',
  };
  if (payload) headers['Content-Type'] = 'application/json';
  try {
    return await fetch(api + endpoint, {
      method: payload ? 'POST' : 'GET', headers, body: payload && JSON.stringify(payload),
      redirect: 'manual', signal: AbortSignal.timeout(15000),
    });
  } catch {
    throw new Error('GitHub API transport failed or timed out');
  }
}

async function get(token, endpoint) {
  const response = await request(token, endpoint);
  if (response.status !== 200) throw new Error(`GitHub API returned ${httpError(response.status)}.`);
  try {
    return await response.json();
  } catch {
    throw new Error('GitHub API returned unreadable JSON.');
  }
}

function isTargetRun(run, workflowId) {
  return validId(run?.id) && run.workflow_id === workflowId && run.name === 'weekly-flake-update' &&
    [workflowPath, `${workflowPath}@refs/heads/${branch}`].includes(run.path) && run.head_branch === branch &&
    validId(run.repository?.id) && run.repository.full_name === repo &&
    run.head_repository?.id === run.repository.id && run.head_repository.full_name === repo;
}

async function recentRun(token, workflowId) {
  const now = Date.now();
  const since = now - windowMs;
  const query = new URLSearchParams({ branch, created: `>=${new Date(since).toISOString()}`, per_page: '100' });
  for (let page = 1; page <= 10; page++) {
    query.set('page', String(page));
    const result = await get(token, `${workflow}/runs?${query}`);
    if (!Array.isArray(result?.workflow_runs)) throw new Error('Invalid workflow runs list from GitHub.');
    const recent = result.workflow_runs.find((run) => {
      if (!isTargetRun(run, workflowId) || !events.includes(run.event) ||
          (run.status === 'completed' && ['cancelled', 'skipped'].includes(run.conclusion))) return false;
      const created = Date.parse(run.created_at);
      return created >= since && created <= now + 5 * 60 * 1000;
    });
    if (recent) return recent;
    if (result.workflow_runs.length < 100) return null;
  }
  throw new Error('GitHub workflow runs list reached its search limit; not dispatching.');
}

async function main() {
  if (!dry) {
    const receipt = readReceipt();
    if (receipt && Date.now() - receipt.attempted_at_ms < windowMs) {
      if (receipt.status === 'pending') throw new Error(`Skipping dispatch: pending receipt. ${reconcile}`);
      return log('Skipping dispatch: accepted receipt within 12h.');
    }
  }
  const token = readToken();
  const metadata = await get(token, workflow);
  if (!validId(metadata?.id) || metadata.path !== workflowPath) throw new Error('Unexpected GitHub workflow metadata.');
  if (metadata.state !== 'active') return log('Skipping dispatch: workflow is not active.');
  const recent = await recentRun(token, metadata.id);
  if (recent) return log(`Skipping dispatch: recent ${recent.event} run ${recent.id} on ${branch}.`);
  if (dry) return log(`Dry run: API checks passed; would dispatch on ${branch}. Local receipts were not checked.`);

  const receipt = { attempted_at_ms: Date.now(), status: 'pending', workflow_run_id: null };
  try {
    saveReceipt(receipt);
  } catch {
    throw new Error('Cannot persist the pending dispatch receipt; not dispatching.');
  }
  let response;
  try {
    response = await request(token, `${workflow}/dispatches`, { ref: branch, return_run_details: true });
    if (response.status !== 200 && response.status !== 204) throw new Error(httpError(response.status));
  } catch (error) {
    throw new Error(`Dispatch outcome uncertain (${error.message}). ${reconcile}`);
  }
  const details = response.status === 200 ? await response.json().catch(() => null) : null;
  const runId = validId(details?.workflow_run_id) ? details.workflow_run_id : null;
  try {
    saveReceipt({ ...receipt, status: 'accepted', workflow_run_id: runId });
  } catch {
    throw new Error(`GitHub accepted dispatch, but its receipt could not be updated. ${reconcile}`);
  }
  if (runId !== null) {
    const run = await get(token, `/runs/${runId}`).catch(() => null);
    if (run?.id === runId && isTargetRun(run, metadata.id) && run.event === 'workflow_dispatch') {
      return log(`Dispatch verified on ${branch}: run ${runId}.`);
    }
  }
  log(`GitHub accepted dispatch (HTTP ${response.status}${runId === null ? '' : `, run ${runId}`}), but the run was not verified. ${reconcile}`);
}

main().catch((error) => {
  console.error(`flake-update-dispatch: ${error.message}`);
  process.exitCode = 1;
});
NODE
