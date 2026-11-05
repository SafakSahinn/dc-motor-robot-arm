#!/usr/bin/env bash
# GitHub Pages sayfalarını üretir (docs/):
#   site/ana_sayfa.html           -> docs/index.html   (güncel çalışmanın sade özeti)
#   site/robot_kol_arastirma.html -> docs/defter.html  (ayrıntılı araştırma defteri)
# Kaynaklarda <html>/<head> çerçevesi yok (claude.ai sayfası kendisi ekliyor); burada elle ekliyoruz:
# ilk </style> satırına kadar olan kısım (title, font bağlantısı, stil) başlığa gider.
# Görseller tek yerde: docs/img/.
set -e
DEPO="$(cd "$(dirname "$0")/.." && pwd)"
uret() {
  local KAYNAK="$DEPO/site/$1" HEDEF="$DEPO/docs/$2"
  {
    printf '<!doctype html>\n<html lang="tr">\n<head>\n<meta charset="utf-8">\n'
    printf '<meta name="viewport" content="width=device-width,initial-scale=1">\n'
    awk 'BEGIN{h=1} {if(h) print} /<\/style>/{if(h){h=0}}' "$KAYNAK"
    printf '</head>\n<body>\n'
    awk 'BEGIN{h=1} {if(!h) print} /<\/style>/{if(h){h=0}}' "$KAYNAK"
    printf '</body>\n</html>\n'
  } > "$HEDEF"
  echo "docs/$2 güncellendi ($(wc -c < "$HEDEF") bayt)"
}
uret ana_sayfa.html index.html
uret robot_kol_arastirma.html defter.html
touch "$DEPO/docs/.nojekyll"
