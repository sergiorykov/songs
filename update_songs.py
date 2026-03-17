#!/usr/bin/env python3
"""Sync song list in index.html and README.md from songs/*.typ metadata."""

import re
import sys
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).parent.resolve()
SONGS_DIR = ROOT / "songs"
INDEX_HTML = ROOT / "index.html"
README_MD  = ROOT / "README.md"
PAGES_BASE = "https://sergiorykov.github.io/songs"

SVG_PLAY = (
    '<svg width="11" height="13" viewBox="0 0 11 13" fill="white">'
    '<polygon points="0,0 11,6.5 0,13"/>'
    "</svg>"
)
SVG_SC = (
    '<svg width="22" height="11" viewBox="0 0 60 28" fill="white">'
    '<path d="M0 20q0-2 1.4-3.4Q2.8 15.2 5 15.2q.5 0 1 .1.3-3.4 2.8-5.6'
    "Q11.3 7.5 15 7.5q2.4 0 4.4 1.1 2 1.1 3.2 3 1-.4 2.1-.4 2.6 0 4.4 1.8"
    " 1.8 1.8 1.8 4.4 0 2.5-1.8 4.3Q27.3 23.5 24.7 23.5H5q-2.1 0-3.55-1.5"
    'Q0 20.5 0 20z"/>'
    "</svg>"
)

# Matches a line that consists only of chord tokens (e.g. "F Em Am \")
_CHORD_TOKEN = re.compile(
    r'^[A-G][#b]?(?:m(?:aj7|in7)?|7|dim7?|aug|sus[24]|add9)?(?:/[A-G][#b]?)?(?:\([^)]+\))?$'
    r'|^\([^)]+\)$'
)


def _is_chord_line(line: str) -> bool:
    tokens = line.rstrip("\\").split()
    return bool(tokens) and all(_CHORD_TOKEN.match(t) for t in tokens)


def extract_lyrics(path: Path) -> str:
    """Return song lyrics as plain text, stripping chords and typst markup."""
    text = path.read_text(encoding="utf-8")
    # Everything after the closing ) of song-template.with(...)
    match = re.search(r'^\)\s*$', text, re.MULTILINE)
    if not match:
        return ""
    body = text[match.end():]

    lines = []
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            lines.append("")
            continue
        if _is_chord_line(stripped):
            continue
        lines.append(stripped.rstrip("\\").rstrip())

    result = "\n".join(lines).strip()
    return re.sub(r"\n{3,}", "\n\n", result)


def parse_song(path: Path) -> dict:
    """Extract metadata and lyrics from a .typ file."""
    text = path.read_text(encoding="utf-8")
    title = re.search(r'title:\s*"([^"]+)"', text)
    sc    = re.search(r'soundcloud:\s*"([^"]+)"', text)
    lang  = re.search(r'language:\s*"([^"]+)"', text)
    return {
        "title":      title.group(1) if title else path.stem,
        "soundcloud": sc.group(1)    if sc    else None,
        "language":   lang.group(1)  if lang  else "en",
        "lyrics":     extract_lyrics(path),
    }


def load_songs() -> list[dict]:
    return [parse_song(p) for p in sorted(SONGS_DIR.glob("*.typ"))]


# ── index.html ────────────────────────────────────────────────────────────────

def render_html_item(song: dict) -> str:
    title  = song["title"]
    sc     = song["soundcloud"]
    lang   = song["language"]
    lyrics = song["lyrics"]
    pdf_href = f"pdf/{title}.pdf"

    sc_btn = ""
    if sc:
        sc_btn = (
            f'<a class="icon-btn sc-btn"'
            f' href="{sc}"'
            f' target="_blank" rel="noopener"'
            f' data-tooltip="Listen on SoundCloud">'
            f"{SVG_PLAY}{SVG_SC}</a>"
        )

    pdf_btn = (
        f'<a class="icon-btn lang-btn"'
        f' href="{pdf_href}"'
        f' target="_blank" rel="noopener"'
        f' data-tooltip="Sheet music PDF">{lang}</a>'
    )

    lyrics_escaped = (
        lyrics
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )

    lyrics_block = ""
    if lyrics_escaped:
        lyrics_block = (
            f'\n        <div class="lyrics">'
            f'<pre>{lyrics_escaped}</pre>'
            f"</div>"
        )

    return (
        f"      <li>\n"
        f'        <details class="song-details">\n'
        f'          <summary class="song-row">\n'
        f'            <span class="song-title">{title}</span>\n'
        f'            <div class="song-actions">{sc_btn}{pdf_btn}</div>\n'
        f"          </summary>"
        f"{lyrics_block}\n"
        f"        </details>\n"
        f"      </li>"
    )


def update_html(songs: list[dict]) -> bool:
    text = INDEX_HTML.read_text(encoding="utf-8")
    inner = "\n".join(render_html_item(s) for s in songs)
    new_block = f"      <!-- songs:start -->\n{inner}\n      <!-- songs:end -->"
    updated = re.sub(
        r"      <!-- songs:start -->.*?      <!-- songs:end -->",
        new_block,
        text,
        flags=re.DOTALL,
    )
    if updated == text:
        return False
    INDEX_HTML.write_text(updated, encoding="utf-8")
    return True


# ── README.md ─────────────────────────────────────────────────────────────────

def render_md_row(song: dict) -> str:
    title   = song["title"]
    sc      = song["soundcloud"]
    encoded = quote(title)
    pdf_url = f"{PAGES_BASE}/pdf/{encoded}.pdf"
    pdf_col = f"[PDF]({pdf_url})"
    sc_col  = f"[Listen]({sc})" if sc else "—"
    return f"| {title} | {pdf_col} | {sc_col} |"


def update_readme(songs: list[dict]) -> bool:
    text = README_MD.read_text(encoding="utf-8")
    header = "| Song | Sheet music | SoundCloud |\n|------|-------------|------------|"
    rows   = "\n".join(render_md_row(s) for s in songs)
    inner  = f"{header}\n{rows}"
    new_block = f"<!-- songs:start -->\n{inner}\n<!-- songs:end -->"
    updated = re.sub(
        r"<!-- songs:start -->.*?<!-- songs:end -->",
        new_block,
        text,
        flags=re.DOTALL,
    )
    if updated == text:
        return False
    README_MD.write_text(updated, encoding="utf-8")
    return True


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    songs = load_songs()
    if not songs:
        print("No songs found.", file=sys.stderr)
        sys.exit(1)

    changed = []
    if update_html(songs):
        changed.append("index.html")
    if update_readme(songs):
        changed.append("README.md")

    if changed:
        print(f"Updated: {', '.join(changed)}")
    else:
        print("Already up to date.")


if __name__ == "__main__":
    main()
