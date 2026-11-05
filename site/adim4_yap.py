"""4. adım raporunu (rapor/rapor.html) site tasarımında bir web sayfasına çevirir: docs/adim4.html.

İçerik raporla birebir aynı (tek kaynak rapor.html); yalnız sunum değişir:
  - A4 baskı stili yerine sitenin renk/yazı tokenları, açık ve koyu tema, telefon genişliği
  - her rapor bölümü bir kart; ana bölümler yan menüde bağlantı
  - tablolar yatay kaydırmalı kapta
  - görseller docs/img/adim4/ altına kopyalanır; Ek B'ye Mechanics Explorer videosu eklenir
Kullanım (depo kökünden):  python site/adim4_yap.py   (ardından bash site/yayinla.sh gerekmez; ayrı dosya)
"""
import html, os, re, shutil, sys

sys.stdout.reconfigure(encoding="utf-8")
DEPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KAYNAK = os.path.join(DEPO, "rapor", "rapor.html")
IMG_K = os.path.join(DEPO, "rapor", "img")
HEDEF = os.path.join(DEPO, "docs", "adim4.html")
IMG_H = os.path.join(DEPO, "docs", "img", "adim4")
GH = "https://github.com/SafakSahinn/dc-motor-robot-arm"
PDF = GH + "/blob/main/rapor/adim4_simulasyon_ve_dogrulama.pdf"

t = open(KAYNAK, encoding="utf-8").read()
govde = t[t.index("<body>") + len("<body>"): t.index("</body>")]

# --- görseller ---
os.makedirs(IMG_H, exist_ok=True)
gorseller = sorted(set(re.findall(r'src="img/([^"]+)"', govde)))
for g in gorseller + ["mb_animasyon.mp4"]:
    shutil.copy2(os.path.join(IMG_K, g), os.path.join(IMG_H, g))
govde = govde.replace('src="img/', 'src="img/adim4/')

# --- Ek B: videoyu Mechanics Explorer karelerinin altına ekle ---
isaret = 'src="img/adim4/mb_me_kareler.png"'
i = govde.index(isaret)
j = govde.index("</figure>", i) + len("</figure>")
video = ('\n  <figure><video controls loop muted playsinline preload="metadata" '
         'src="img/adim4/mb_animasyon.mp4" aria-label="Mechanics Explorer animasyonu, hücre 5"></video>'
         '<figcaption>Mechanics Explorer animasyonu: hücre 5, 1,5 s benzetim, 0,2× hızda 7,5 s '
         '(<code>mb_animasyon.mp4</code>).</figcaption></figure>')
govde = govde[:j] + video + govde[j:]

# --- tablolar kaydırmalı kapta (ısı haritası tabloları kendi ızgarasında kalır) ---
govde = re.sub(r'(<table(?! class="hm")[\s\S]*?</table>)', r'<div class="tbl">\1</div>', govde)

# --- bölümlere kimlik, ana bölümlerden menü ---
menu, n = [], 0
def bolum(m):
    global n
    n += 1
    kicker, baslik = m.group(2), m.group(3)
    kimlik = f"b{n}"
    duz = re.sub(r"<[^>]+>", "", baslik)
    if "devam" not in kicker:
        no = re.sub(r"<[^>]+>", "", kicker).split("·")[0].strip()
        menu.append((kimlik, no, duz))
    return f'<section id="{kimlik}"{m.group(1)}>\n  <div class="kicker">{kicker}</div>\n  <h2>{baslik}</h2>'
govde = re.sub(r'<section( class="[^"]*")?>\s*<div class="kicker">(.*?)</div>\s*<h2>(.*?)</h2>', bolum, govde)
# kartsız devam blokları (kicker'sız <section class="devam">) bir önceki kartın parçası gibi görünsün
govde = govde.replace('<section class="devam">', '<section class="devam ek">')

