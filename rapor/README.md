# 4. adım raporu: simülasyon ve doğrulama

**PDF:** [adim4_simulasyon_ve_dogrulama.pdf](adim4_simulasyon_ve_dogrulama.pdf) (49 sayfa)

Çalışma planının 4. adımında yapılan bütün iş tek belgede:

1. Özet
2. Model, düzenekler ve kontrolcü
3. İlk benzetimler ve boyutsuz harita (`simulasyon/`)
4. Literatür sonucunun yeniden üretimi: Ghaffari ve Mohammadiasl 2013 (`simulasyon/4a_ghaffari/`)
5. Önerilen katkı: yerçekimli iki girişli DF
6. Boyutsuz oran ve kontrolcü eşlemesi
7. Rejim ayrımı
8. Düzenek seçenekleri ve sensör etkileri
9. Dijital ikiz: Simulink ve Simscape (`simulasyon/simulink/`)
10. Dijital ikizde sistem tanılama
11. Donanım deney protokolü
12–16. Eksikler, olmayanlar ve kök neden, sonraki adımlar, sorular, kaynaklar ve dosya dizini
- Ek A: Simulink tasarım ayrıntıları (blok ve parametre tabloları, çözücü ayarları, bütün MATLAB Function kodları)

**Gömülü dosyalar:** üç Simulink/Simscape modeli (`.slx`), onları kuran betikler, `blok_*.m`, `sim_param.m`, doğrulama betikleri ve `simulasyon/simulink/README.md` PDF'in içinde ek dosya olarak duruyor. Adobe Acrobat/Reader'da soldaki ataş (Ekler) panelinden açılır; tarayıcıların PDF görüntüleyicisi ekleri göstermez.

## Kaynak ve yeniden üretim

| Dosya | Ne |
|---|---|
| `rapor.html` | Raporun kaynağı (A4 baskı CSS'i, Google Fonts) |
| `img/` | Rapordaki görseller |
| `betikler/ust_uste.m` | Betik / Simulink / Simscape θ(t) karşılaştırmasının verisi (Bölüm 9) |
| `betikler/grafik.py` | Kritik kazanç–açı grafiği (Bölüm 5) ve θ(t) karşılaştırma grafiği |
| `betikler/slx_detay.m` | Model diyagramları, MATLAB Function kodları, blok/parametre listesi (Bölüm 9, Ek A) |
| `betikler/tanilama_sekil.m` | Bölüm 10'un kayıt grafikleri (yerel `tani_*_kayit.mat` dosyalarından; bunlar depoda yok) |
| `betikler/pdf_yap.py` | Model dosyalarını PDF'e gömer |

```bash
# 1) veriler ve görseller (MATLAB R2026b, Simscape, Simscape Electrical)
matlab -batch "addpath('rapor/betikler'); ust_uste('<çıkış>'); slx_detay('<çıkış>')"
python rapor/betikler/grafik.py <çıkış>          # matplotlib
# Ek B (Simscape Multibody): 3B model kareleri -> rapor/img/mb_3b_gorunum.png, mb_kareler.png
matlab -batch "addpath('simulasyon/simulink'); mb_kareler(5)"
# 2) HTML -> PDF (Chrome)
chrome --headless=new --no-pdf-header-footer --print-to-pdf=ham.pdf rapor/rapor.html
# 3) model dosyalarını göm (pymupdf)
python rapor/betikler/pdf_yap.py rapor/adim4_simulasyon_ve_dogrulama.pdf ham.pdf
```
