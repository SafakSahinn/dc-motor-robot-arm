"""Düzenek seçenekleri haritalarını (secenekler_log.txt, sensor_7c_log.txt) sitedeki renkli
HTML tablolarına çevirir. Kullanım: python harita_html.py > harita_parca.html"""
import re
import sys

AD = {".": "denge", "s": "sönümlü titreşim", "Z": "zorlanmış cevap", "C": "kalıcı çevrim",
      "X": "kararsız", "?": "düzensiz"}
SINIF = {".": "h0", "s": "h1", "Z": "h2", "C": "h3", "X": "h4", "?": "h5"}


def bloklar(yol, desen):
    """'=== <başlık>' satırıyla başlayan blokları ve içlerindeki r_gs satırlarını döndürür."""
    sonuc, ad, aci = {}, None, None
    for satir in open(yol, encoding="utf-8"):
        m = re.match(desen, satir)
        if m:
            ad = m.group(1)
            sonuc[ad] = []
            continue
        if ad and "açı:" in satir:
            aci = satir.split("açı:")[1].split()
        m = re.match(r"\s+r_gs ([\d.]+):\s+(.*)", satir)
        if ad and m:
            sonuc[ad].append((m.group(1), m.group(2).split()))
    return sonuc, aci


def tablo(baslik, satirlar, aci):
    h = [f'<table class="hm"><caption>{baslik}</caption>',
         "<tr><th>r<sub>gs</sub> \\ açı</th>" + "".join(f"<th>{a}°</th>" for a in aci) + "</tr>"]
    for rg, hucreler in satirlar:
        tds = []
        for c in hucreler:
            k = c[0]
            yildiz = c.endswith("*")
            ipucu = AD[k] + (" (başlangıç koşuluna bağlı)" if yildiz else "")
            tds.append(f'<td class="{SINIF[k]}" title="{ipucu}">{k if k != "." else "·"}{"*" if yildiz else ""}</td>')
        h.append(f"<tr><th>{rg.replace('.', ',')}</th>" + "".join(tds) + "</tr>")
    h.append("</table>")
    return "\n".join(h)


BASLIK = {"A": "A · R 0,17", "B1": "B1 · R 1, dengeli ek", "B2": "B2 · R 2, dengeli ek",
          "C": "C · 1:10 dişli", "D": "D · R 1, ağır uç"}


def parca():
    """İki ızgara: beş düzeneğin ideal haritaları; A ve D için sensör + sürtünme (kenar zamanlamalı hız)."""
    sen, aci = bloklar("sensor_7c_log.txt", r"=== (\w+, \w+)")
    out = ['<div class="hm-izgara">']
    out += [tablo(BASLIK[a], sen[f"{a}, ideal"], aci) for a in ["A", "B1", "B2", "C", "D"]]
    out.append("</div>")
    gercek = ['<div class="hm-izgara">']
    gercek += [tablo(f"{BASLIK[a]} · sensör + sürtünme", sen[f"{a}, kenar_g"], aci) for a in ["A", "D"]]
    gercek.append("</div>")
    return "\n".join(out), "\n".join(gercek)


if __name__ == "__main__":
    a, b = parca()
    print(a)
    print(b)
