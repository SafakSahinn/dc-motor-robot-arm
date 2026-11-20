# Birleşik raporun PDF'ini üretir.
#  1. rapor.html'deki Ek B yer tutucularına betiklerin ve logun metnini koyar (_baski.html, geçici)
#  2. Edge headless ile PDF'e basar
#  3. Betikleri PDF'e gömülü dosya olarak ekler (pymupdf)
# Kullanım: python pdf_yap.py   (çıktı: birlesik_rapor.pdf)
import html, os, subprocess, sys
import pymupdf
sys.stdout.reconfigure(encoding='utf-8')

KOK = os.path.dirname(os.path.abspath(__file__))
EDGE = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
GOMULU = ['bolum3_dogrusal.m', 'bolum3_dogrusal_log.txt', 'sekil_5_6.py']

def metin(ad):
    return html.escape(open(os.path.join(KOK, ad), encoding='utf-8').read().rstrip('\n'))

s = open(os.path.join(KOK, 'rapor.html'), encoding='utf-8').read()
for yer, ad in [('<!--EK_B_KOD-->', 'bolum3_dogrusal.m'), ('<!--EK_B_LOG-->', 'bolum3_dogrusal_log.txt'),
                ('<!--EK_B_PY-->', 'sekil_5_6.py')]:
    assert yer in s, yer
    s = s.replace(yer, metin(ad))
gecici = os.path.join(KOK, '_baski.html')
open(gecici, 'w', encoding='utf-8').write(s)

ham = os.path.join(KOK, '_ham.pdf')
subprocess.run([EDGE, '--headless', '--disable-gpu', '--no-pdf-header-footer', '--virtual-time-budget=15000',
                '--print-to-pdf=' + ham, 'file:///' + gecici.replace('\\', '/')], check=True,
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

cikti = os.path.join(KOK, 'birlesik_rapor.pdf')
d = pymupdf.open(ham)
for ad in GOMULU:
    d.embfile_add(ad, open(os.path.join(KOK, ad), 'rb').read(), filename=ad, desc='Birleşik rapor, Ek B')
d.save(cikti, garbage=3, deflate=True)
d.close()
os.remove(ham); os.remove(gecici)
d = pymupdf.open(cikti)
print('sayfa', len(d), 'ek', d.embfile_count(), os.path.getsize(cikti)//1024, 'KB')
print('kısa sayfalar:', [(p.number + 1, len(p.get_text())) for p in d if len(p.get_text()) < 300])
