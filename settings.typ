// Общие данные, которые не меняются от песни к песне

#let author = "Sergio Rykov"
#let author-photo = "images/author-photo.jpg"  // Квадратное фото автора
#let album = "Тишина"
#let album-year = "2026"

// Настройки шрифтов и цветов
#let main-font = "Segoe UI"
#let chord-color = blue.darken(30%)  // Цвет аккордов
#let text-color = black
#let bg-color = white

// Размеры
#let cover-size = 2.5cm  // Размер квадратного фото песни
#let author-icon-size = 0.8cm  // Размер иконки автора

// Per-language overrides — any key here shadows the global default in template.typ
// Supported keys: lyrics-label, music-label, author (default music author name)
#let lang-settings = (
  ru: (
    lyrics-label: "Стихи",
    music-label:  "Музыка",
    author:       "Сергей Рыков",
  ),
  en: (
    lyrics-label: "Lyrics",
    music-label:  "Music",
  ),
)