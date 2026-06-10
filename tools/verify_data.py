#!/usr/bin/env python3
"""Verify trial-journey facts against authoritative WoW Classic Era data.

Ground truth, in order of authority:
  zones/subzones  -> client DB2 dumps via wago.tools (AreaTable, WMOAreaTable,
                     Map) for a pinned 1.15.x build. These are the exact
                     strings GetZoneText/GetSubZoneText/GetMinimapZoneText
                     return (enUS).
  spells/auras    -> SpellName DB2 (exact match required).
  items           -> ItemSparse DB2 (exact match required).
  emote tokens    -> the client's own ChatFrame.lua (Gethe/wow-ui-source,
                     classic_era branch).
  NPC names       -> not in client data (server-side); checked against
                     Wowhead Classic's search suggestions, else flagged
                     for manual review with a search URL.

Usage (from repo root):
  lua tools/extract_facts.lua > tools/facts.json
  python3 tools/verify_data.py

Downloads are cached in tools/cache/. Pin a different build with
WOW_BUILD=1.15.x.yyyyy.
"""

import csv
import io
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

BUILD = os.environ.get("WOW_BUILD", "1.15.8.67156")
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "cache")
FACTS = os.path.join(HERE, "facts.json")

UA = {"User-Agent": "PrestigeClasses-data-verifier/1.0 (addon dev tool)"}

CHATFRAME_URLS = [
    # Emote tokens live in ChatEmoteConstants.lua on current classic_era.
    "https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_era/Interface/AddOns/Blizzard_ChatFrameBase/Classic/ChatEmoteConstants.lua",
    "https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_era/Interface/FrameXML/ChatFrame.lua",
    "https://raw.githubusercontent.com/Gethe/wow-ui-source/classic_era/Interface/AddOns/Blizzard_ChatFrameBase/Classic/ChatFrame.lua",
]


def fetch(url, dest, binary=False):
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        return dest
    sys.stderr.write(f"  downloading {url}\n")
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    os.makedirs(CACHE, exist_ok=True)
    with open(dest, "wb") as f:
        f.write(data)
    time.sleep(0.5)  # be polite
    return dest


def db2_csv(table):
    dest = os.path.join(CACHE, f"{table}.{BUILD}.csv")
    fetch(f"https://wago.tools/db2/{table}/csv?build={BUILD}", dest)
    with open(dest, newline="", encoding="utf-8", errors="replace") as f:
        return list(csv.DictReader(f))


def column(rows, *candidates):
    for c in candidates:
        if rows and c in rows[0]:
            return [r[c] for r in rows if r.get(c)]
    raise SystemExit(f"none of {candidates} found in CSV columns: "
                     f"{list(rows[0].keys()) if rows else 'EMPTY'}")


def emote_tokens():
    dest = os.path.join(CACHE, "ChatFrame.classic_era.lua")
    last_err = None
    for url in CHATFRAME_URLS:
        try:
            fetch(url, dest)
            break
        except Exception as e:  # try next layout
            last_err = e
    if not os.path.exists(dest):
        sys.stderr.write(f"  WARN: could not fetch ChatFrame.lua ({last_err})\n")
        return None
    text = open(dest, encoding="utf-8", errors="replace").read()
    return set(re.findall(r'EMOTE\d+_TOKEN\s*=\s*"([A-Z_]+)"', text))


def wowhead_npc(name):
    """Return 'ok' / 'missing' / 'unknown' for an NPC name on Wowhead Classic."""
    slug = urllib.parse.quote(name)
    dest = os.path.join(CACHE, "npc." + re.sub(r"\W+", "_", name) + ".json")
    url = ("https://classic.wowhead.com/search/suggestions-template"
           f"?q={slug}")
    try:
        fetch(url, dest)
        body = open(dest, encoding="utf-8", errors="replace").read()
        # The suggestions payload mentions matching entity names verbatim.
        return "ok" if name.lower() in body.lower() else "missing"
    except Exception as e:
        sys.stderr.write(f"  WARN: wowhead lookup failed for {name}: {e}\n")
        return "unknown"


def contains_ci(haystacks, needle):
    n = needle.lower()
    return sorted({h for h in haystacks if n in h.lower()})[:4]


def main():
    facts = json.load(open(FACTS, encoding="utf-8"))

    sys.stderr.write(f"build {BUILD}: loading client tables...\n")
    area = column(db2_csv("AreaTable"), "AreaName_lang")
    wmo = column(db2_csv("WMOAreaTable"), "AreaName_lang")
    maps = column(db2_csv("Map"), "MapName_lang")
    spells = set(s.lower() for s in column(db2_csv("SpellName"), "Name_lang"))
    items = set(i.lower() for i in column(db2_csv("ItemSparse"), "Display_lang"))
    tokens = emote_tokens()

    ok, warn, fail = 0, 0, 0
    lines = []

    def report(status, fact, detail):
        nonlocal ok, warn, fail
        mark = {"OK": "ok  ", "WARN": "WARN", "FAIL": "FAIL"}[status]
        if status == "OK":
            ok += 1
        elif status == "WARN":
            warn += 1
        else:
            fail += 1
        lines.append(f"  {mark} [{fact['kind']:11}] {fact['value']!r}"
                     f" ({fact['source']}) {detail}")

    for fact in facts:
        kind, value = fact["kind"], fact["value"]
        if kind in ("zone", "subzone"):
            pool = (area + maps) if kind == "zone" else (area + wmo)
            hits = contains_ci(pool, value)
            if hits:
                report("OK", fact, f"-> {hits}")
            else:
                report("FAIL", fact, "no area/WMO/map name contains this")
        elif kind == "spell":
            if value.lower() in spells:
                report("OK", fact, "exact SpellName match")
            else:
                report("FAIL", fact, "not in SpellName")
        elif kind == "item":
            if value.lower() in items:
                report("OK", fact, "exact ItemSparse match")
            else:
                report("FAIL", fact, "not in ItemSparse")
        elif kind == "emote":
            if tokens is None:
                report("WARN", fact, "token list unavailable; check manually")
            elif value in tokens:
                report("OK", fact, "valid DoEmote token")
            else:
                report("FAIL", fact, "not an EMOTEnn_TOKEN in ChatFrame.lua")
        elif kind == "npc":
            status = wowhead_npc(value)
            if status == "ok":
                report("OK", fact, "found on Wowhead Classic")
            else:
                report("WARN", fact,
                       "verify manually: https://classic.wowhead.com/search?q="
                       + urllib.parse.quote(value))
        elif kind == "npc_pattern":
            report("WARN", fact,
                   "substring pattern; confirm mobs exist: "
                   "https://classic.wowhead.com/npcs/name:"
                   + urllib.parse.quote(value))
        else:
            report("WARN", fact, "unknown fact kind")

    print("\n".join(lines))
    print(f"\n==== {ok} ok, {warn} to check manually, {fail} FAILED ====")
    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
