# 4a Adım 5: Döner tabla taraması (Şekil 11, Tablo I)

Kod: [`ghaffari_tabla.m`](ghaffari_tabla.m) (tarama, karşılaştırma, çizim), [`ghaffari_df.m`](ghaffari_df.m) (tam DF). Kayıt: [`tabla_log.txt`](tabla_log.txt), [`tabla_sonuclar.mat`](tabla_sonuclar.mat). Çizim: [`tabla_karsilastirma.png`](tabla_karsilastirma.png). Makaledeki şekil: [`sekiller/sekil11_frekans_kazanc.png`](sekiller/sekil11_frekans_kazanc.png).

## Yöntem

- **Benzetim:** döner tabla parametreleri (Ek), kp taraması (kv = 20) ve kv taraması (kp = 11,6); makalenin sürtünmeleriyle ve sürtünmesiz. Her kazanç üç başlangıç sapmasıyla (0,05°, 1°, 3°) koşuldu; frekans, salınım bulunan koşuların en büyüğü. Deneyde salınım hız basamağıyla, yani büyük bir uyarımla başlatılıyor.
- **Tam DF:** n(θd) gerçel olduğundan çevrim frekansı G(jω)H(jω)'nin −180° faz geçişi; n = −1/Re{GH}. Re{GH} ≥ −1 ise n = 1'de bile döngü kararsız: makaledeki gibi "mekanik rezonans", frekans ωa.
- **Temas sönümü:** ξ = 0. ξ = 0,02 ile sürtünmesiz benzetim makalenin sürtünmesiz benzetiminden ≈ %20 düşük frekans verdi; ξ = 0 ile örtüştü.

## Sonuç

