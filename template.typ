// template.typ
#import "settings.typ": author, author-photo, album, album-year, main-font, chord-color, text-color, cover-size, author-icon-size, lang-settings
#import "albums/registry.typ": registry as _album_registry

// Highlight chords: Latin A-G with modifiers (Cyrillic lyrics don't overlap)
#let chord-show = it => text(weight: "bold", fill: chord-color, font: "Courier New", size: 0.9em, it)

#let song-template(
  title: "",
  cover-image: none,
  capo: none,
  soundcloud: none,
  language: "en",
  default: false,           // used by update_songs.py; ignored here
  default_language: "",     // propagated from about; ignored here
  soundcloud-embed: none,   // used by update_songs.py; ignored here
  song-id: "",              // used by update_songs.py; ignored here
  album-id: "",             // resolve album from registry; falls back to global settings
  // Lyrics credits
  lyrics-author: none,
  lyrics-author-url: none,
  lyrics-date: none,
  lyrics-sources: (),   // array of ("Label", "url") pairs
  // Music credits
  music-author: none,   // if none, resolved from lang-settings or global author
  music-author-url: none,
  music-date: none,
  body,
) = {
  // Resolve album from registry (panics if album-id is set but not found)
  let _ra      = if album-id != "" { _album_registry.at(album-id) } else { none }
  let _ra_raw  = if _ra != none { _ra.lang.at(language, default: (:)) } else { (:) }
  let _ra_lang = if type(_ra_raw) == dictionary { _ra_raw } else { (:) }

  // Resolve per-language overrides from settings
  let ls             = lang-settings.at(language, default: (:))
  let lyrics-label   = ls.at("lyrics-label", default: "Lyrics")
  let music-label    = ls.at("music-label",  default: "Music")
  let eff-music-author = if music-author != none { music-author } else {
    ls.at("author", default: author)
  }
  let eff-album      = _ra_lang.at("album",
    default: if _ra != none { _ra.album } else { ls.at("album", default: album) })
  let eff-album-year = if _ra != none { _ra.album-year } else { album-year }

  let _header-color = luma(150)
  let _photo-size   = 0.5cm

  set page(
    paper: "a5",
    margin: (x: 1.2cm, top: 1.5cm, bottom: 1cm),
    header: {
      set text(font: main-font, size: 7.5pt, fill: _header-color)
      grid(
        columns: (1fr, auto, 1fr),
        align: (left + horizon, center + horizon, right + horizon),
        [#eff-album · #eff-album-year],
        title,
        grid(
          columns: (auto, auto),
          column-gutter: 0.2em,
          align: horizon,
          box(width: _photo-size, height: _photo-size, radius: 50%, clip: true,
            image(author-photo, width: _photo-size, height: _photo-size, fit: "cover")),
          eff-music-author,
        ),
      )
      line(length: 100%, stroke: 0.5pt + _header-color)
    },
  )

  set text(font: main-font, size: 11pt, fill: text-color, lang: language)
  set par(leading: 0.55em, spacing: 1em)

  // Apply chord highlighting via show rule (document-wide)
  show regex("\\b[A-G][#b]?m?(maj7|min7|7|dim7|dim|aug|sus4|sus2|add9)?(/[A-G][#b]?)?\\b"): chord-show

  // ── Title + cover + credits ─────────────────────────────────────
  grid(
    columns: (cover-size, 1fr),
    gutter: 0.4cm,
    align: top,
    image(cover-image, width: cover-size, height: cover-size, fit: "cover"),
    block(inset: 0pt)[
      #set par(leading: 0.3em, spacing: 0.35em)
      #text(size: 13pt, weight: "bold", title)
      \
      #set text(size: 7pt, fill: luma(130), style: "italic")
      #if lyrics-author != none [
        #lyrics-label: #if lyrics-author-url != none [
          #link(lyrics-author-url)[#lyrics-author]
        ] else [
          #lyrics-author
        ]#if lyrics-date != none [ · #lyrics-date]#for s in lyrics-sources [ · #link(s.at(1))[#s.at(0)]]
        \
      ]
      #music-label: #if music-author-url != none [
        #link(music-author-url)[#eff-music-author]
      ] else [
        #eff-music-author
      ]#if music-date != none [ · #music-date]
    ],
  )

  v(0.5cm)

  // ── Capo indicator ──────────────────────────────────────────────
  if capo != none {
    block(inset: (bottom: 0.3cm))[
      #text(size: 9pt, fill: luma(110), style: "italic")[Capo +#capo]
    ]
  }

  // ── Song body ───────────────────────────────────────────────────
  body
}
