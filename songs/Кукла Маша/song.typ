// Per-language configuration for "Кукла Маша".
// Keys in `about` are shared; each entry in `languages` overrides individual keys.
// Usage in lang files: #show: song-template.with(..variant("ru"))

#import "../../albums/Кукла Маша/album.typ": album as _album

#let about = (
  song-id:          "kukla-masha",
  album-id:         "kukla-masha",
  album:            _album.album,
  album-year:       _album.album-year,
  default_language: "ru",
  cover-image:      "/songs/Кукла Маша/cover.png",
  capo:             "3",
  soundcloud:       "https://soundcloud.com/sergiorykov/kukla-masha",
  soundcloud-embed: "https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/soundcloud%253Atracks%253A1814438613&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true",
)

#let languages = (
  ru: (
    title:        "Кукла Маша",
    lyrics-author:    "Сергей Рыков",
    lyrics-author-url: "https://soundcloud.com/sergiorykov/",
    lyrics-date:      "01.07.2016",
    lyrics-sources:   (),
    music-author: "Сергей Рыков",
    music-author-url: "https://soundcloud.com/sergiorykov/",
    music-date:       "01.07.2016",
  ),
)

// Merge about + language overrides; inject language code from key name
#let variant(lang) = {
  let result = about
  result.insert("language", lang)
  for (k, v) in languages.at(lang) { result.insert(k, v) }
  result
}