| | Bu çalışma, ortalama mutlak hata (11a / 11b) | Makale, Tablo I (11a / 11b) | Durum |
|---|---|---|---|
| Tam DF − deney | %20,2 / %22,1 | %19,6 / %21,4 | **üretildi** |
| Denklem 12 − deney | %65 / %88 | — | (denklem 12 yalnız rezonans yakınında yaklaşık) |
| Sürtünmesiz benzetim − makalenin sürtünmesiz benzetimi | kp 6,7–18,3: ≤ 0,2 Hz (en büyük fark kp = 6,7'de 4,18 / 4,0 Hz) | — | **üretildi** |
| Sürtünmeli benzetim − deney | %18,3 / %19,5 | %2,4 / %3,3 | **üretilemedi** |

DF frekansları noktası noktasına aynı: kp = 6,7 / 8,3 / 10 / 11,7 / 13,3 için 6,03 / 8,99 / 11,31 / 13,23 / 14,81 Hz (makale 6,0 / 9,0 / 11,3 / 13,1 / 14,8).

## Sürtünmeli benzetim neden tutmuyor?

- **Salınım başlangıcı tutuyor:** bu model kp = 10'da (r_gs = 1,09), deney 10,2 ile 11,7 arasında; kv taramasında model 15, deney 17,5 ile 20 arası. Sürtünmenin başlangıcı yukarı kaydırması (sürtünmesiz ≈ 5,8) nitel olarak üretildi.
- **Yüksek kazançta doyma tutmuyor:** deney ve makalenin sürtünmeli benzetimi ≈ 13 Hz'de kararlı bir çevrimde kalıyor; bu model ωa'ya (15,3 Hz) gidiyor ve genlik büyüyor. Nedeni yapısal: kp ≥ 15'te Re{GH} ≥ −1, yani doğrusal kısım kararsız; Coulomb sürtünmesi sabit büyüklükte bir tork olduğundan üstel büyümeyi sınırlayamaz. Makalenin sürtünmeli modeli genliği bir şekilde sınırlıyor, ama makale bunu sağlayan unsuru vermiyor: benzetimin "deneysel servo izlerinden (2000 nokta, 4 ms) modellendiğini" ve sürtünmelerin "optimize edildiğini" söylüyor. Olası eksikler: tork sınırı, örnekleme ve akım döngüsü gecikmesi, farklı bir sürtünme modeli. Bunları ayırt edecek veri makalede yok.
- **Kazanç noktalarının bir kısmında makalenin sürtünmesiz eğrisi 0 gösteriyor** (kp = 5,8 ve 6,2; kv = 1,5), bu model ve tam DF küçük genlikli (≈ δ) bir çevrim buluyor. Makale bu genlikteki çözümleri saymamış olabilir.

## Ek deneme: motor tork sınırı

Kod: [`tork_siniri.m`](tork_siniri.m); kayıtlar: [`tork_siniri_log.txt`](tork_siniri_log.txt) (5–640 N·m), [`tork_siniri_log_ince.txt`](tork_siniri_log_ince.txt) (240–480 N·m). Motor torku ±Tmax ile sınırlandı, doyumda integral durduruldu; sürtünmeler makaledeki gibi, başlangıç sapması 1° ve 3°.

| Tmax [N·m] | ∞ | 640 | 480 | 400 | **360** | 320 | 280 | 240 | 160 | 80 | ≤ 40 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hata 11a [%] | 18,3 | 8,7 | 5,8 | 4,0 | **3,9** | 4,0 | 4,8 | 6,6 | 15,2 | 34,7 | salınım yok |
| Hata 11b [%] | 19,5 | 9,9 | 6,8 | 4,5 | **3,9** | 4,6 | 5,0 | 6,0 | 15,5 | 36,8 | salınım yok |

Tmax = 360 N·m'de kp = 11,7 / 13,3 / 15 / 16,7 / 18,3 için 12,16 / 12,44 / 12,59 / 12,72 / 12,84 Hz (deney 10,94 / 12,02 / 12,50 / 13,04 / 13,06). İlk nokta +%11, diğerleri %3 içinde.

- **Doymayı tork sınırı açıklıyor.** Sınırsız modelde kalıcı çevrim kp = 11,7'de bile yüzlerce N·m tepe tork istiyor; sınır genliği kısıtlıyor, frekans ωa'nın altında bir değerde doyuyor. Hata makalenin sürtünmeli benzetimine (%2,4 / %3,3) yaklaştı.
- **Sınır çok düşükse salınım tamamen kayboluyor** (≤ 40 N·m): motor sürtünmeyi (6 + 2 N·m) yenmenin ötesinde tork üretemiyor.
- **Uyarılar:** (i) Tmax aynı deney verisine ayarlanmış tek bir parametre, yani bir öngörü değil; (ii) 360 N·m'nin 1FT6108-8AB71 motorunun gerçek tepe torkuyla uyumu doğrulanmadı (makale vermiyor; katalog değeriyle karşılaştırılmalı); (iii) kv = 17,5'te model salınıyor (10,3 Hz), deney salınmıyor: salınım başlangıcı kv ekseninde hâlâ ≈ 2,5 birim erken.
- Sonuç: makalenin sürtünmeli modelinde büyük olasılıkla bir tork (ya da akım) sınırı var. Bu çalışmanın düzeneğinde DRV8874'ün akım sınırı aynı rolü oynayacak; deneyde ve modelde bu sınır ölçülüp aynı değer kullanılmalı.

## Bu çalışma için anlamı

1. Ghaffari'nin analitik çerçevesi (Şekil 4 modeli, tek döngü dönüşümü, tam DF) bu kodla birebir üretiliyor; genişletme (yerçekimli kayma) bu kodun üzerine kurulabilir.
2. Makalenin %2–3'lük benzetim–deney uyumu deneysel izlere ayarlanmış, ayrıntısı verilmemiş bir modele dayanıyor; bu çalışmada aynı uyumu iddia etmek için sürtünme ve sürücü sınırları kendi düzeneğimizde tanılanmalı (kalibrasyon adımları, mimari.md).
3. Başarı ölçütü B1'in referansı (Ghaffari DF hatası ≈ %20) bu çalışmada yeniden üretilmiş bir sayı.
4. Sürtünme hem salınımın başladığı kazancı hem de başlangıç koşuluna bağlılığı belirliyor: φ = F_C/(K_s·r) sınır öngörüsünde ayrı bir eksen olmalı.
