#!/usr/bin/env python3
"""Render the den aspect graph as a narrow, vertical SVG.

Read from source, not from evaluation: `den.aspects.<name>` definitions anywhere
under modules/ — both `X.includes = [...]` and `X = { includes = [...]; }` forms,
plus `provides.<k> = den.aspects.<y>` for functor aspects — and `den.hosts.*` in
modules/flake/den.nix.

    python3 assets/scripts/draw-aspects.py [width]

Edges point parent -> included, top down: a host includes graphical, graphical
includes base. Nothing is inferred; a missing arrow is a missing edge in source.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEN_NIX = ROOT / "modules" / "flake" / "den.nix"

W = int(sys.argv[1]) if len(sys.argv) > 1 else 820
PAD = 36
BG = "#04060a"
PANEL = "#0b141c"
CARD = "#151c24"
BORDER = "#517269"
INK = "#e6f2ec"
DIM = "#93b3ab"
GREEN = "#3dffb0"
CYAN = "#34e0ff"
PURPLE = "#b673ff"
PINK = "#ff5d8a"
FONT = "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def match_list(text, start):
    """Index of the `]` closing the `[` at `start`, string aware."""
    depth, i = 0, start
    while i < len(text):
        c = text[i]
        if c == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("unbalanced []")


def match_brace(text, start):
    """Index of the `}` closing the `{` at `start`, string aware."""
    depth, i = 0, start
    while i < len(text):
        c = text[i]
        if c == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("unbalanced {}")


def depth_at(text, pos):
    depth, i = 0, 0
    while i < pos:
        c = text[i]
        if c == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c in "{[":
            depth += 1
        elif c in "}]":
            depth -= 1
        i += 1
    return depth


def split_items(body):
    """Split an include list on top-level whitespace (Nix lists are space-separated)."""
    items, depth, cur = [], 0, ""
    i = 0
    while i < len(body):
        c = body[i]
        if c == '"':
            j = i + 1
            while j < len(body) and body[j] != '"':
                j += 2 if body[j] == "\\" else 1
            cur += body[i : j + 1]
            i = j + 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        if depth == 0 and c.isspace():
            if cur.strip():
                items.append(cur.strip())
            cur = ""
        else:
            cur += c
        i += 1
    if cur.strip():
        items.append(cur.strip())
    return items


def label_for(item):
    """One include entry -> (label, kind, target aspect name or None)."""
    if not item.startswith("("):
        return item, "aspect", item
    if "batteries.unfree" in item:
        names = re.findall(r'"([^"]+)"', item)
        return "unfree(" + ", ".join(names) + ")", "unfree", None
    call = re.match(r"\(\s*([\w-]+)\s*\{(.*)\}", item, re.S)
    if call:
        name, args = call.group(1), " ".join(call.group(2).split())
        args = re.sub(r"\s*=\s*", "=", args).rstrip(";")
        return f"{name} {{{args}}}", "call", name
    return " ".join(item.split())[:60], "call", None


def nix_files():
    return sorted(
        p
        for p in ROOT.joinpath("modules").rglob("*.nix")
        if not any(part in {".git", ".direnv", "result"} for part in p.parts)
    )


def parse_aspects():
    """aspect -> {includes: [(label, kind, target)], provides: {k: target}, file}"""
    found = {}

    def entry(name, path):
        return found.setdefault(
            name, {"includes": [], "provides": {}, "file": str(path.relative_to(ROOT))}
        )

    for path in nix_files():
        text = path.read_text()
        for m in re.finditer(r"den\.aspects\.([\w-]+)(\.includes)?\s*=", text):
            name = m.group(1)
            ent = entry(name, path)
            if m.group(2):
                lb = text.index("[", m.end())
                ent["includes"] += [label_for(i) for i in split_items(text[lb + 1 : match_list(text, lb)])]
                continue
            if not text[m.end() :].lstrip().startswith("{"):
                continue
            brace = text.index("{", m.end())
            block = text[brace : match_brace(text, brace)]
            for inc in re.finditer(r"includes\s*=\s*\[", block):
                if depth_at(block, inc.start()) != 1:
                    continue
                lb = block.index("[", inc.end() - 1)
                ent["includes"] += [
                    label_for(i) for i in split_items(block[lb + 1 : match_list(block, lb)])
                ]
            for prov in re.finditer(r"provides\.([\w-]+)\s*=\s*den\.aspects\.([\w-]+)", block):
                if depth_at(block, prov.start()) == 1:
                    ent["provides"][prov.group(1)] = prov.group(2)
    return found


def definition_files():
    """aspect -> defining file, preferring files outside flake/den.nix."""
    out = subprocess.run(
        ["rg", "--sort", "path", "--no-heading", "-n", r"den\.aspects\.[\w-]+", "modules", "--type", "nix"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    ).stdout
    found = {}
    for line in out.splitlines():
        path, _, rest = line.partition(":")
        m = re.search(r"den\.aspects\.([\w-]+)", rest)
        if m:
            found.setdefault(m.group(1), [])
            if path not in found[m.group(1)]:
                found[m.group(1)].append(path)
    return {
        name: next((f for f in files if not f.endswith("flake/den.nix")), files[0])
        for name, files in found.items()
    }


def hosts():
    text = DEN_NIX.read_text()
    return [
        (h, a)
        for h, a in re.findall(
            r"den\.hosts\.x86_64-linux\.([\w-]+)\s*=\s*\{.*?aspect\s*=\s*den\.aspects\.([\w-]+)",
            text,
            re.S,
        )
    ]


def nix_file_count():
    return len(
        [
            p
            for p in ROOT.rglob("*.nix")
            if not any(part in {".git", ".direnv", "result"} for part in p.parts)
        ]
    )


def rect(x, y, w, h, rx, fill, stroke=None, width=1.5, opacity=None):
    s = f'<rect x="{x}" y="{y}" rx="{rx}" width="{w}" height="{h}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{width}"'
    if opacity:
        s += f' opacity="{opacity}"'
    return s + "/>"


def text(x, y, s, size, fill, weight=400, anchor="start", opacity=None, spacing=None):
    t = f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}"'
    if weight != 400:
        t += f' font-weight="{weight}"'
    if anchor != "start":
        t += f' text-anchor="{anchor}"'
    if opacity:
        t += f' opacity="{opacity}"'
    if spacing:
        t += f' letter-spacing="{spacing}"'
    return t + f">{esc(s)}</text>"


def char_w(size):
    return size * 0.6


def text_w(s, size):
    return len(s) * char_w(size)


def fit(s, size, width):
    """Trim to the widest prefix that fits, with an ellipsis."""
    if text_w(s, size) <= width:
        return s
    out = s
    while out and text_w(out + "…", size) > width:
        out = out[:-1]
    return (out.rstrip() + "…") if out else ""


def arrow(x1, y1, x2, y2, color, marker):
    return (
        f'<path d="M {x1} {y1} L {x2} {y2}" stroke="{color}" stroke-width="2" '
        f'stroke-linecap="round" fill="none" opacity="0.85" marker-end="url(#{marker})"/>'
    )


def node(x, y, w, title, sub, accent, h=56):
    return [
        rect(x, y, w, h, 10, CARD, BORDER),
        rect(x + 4, y + 9, 4, h - 18, 3, accent),
        text(x + 20, y + 24, title, 13, INK, 700),
        text(x + 20, y + 42, sub, 10, accent, 400, opacity=0.75),
    ]


def list_card(x, y, w, title, subtitle, rows, accent, hues):
    """rows: (label, kind, file). One aspect per line."""
    head = 58
    row_h = 23
    h = head + len(rows) * row_h + 10
    elems = [
        rect(x, y, w, h, 12, CARD, BORDER),
        rect(x, y, 4, h, 2, accent),
        text(x + 18, y + 24, title, 14, INK, 700),
        text(x + 18, y + 41, fit(subtitle, 10, w - 36), 10, DIM, 400),
        f'<line x1="{x + 16}" y1="{y + 50}" x2="{x + w - 16}" y2="{y + 50}" stroke="{BORDER}" stroke-width="1"/>',
    ]
    for i, (label, kind, file) in enumerate(rows):
        ry = y + head + i * row_h + 15
        elems.append(f'<circle cx="{x + 24}" cy="{ry - 4}" r="3" fill="{hues.get(kind, DIM)}"/>')
        elems.append(text(x + 36, ry, label, 11.5, INK))
        if not file:
            continue
        label_end = x + 36 + text_w(label, 11.5) + 14
        shown = file
        while shown and x + w - 18 - text_w(shown, 9.5) < label_end:
            cut = shown.find("/")
            if cut < 0:
                shown = shown[: len(shown) - 2] + "…" if len(shown) > 12 else ""
                break
            shown = shown[cut + 1 :]
        if shown:
            elems.append(text(x + w - 18, ry, shown, 9.5, DIM, 400, "end", 0.75))
    return elems, h


def wrap(s, size, width):
    lines, cur = [], ""
    for word in s.split(" "):
        cand = f"{cur} {word}".strip()
        if text_w(cand, size) > width and cur:
            lines.append(cur)
            cur = word
        else:
            cur = cand
    if cur:
        lines.append(cur)
    return lines or [""]


def included_card(x, y, w, title, subtitle, rows, accent):
    """rows: (name, parents, contents) — `name` with `included by parents` above its contents."""
    head = 58
    line_h = 15
    wrapped = [wrap(contents, 10.5, w - 52) for _, _, contents in rows]
    h = head + sum(15 + len(lines) * line_h + 10 for lines in wrapped) + 2
    elems = [
        rect(x, y, w, h, 12, CARD, BORDER),
        rect(x, y, 4, h, 2, accent),
        text(x + 18, y + 24, title, 14, INK, 700),
        text(x + 18, y + 41, fit(subtitle, 10, w - 36), 10, DIM, 400),
        f'<line x1="{x + 16}" y1="{y + 50}" x2="{x + w - 16}" y2="{y + 50}" stroke="{BORDER}" stroke-width="1"/>',
    ]
    ry = y + head + 14
    for (name, parents, _), lines in zip(rows, wrapped):
        elems.append(text(x + 18, ry, name, 11, PURPLE, 700))
        if parents:
            elems.append(text(x + w - 18, ry, "included by " + parents, 9.5, DIM, 400, "end", 0.85))
        for j, line in enumerate(lines):
            elems.append(text(x + 34, ry + line_h + j * line_h, line, 10.5, INK))
        ry += 15 + len(lines) * line_h + 10
    return elems, h


def verify(path, w, h):
    """Monospace metrics are fixed, so extents can be checked without a renderer."""
    svg = path.read_text()
    boxes, problems = [], []
    for m in re.finditer(r"<text ([^>]*)>([^<]*)</text>", svg):
        attrs, content = m.group(1), m.group(2)
        x = float(re.search(r'(?:^|\s)x="([^"]+)"', attrs).group(1))
        y = float(re.search(r'(?:^|\s)y="([^"]+)"', attrs).group(1))
        size = float(re.search(r'font-size="([^"]+)"', attrs).group(1))
        anchor = re.search(r'text-anchor="(\w+)"', attrs)
        anchor = anchor.group(1) if anchor else "start"
        plain = content.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
        tw = text_w(plain, size)
        x0 = x if anchor == "start" else (x - tw if anchor == "end" else x - tw / 2)
        boxes.append((y, x0, x0 + tw, plain))
        if x0 < 6 or x0 + tw > w - 6:
            problems.append(f"x-overflow {plain!r} {x0:.0f}..{x0 + tw:.0f} (w={w})")
        if y > h - 4:
            problems.append(f"y-overflow {plain!r} at {y:.0f} (h={h})")
    rows = {}
    for b in boxes:
        rows.setdefault(round(b[0]), []).append(b)
    for y, items in rows.items():
        items.sort(key=lambda b: b[1])
        for a, b in zip(items, items[1:]):
            if b[1] < a[2] - 1:
                problems.append(f"overlap y={y}: {a[3]!r} / {b[3]!r}")
    return problems


def build():
    aspects = parse_aspects()
    defs = definition_files()
    host_list = hosts()
    hues = {"aspect": GREEN, "call": PURPLE, "unfree": PINK}

    spine = ["base", "graphical"]
    composite = {
        name: ent["includes"] + [("provides " + k, "aspect", v) for k, v in ent["provides"].items()]
        for name, ent in aspects.items()
        if ent["includes"] or ent["provides"]
    }
    host_aspects = {a for _, a in host_list}
    sub = sorted(n for n in composite if n not in spine and n not in host_aspects)
    edges = sum(len(v) for v in composite.values())

    included_by = {}
    for parent, kids in composite.items():
        for _, _, target in kids:
            if target:
                included_by.setdefault(target, [])
                if parent not in included_by[target]:
                    included_by[target].append(parent)
    for parent, ent in aspects.items():
        for k, v in ent["provides"].items():
            included_by.setdefault(v, [])
            tag = f"{parent}.provides.{k}"
            if tag not in included_by[v]:
                included_by[v].append(tag)

    def decorate(label, target):
        if target in spine:
            return label + "  ↑"
        if target in sub:
            return label + "  ⊃"
        return label

    out, y = [], 0
    badge_w = 104
    badge_x = W - PAD - badge_w
    out += [
        text(PAD, 46, "nixfiles", 32, INK, 700),
        rect(badge_x, 24, badge_w, 22, 6, GREEN, GREEN, 0.5, 0.12),
        text(badge_x + badge_w // 2, 39, "DENDRITIC", 10, GREEN, 600, "middle"),
        text(
            PAD,
            72,
            f"flake-parts + den  ·  {nix_file_count()} .nix files  ·  {len(defs)} aspect names  ·  "
            f"{edges} includes edges  ·  {len(host_list)} hosts",
            11.5,
            DIM,
        ),
    ]
    y = 104

    out.append(text(PAD, y + 8, "ENTRY", 10.5, DIM, 700, spacing="2"))
    chain = [
        ("flake.nix", "mkFlake · import-tree ./modules", GREEN),
        ("modules/**/*.nix", "every file is a flake-parts module — no import list", CYAN),
        ("den", "aspects + hosts · den.default.includes = hostOptions", PURPLE),
    ]
    cy = y + 22
    for i, (title, sub_, accent) in enumerate(chain):
        out += node(PAD, cy, W - 2 * PAD, title, sub_, accent)
        if i < len(chain) - 1:
            out.append(arrow(W // 2, cy + 56, W // 2, cy + 76, GREEN, "arw-green"))
        cy += 78
    y = cy + 4

    card_w = W - 2 * PAD

    out.append(text(PAD, y + 10, "INHERITANCE", 10.5, DIM, 700, spacing="2"))
    out.append(
        text(
            W - PAD,
            y + 10,
            "read down: each card is included by the one below",
            10,
            DIM,
            400,
            "end",
            0.8,
        )
    )
    y += 28

    spine_bottom = y
    for i, name in enumerate(spine):
        ent = aspects[name]
        rows = [(decorate(l, t), k, defs.get(t or l, "")) for l, k, t in ent["includes"]]
        elems, h = list_card(
            PAD, y, card_w, name, f"den.aspects.{name}.includes · {len(rows)} entries", rows, GREEN, hues
        )
        out += elems
        y += h
        spine_bottom = y
        if i < len(spine) - 1:
            child = spine[i + 1]
            out.append(arrow(W // 2, y + 30, W // 2, y + 2, GREEN, "arw-green"))
            out.append(text(W // 2 + 12, y + 22, f"included by {child}", 10, GREEN, 400))
            y += 38

    gap = 20
    col_w = (card_w - gap) // 2
    bus_y = y + 14
    host_top = y + 34
    mids, tallest = [], 0
    for i, (host, aspect) in enumerate(host_list):
        ent = aspects[aspect]
        rows = [(decorate(l, t), k, defs.get(t or l, "")) for l, k, t in ent["includes"]]
        cx = PAD + i * (col_w + gap)
        sub_ = f"den.hosts.x86_64-linux.{host} · {len(rows)} includes"
        elems, h = list_card(cx, host_top, col_w, aspect, sub_, rows, PINK if i == 0 else CYAN, hues)
        out += elems
        mids.append(cx + col_w // 2)
        tallest = max(tallest, h)
    out.append(
        f'<line x1="{mids[0]}" y1="{bus_y}" x2="{mids[-1]}" y2="{bus_y}" stroke="{GREEN}" stroke-width="2" opacity="0.85"/>'
    )
    for mx in mids:
        out.append(arrow(mx, host_top + 2, mx, bus_y + 2, GREEN, "arw-green"))
    out.append(arrow(W // 2, bus_y, W // 2, spine_bottom + 2, GREEN, "arw-green"))
    out.append(
        text(W // 2 + 12, spine_bottom + 6, "included by " + " + ".join(a for _, a in host_list), 10, GREEN, 400)
    )
    y = host_top + tallest + 6

    y += 32
    out.append(text(PAD, y + 8, "SUB-INCLUDES", 10.5, DIM, 700, spacing="2"))
    out.append(text(W - PAD, y + 8, "the ⊃ aspects, expanded", 10, DIM, 400, "end", 0.8))
    y += 24
    rows = []
    for name in sub:
        ent = aspects[name]
        parts = [l for l, _, _ in ent["includes"]]
        parts += [f"provides {k} → {v}" for k, v in ent["provides"].items()]
        rows.append(
            (name, ", ".join(included_by.get(name, [])), " · ".join(parts) if parts else "no further includes")
        )
    elems, h = included_card(
        PAD, y, card_w, "sub-includes", f"{len(rows)} aspects pulled in by the cards above", rows, PURPLE
    )
    out += elems
    y += h + 30

    notes = [
        (GREEN, "arrows point up: the lower card includes the card above it"),
        (GREEN, "base is included by graphical (den.nix:44); base includes graphical nowhere (den.nix:12)"),
        (PURPLE, "call includes take arguments where they are used: (ai { local; stt; })"),
        (PINK, "unfree(...) is a den battery bundle, not an aspect file"),
        (DIM, "↑  that aspect is drawn above, in the spine"),
        (DIM, "⊃  that aspect's own includes are listed once, under SUB-INCLUDES"),
        (DIM, "not drawn: provides.to-users.homeManager — config forwarding, not composition"),
    ]
    out.append(rect(PAD, y, card_w, 20 + len(notes) * 19, 10, PANEL, BORDER, 1))
    for i, (color, line) in enumerate(notes):
        ny = y + 28 + i * 19
        out.append(f'<circle cx="{PAD + 20}" cy="{ny - 4}" r="2.5" fill="{color}"/>')
        out.append(text(PAD + 32, ny, line, 10.5, DIM))
    y += 20 + len(notes) * 19 + 24

    out.append(
        text(
            W // 2,
            y,
            f"{nix_file_count()} files  ·  {len(defs)} aspect names  ·  {edges} includes  ·  {len(host_list)} hosts",
            10.5,
            DIM,
            400,
            "middle",
            0.7,
        )
    )
    height = y + 22

    markers = [
        f'<marker id="arw-{name}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" '
        f'markerHeight="6" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="{color}"/></marker>'
        for name, color in (
            ("green", GREEN),
            ("cyan", CYAN),
            ("pink", PINK),
            ("purple", PURPLE),
        )
    ]
    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{height}" viewBox="0 0 {W} {height}">',
        "<defs>",
        *markers,
        f'<pattern id="grid" width="30" height="30" patternUnits="userSpaceOnUse">'
        f'<circle cx="15" cy="15" r="0.5" fill="{BORDER}" opacity="0.18"/></pattern>',
        "</defs>",
        f'<rect width="{W}" height="{height}" rx="14" fill="{BG}"/>',
        f'<rect width="{W}" height="{height}" rx="14" fill="url(#grid)"/>',
        f'<g font-family="{FONT}">',
        *out,
        "</g></svg>",
    ]
    target = ROOT / "assets" / f"aspect-graph{'' if W == 820 else f'-{W}'}.svg"
    target.write_text("\n".join(svg) + "\n")

    print(f"aspects: {len(aspects)}  edges: {edges}  hosts: {[h for h, _ in host_list]}")
    print(f"wrote {target.relative_to(ROOT)}  {W}x{height}  ({target.stat().st_size} bytes)")
    problems = verify(target, W, height)
    print("layout:", "ok" if not problems else f"{len(problems)} issue(s)")
    for p in problems[:12]:
        print("  !", p)
    print("edges as drawn:")
    for name in [*(a for _, a in host_list), *spine, *sub]:
        ent = aspects[name]
        kids = ", ".join(l for l, _, _ in ent["includes"]) or "-"
        prov = ""
        if ent["provides"]:
            prov = "  | provides " + ", ".join(f"{k}->{v}" for k, v in ent["provides"].items())
        print(f"  {name} -> {kids}{prov}")


if __name__ == "__main__":
    sys.exit(build())