# --- kapak: baskı kapağını üst bilgi kartına çevir ---
govde = govde.replace('<div>\n  <div class="kicker">Ara rapor', '<header class="kapak">\n  <div class="kicker">Ara rapor', 1)
k = govde.index('<header class="kapak">')
s = govde.index("<section", k)
kapak_son = govde.rindex("</div>", k, s)
govde = govde[:kapak_son] + "</header>" + govde[kapak_son + len("</div>"):]

# --- A.6: web sürümünde dosyalar depoda ---
a6 = govde.index("A.6 PDF")
not_ = (f'<div class="note ok"><b class="t">Web sürümünde</b>Gömülü dosyalar PDF\'te; aynı dosyalar depoda '
        f'<a href="{GH}/tree/main/simulasyon/simulink"><code>simulasyon/simulink/</code></a> klasöründe, video '
        f'<a href="{GH}/blob/main/rapor/img/mb_animasyon.mp4"><code>rapor/img/mb_animasyon.mp4</code></a>.</div>')
k6 = govde.index("</section>", a6)
govde = govde[:k6] + not_ + "\n" + govde[k6:]

nav = "\n".join(f'  <a href="#{k}"><span>{html.escape(no)}</span>{html.escape(b)}</a>' for k, no, b in menu)

CSS = r"""
/* Düzen: solda yapışkan bölüm menüsü, sağda raporun bölümleri kart kart; ana siteyle aynı tokenlar */
:root{
  --bg:#f4f6f5; --paper:#ffffff; --ink:#18231f; --muted:#5b6a64; --line:#d8e1dd;
  --accent:#2d6a5a; --accent-soft:#e2efea; --warn:#9a5b12; --warn-soft:#f8eddc; --todo:#2f5a8a; --todo-soft:#e3ecf7;
  --hot:#b03a2e; --on-hot:#ffffff; --img-bg:#ffffff;
  --display:"Bricolage Grotesque","Segoe UI",system-ui,sans-serif;
  --body:"Source Sans 3","Segoe UI",system-ui,sans-serif;
  --mono:"JetBrains Mono",Consolas,"Courier New",monospace;
}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){
  --bg:#101715; --paper:#17211e; --ink:#e2ebe7; --muted:#9aaba4; --line:#29372f;
  --accent:#7fcbb4; --accent-soft:#1b322b; --warn:#e9b56f; --warn-soft:#352816; --todo:#8db7e6; --todo-soft:#1b2a3c;
  --hot:#d9675a; --on-hot:#101715; --img-bg:#ffffff; color-scheme:dark}}
:root[data-theme="dark"]{
  --bg:#101715; --paper:#17211e; --ink:#e2ebe7; --muted:#9aaba4; --line:#29372f;
  --accent:#7fcbb4; --accent-soft:#1b322b; --warn:#e9b56f; --warn-soft:#352816; --todo:#8db7e6; --todo-soft:#1b2a3c;
  --hot:#d9675a; --on-hot:#101715; --img-bg:#ffffff; color-scheme:dark}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{background:var(--bg); color:var(--ink); font:17px/1.6 var(--body); margin:0}
.wrap{max-width:1180px; margin:0 auto; padding-left:max(16px,env(safe-area-inset-left,0px)); padding-right:max(16px,env(safe-area-inset-right,0px));
  padding-block:28px 64px; display:grid; grid-template-columns:230px minmax(0,1fr); gap:36px}
nav{position:sticky; top:calc(env(safe-area-inset-top,0px) + 20px); align-self:start; max-height:calc(100vh - 40px); overflow-y:auto;
  display:flex; flex-direction:column; gap:2px; font-size:14.5px}
nav a{display:grid; grid-template-columns:2.4em minmax(0,1fr); gap:4px; color:var(--muted); text-decoration:none; padding:5px 8px; border-radius:6px; line-height:1.35}
nav a span{font:500 12px/1.6 var(--mono); color:var(--accent)}
nav a:hover,nav a:focus-visible{background:var(--accent-soft); color:var(--accent); outline:none}
nav .lbl{font:500 11px var(--mono); letter-spacing:.08em; text-transform:uppercase; color:var(--muted); padding:0 8px 6px}
nav .geri{margin-bottom:10px; display:block}
main{min-width:0; display:flex; flex-direction:column; gap:22px}
h1{font:700 clamp(28px,4.4vw,40px)/1.12 var(--display); margin:6px 0 10px; text-wrap:balance}
h2{font:700 25px/1.2 var(--display); margin:4px 0 0; text-wrap:balance}
h3{font:600 13px var(--mono); letter-spacing:.07em; text-transform:uppercase; color:var(--muted); margin:20px 0 6px}
.kicker{font:500 12px var(--mono); letter-spacing:.08em; text-transform:uppercase; color:var(--accent)}
header.kapak,section{background:var(--paper); border:1px solid var(--line); border-radius:10px; padding:24px 26px; min-width:0; scroll-margin-top:16px}
section.devam.ek{margin-top:-22px; border-top:none; border-radius:0 0 10px 10px; padding-top:4px}
p{margin:8px 0 0; max-width:74ch}
.lead{color:var(--muted); font-size:18px}
ul,ol{margin:8px 0 0; padding-left:1.3em; max-width:76ch} li{margin:3px 0}
a{color:var(--accent)} a:focus-visible{outline:2px solid var(--accent); outline-offset:2px}
code{font:.86em var(--mono)}
.baglar{display:flex; flex-wrap:wrap; gap:8px; margin-top:16px}
.baglar a{font:500 13px var(--mono); border:1px solid var(--line); border-radius:999px; padding:5px 14px; text-decoration:none}
.baglar a:hover,.baglar a:focus-visible{background:var(--accent-soft)}
.toc{display:none}
.stats{display:flex; flex-wrap:wrap; gap:10px; margin-top:16px}
.stat{border:1px solid var(--line); border-radius:8px; padding:10px 14px; min-width:150px; flex:1 1 150px}
.stat b{display:block; font:700 22px/1.15 var(--display); color:var(--accent); font-variant-numeric:tabular-nums}
.stat span{font-size:14px; color:var(--muted)}
.tbl{overflow-x:auto; margin-top:10px}
table{border-collapse:collapse; width:100%; font-size:15px}
th,td{text-align:left; vertical-align:top; padding:7px 9px; border-bottom:1px solid var(--line)}
th{font:500 11.5px var(--mono); letter-spacing:.05em; text-transform:uppercase; color:var(--muted)}
td.n{font-family:var(--mono); font-size:14px; white-space:nowrap; font-variant-numeric:tabular-nums}
tr.vurgu td{background:var(--accent-soft)}
table.meta td:first-child{font-weight:600; width:170px}
table.ek{font-size:14px}
.note{margin-top:14px; background:var(--warn-soft); border-radius:8px; padding:12px 16px; max-width:80ch}
.note b.t{display:block; font:500 12px var(--mono); letter-spacing:.07em; text-transform:uppercase; color:var(--warn); margin-bottom:2px}
.note.ok{background:var(--accent-soft)} .note.ok b.t{color:var(--accent)}
figure{margin:14px 0 0; min-width:0}
figure img,figure video{display:block; max-width:100%; height:auto; border:1px solid var(--line); border-radius:8px; background:var(--img-bg)}
figure img[style]{margin-inline:auto}
figcaption{font-size:14.5px; color:var(--muted); margin-top:6px; max-width:90ch}
.yatay{margin-top:14px}
main > .yatay{margin-top:0; background:var(--paper); border:1px solid var(--line); border-radius:10px; padding:16px}
.dosya{margin-top:12px; font-size:14px; color:var(--muted); border-top:1px dashed var(--line); padding-top:6px}
.dosya code{color:var(--ink)}
.adim{border:1px solid var(--line); border-radius:8px; padding:12px 16px; margin-top:14px}
.adim > h3:first-child{margin-top:0}
.adim .bas{font:600 17px var(--body); margin:0}
.qa p{margin-top:10px}
.kodkutu{margin-top:12px; border:1px solid var(--line); border-radius:8px; overflow:hidden}
.kodbas{font:600 13px var(--mono); color:var(--accent); background:var(--accent-soft); padding:6px 10px}
.kodbas span{color:var(--muted); font-weight:400}
pre.kod{margin:0; padding:8px 10px; font:12.5px/1.45 var(--mono); overflow-x:auto; white-space:pre; color:var(--ink); max-height:520px; overflow-y:auto}
.ikili{display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:14px}
.hm-izgara{display:flex; flex-wrap:wrap; gap:14px; margin-top:10px; max-width:100%; overflow-x:auto}
.hm{border-collapse:collapse; font:12px var(--mono); width:auto}
.hm caption{font:500 12px var(--mono); color:var(--muted); text-align:left; padding-bottom:4px; caption-side:top}
.hm th{font:400 11px var(--mono); letter-spacing:0; text-transform:none; color:var(--muted); padding:2px 4px; border:none; text-align:center}
.hm td{width:24px; height:20px; text-align:center; padding:0; border:1px solid var(--paper)}
.h0{background:var(--bg); color:var(--muted)} .h1{background:var(--accent-soft); color:var(--accent)}
.h2{background:var(--warn-soft); color:var(--warn)} .h3{background:var(--warn); color:var(--paper); font-weight:500}
.h4{background:var(--hot); color:var(--on-hot); font-weight:500} .h5{background:var(--warn-soft); color:var(--warn)}
.hm-anahtar{display:flex; flex-wrap:wrap; gap:6px 16px; margin-top:10px; font:12px var(--mono); color:var(--muted)}
.hm-anahtar span{display:inline-flex; align-items:center; gap:6px}
.hm-anahtar i{display:inline-block; width:14px; height:14px; border-radius:2px}
@media (max-width:820px){
  .wrap{grid-template-columns:minmax(0,1fr); gap:18px}
  nav{position:static; max-height:none; flex-direction:row; flex-wrap:wrap}
  nav a{display:inline-flex; gap:6px} nav .lbl,nav .geri{width:100%}
  header.kapak,section{padding:18px 16px}
  section.devam.ek{margin-top:-18px}
}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
"""

