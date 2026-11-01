import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


def process_start(pid):
    try:
        status = (Path("/proc") / str(pid) / "stat").read_text()
        fields = status.rsplit(")", 1)[1].split()
        if fields[0] == "Z":
            return None
        return fields[19]
    except (OSError, IndexError):
        return None


def replace_file(path, text):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(text)
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("action", choices=["on", "off", "refresh"])
    parser.add_argument("owner", nargs="?", default="manual")
    parser.add_argument("pid", nargs="?", type=int)
    args = parser.parse_args(argv)
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.owner):
        parser.error("owner must contain only letters, digits, underscores or hyphens")
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime:
        parser.error("XDG_RUNTIME_DIR is required")
    directory = Path(runtime) / "nixfiles-hdr"
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (directory / "lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state_file = directory / "owners.json"
        owners = json.loads(state_file.read_text()) if state_file.exists() else {}
        owners = {
            owner: record
            for owner, record in owners.items()
            if record is None or process_start(record["pid"]) == record["start"]
        }
        if args.action == "on":
            record = None
            if args.pid is not None:
                start = process_start(args.pid)
                if start is None:
                    parser.error("owner process is not alive")
                record = {"pid": args.pid, "start": start}
            owners[args.owner] = record
        elif args.action == "off":
            owners.pop(args.owner, None)
        replace_file(state_file, json.dumps(owners, sort_keys=True))
        overlay = directory / "state.lua"
        content = (
            "hl.monitor({ output = " + json.dumps(args.output) + ', cm = "hdredid" })\n'
            if owners else ""
        )
        previous = overlay.read_text() if overlay.exists() else ""
        pending = directory / "reload-pending"
        if previous != content:
            pending.touch()
        if previous != content or not overlay.exists():
            replace_file(overlay, content)
        if pending.exists():
            result = subprocess.run(
                [os.environ.get("HDR_HYPRCTL", "hyprctl"), "reload"],
                capture_output=True,
                text=True,
            )
            if result.returncode:
                parser.exit(result.returncode, result.stderr or "hyprctl reload failed\n")
            pending.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
