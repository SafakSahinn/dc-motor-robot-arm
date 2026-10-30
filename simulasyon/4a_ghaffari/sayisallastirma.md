# 4a Adım 2: Şekil 11 ve Tablo I'in sayısallaştırılması

Veri: [`veri_sekil11.csv`](veri_sekil11.csv), [`tablo1.csv`](tablo1.csv). Döner tabla, kse = 168,2 N·m/rad (bkz. [`parametreler.md`](parametreler.md)).

## Yöntem

- **Tablo I** metin olarak okundu; olduğu gibi aktarıldı.
- **Şekil 11:** PDF sayfası 300 dpi'de kesildi. Eksen çerçeveleri ve tik işaretleri piksel taramasıyla bulundu (11a: 5 Hz ≈ 74 px, 2 birim kp ≈ 103 px; 11b: 10 birim kv ≈ 154 px). İşaretler 6–7 px büyüklüğünde ve deney ile simülasyon işaretleri çoğu noktada üst üste biniyor; şekle göre ayırmak yerine bilinen kazanç değerlerinde dikey şeritte işaret kümelerinin merkezi ölçüldü.
- **Deney değeri** iki bağımsız yoldan kestirildi: (i) alt kümenin merkezi (deney ve simülasyonun ortalaması kabul edilip e_se ile ayrıldı), (ii) üst küme (DF) ÷ (1 + e_te). İki kestirim her noktada ±0,15 Hz içinde; tabloya ortalaması yazıldı. Deney ve simülasyonun ayrı ayrı okunabildiği iki noktada (kp = 15, kv = 50) oran Tablo I ile tutarlı (+%6,2 / +%5,5 ve +%7,4 / +%7).
- **Düşük kazançtaki teori noktaları** (DF ve sürtünmesiz simülasyon, salınımın başladığı bölge) ince çizgiler üzerinde, gözle ±0,3 Hz doğrulukla okundu.

## Gözlemler

1. **Şekildeki "DF" eğrisi denklem 12 değil, tam DF çözümü.** kp = 11,7, kv = 20 için denklem 12 √(kp·kv/Jle) = 18,0 Hz veriyor; şekildeki DF değeri 13,1 Hz. Şekildeki ωcr/ωa = 0,7 etiketi de (kp = 10) aynı noktada r_gs = 1,1 ile yan yana. Adım 5'te G·H ile n(θd)'nin kesişimi sayısal olarak çözülecek; denklem 12 ayrıca raporlanacak.
2. **Sürtünme salınımın başladığı kazancı büyük ölçüde kaydırıyor.** DF ve sürtünmesiz simülasyon salınımı kp ≈ 6,2–6,7'de (r_gs ≈ 0,86–0,89) başlatıyor; deney ve sürtünmeli simülasyonda salınım kp = 10,2 (r_gs = 1,10) ile 11,7 (1,18) arasında başlıyor. kv taramasında da benzer: teori kv ≈ 2, deney kv = 17,5–20.
3. **"r_gs ≥ 1 kararsız" sınırı bu düzenekte tutmuyor.** Deneyde r_gs = 1,17–1,86 aralığında kararlı kalıcı çevrim var. Makale bunu yük tarafındaki Coulomb sürtünmeye bağlıyor ve akış şemasında r_gs yerine ωcr/ωa kullanılmasını öneriyor.
4. **Frekans ωa'ya ulaşmıyor.** Yüksek kazançta teori 15,3 Hz'e (ωa) doyuyor, deney ≈ 12,7–13,1 Hz'de kalıyor. Teori ile deney arasındaki sistematik fark (e_te ≈ %17–27) bu doymadan geliyor.
5. **Bu çalışma için anlamı:** salınımın başlangıcını sürtünme belirliyor (gözlem 2); bu çalışmadaki φ = F_C/(K_s·r) oranının sınır öngörüsüne girmesi gerektiğini doğruluyor. Yeniden üretimin başarı ölçütü olarak (i) sürtünmeli simülasyonun deneye uyumu (makale: ortalama %2,4 / %3,3), (ii) tam DF'nin deneye uyumu (makale: %19,6 / %21,4) ve (iii) salınım başlangıç kazancı birlikte kullanılacak.

## Sınırlar

- Rezonans bölgesindeki deney değerleri ≈ ±0,15 Hz, düşük kazançtaki teori noktaları ≈ ±0,3 Hz belirsizlikle okundu.
- Salınım başlangıcı yalnızca ölçülen kazanç noktaları arasında sınırlanabiliyor (ör. kp 10,2 ile 11,7 arası).
