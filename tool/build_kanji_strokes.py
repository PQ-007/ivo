#!/usr/bin/env python3
"""
Build a compact offline stroke-template asset for handwriting recognition.

Source: KanjiVG (https://kanjivg.tagaini.net) — CC BY-SA 3.0, (C) Ulrich Apel.
We sample each kanji's canonical strokes (in stroke order) into a fixed number
of arc-length-spaced points, normalize to a unit box, quantize to uint8, and
write a small binary the Dart `StrokeRecognizer` reads at runtime.

Character set: restricted to kanji the bundled dictionary knows AND that
learners actually hit (kanji.db rows with a JLPT level or frequency), plus the
basic hiragana/katakana blocks. This keeps the asset ~1 MB instead of 23 MB.

Usage:
    python tool/build_kanji_strokes.py \
        --kanjivg <kanjivg.xml> \
        --kanjidb assets/db/kanji.db \
        --out assets/kanji_strokes.bin

Binary format (all integers big-endian):
    header:  magic "KVG1" (4 bytes) | N points-per-stroke (1 byte) |
             record count (uint32, 4 bytes)
    record:  codepoint (uint32, 4 bytes) | stroke count (uint8, 1 byte) |
             stroke count * N * 2 bytes of (x, y) uint8 in [0,255]
"""

import argparse
import sqlite3
import struct
import sys
import xml.etree.ElementTree as ET

from svgpathtools import parse_path

N_POINTS = 16          # points sampled per stroke
MAX_STROKES = 40       # skip pathological entries
EPS = 1e-6


def target_chars(kanjidb_path):
    """Codepoints we want templates for: dict kanji with jlpt/freq + kana."""
    chars = set()
    conn = sqlite3.connect(kanjidb_path)
    try:
        rows = conn.execute(
            "SELECT id FROM character WHERE freq IS NOT NULL OR jlpt IS NOT NULL"
        ).fetchall()
    finally:
        conn.close()
    for (cid,) in rows:
        if cid:
            chars.add(ord(cid[0]))
    # basic hiragana + katakana (useful for draw-to-search)
    chars.update(range(0x3041, 0x3097))   # hiragana
    chars.update(range(0x30A1, 0x30FB))   # katakana
    return chars


def sample_stroke(d_attr):
    """Sample one SVG path into N_POINTS arc-length-spaced (x, y) tuples."""
    path = parse_path(d_attr)
    total = path.length()
    pts = []
    if total < EPS:
        # a dot: repeat the start point
        p = path.point(0.0)
        return [(p.real, p.imag)] * N_POINTS
    for i in range(N_POINTS):
        s = total * (i / (N_POINTS - 1))
        t = path.ilength(s)
        p = path.point(t)
        pts.append((p.real, p.imag))
    return pts


def normalize(strokes):
    """Translate+uniform-scale all strokes into [0,1] preserving aspect ratio."""
    xs = [x for st in strokes for (x, _) in st]
    ys = [y for st in strokes for (_, y) in st]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    w, h = maxx - minx, maxy - miny
    scale = 1.0 / max(w, h, EPS)
    out = []
    for st in strokes:
        out.append([((x - minx) * scale, (y - miny) * scale) for (x, y) in st])
    return out


def q(v):
    return max(0, min(255, round(v * 255)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kanjivg", required=True)
    ap.add_argument("--kanjidb", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    wanted = target_chars(args.kanjidb)
    print(f"target characters: {len(wanted)}")

    tree = ET.parse(args.kanjivg)
    root = tree.getroot()

    records = []  # (codepoint, [stroke,...]) ; stroke = list[(x,y) in [0,1]]
    for kanji in root.findall("kanji"):
        kid = kanji.get("id", "")            # e.g. kvg:kanji_06c34
        hexcp = kid.split("_")[-1]
        try:
            cp = int(hexcp, 16)
        except ValueError:
            continue
        if cp not in wanted:
            continue
        # all <path> in document order == stroke order
        d_attrs = [p.get("d") for p in kanji.iter("path") if p.get("d")]
        if not d_attrs or len(d_attrs) > MAX_STROKES:
            continue
        try:
            strokes = [sample_stroke(d) for d in d_attrs]
        except Exception as e:  # noqa: BLE001
            print(f"  skip U+{cp:04X}: {e}", file=sys.stderr)
            continue
        records.append((cp, normalize(strokes)))

    records.sort(key=lambda r: r[0])
    print(f"emitting {len(records)} records")

    with open(args.out, "wb") as f:
        f.write(b"KVG1")
        f.write(struct.pack("B", N_POINTS))
        f.write(struct.pack(">I", len(records)))
        for cp, strokes in records:
            f.write(struct.pack(">I", cp))
            f.write(struct.pack("B", len(strokes)))
            for st in strokes:
                for (x, y) in st:
                    f.write(struct.pack("BB", q(x), q(y)))

    import os
    size = os.path.getsize(args.out)
    print(f"wrote {args.out}: {size/1024:.0f} KB")


if __name__ == "__main__":
    main()