sayfa = f"""<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>4. Adım: Simülasyon ve Doğrulama</title>
<meta name="description" content="Robot kol çalışmasının 4. adım raporu: benzetim, literatür sonucunun yeniden üretimi, yerçekimli DF, dijital ikiz, sistem tanılama ve Multibody 3B modeli.">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700&family=Source+Sans+3:ital,wght@0,400;0,600;1,400&family=JetBrains+Mono:wght@400;500&display=swap">
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
<nav aria-label="Rapor bölümleri">
  <a class="geri" href="defter.html">← Çalışma notu</a>
  <div class="lbl">4. adım raporu</div>
{nav}
</nav>
<main>
{govde.strip()}
</main>
</div>
</body>
</html>
"""
# kapağa bağlantılar
try:
    import pymupdf
    SAYFA = len(pymupdf.open(os.path.join(DEPO, "rapor", "adim4_simulasyon_ve_dogrulama.pdf")))
except Exception:
    SAYFA = None
ps = f"{SAYFA} sayfa, " if SAYFA else ""
sayfa = sayfa.replace("</header>", f"""  <div class="baglar"><a href="{PDF}">PDF sürümü ({ps}model dosyaları gömülü)</a><a href="{GH}/tree/main/simulasyon/simulink">Model dosyaları</a><a href="defter.html">Çalışma notuna dön</a></div>
</header>""", 1)
open(HEDEF, "w", encoding="utf-8", newline="\n").write(sayfa)
print(f"{HEDEF}: {len(sayfa)//1024} KB, {len(menu)} menü bölümü, {len(gorseller)} görsel + video")
