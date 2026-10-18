#!/usr/bin/env bash
# Araştırma sitesini GitHub Pages için docs/index.html olarak üretir.
# Kaynak: site/robot_kol_arastirma.html (claude.ai sayfasıyla aynı dosya).
# claude.ai sayfası <html>/<head> çerçevesini kendisi ekliyor; burada elle ekliyoruz.
# Görseller tek yerde: docs/img/ (claude.ai'ye de oradan yüklenir).
set -e
DEPO="$(cd "$(dirname "$0")/.." && pwd)"
KAYNAK="$DEPO/site/robot_kol_arastirma.html"
HEDEF="$DEPO/docs/index.html"
{
  printf '<!doctype html>\n<html lang="tr">\n<head>\n<meta charset="utf-8">\n'
  printf '<meta name="viewport" content="width=device-width,initial-scale=1">\n'
  # ilk </style> satırına kadar olan kısım (title, font bağlantısı, stil) başlığa
  awk 'BEGIN{h=1} {if(h) print} /<\/style>/{if(h){h=0}}' "$KAYNAK"
  printf '</head>\n<body>\n'
  awk 'BEGIN{h=1} {if(!h) print} /<\/style>/{if(h){h=0}}' "$KAYNAK"
  printf '</body>\n</html>\n'
} > "$HEDEF"
touch "$DEPO/docs/.nojekyll"
echo "docs/index.html güncellendi ($(wc -c < "$HEDEF") bayt)"
