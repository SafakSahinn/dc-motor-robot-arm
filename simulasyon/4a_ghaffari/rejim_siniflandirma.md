# 4a Adım 6: Rejim sınıflandırıcısı

Kod: [`rejim_sinifla.m`](rejim_sinifla.m) (sınıflandırıcı), [`rejim_testleri.m`](rejim_testleri.m) (doğrulama). Kayıt: [`rejim_testleri_log.txt`](rejim_testleri_log.txt).

Amaç: benzetimde ve deneyde aynı zaman serisinden (yük açısının hedeften sapması; deneyde AS5600'ün ölçtüğü büyüklük) sönümlü titreşim, zorlanmış cevap, kalıcı çevrim ve kararsızlığı aynı ölçütlerle ayırmak.

## Ölçütler

Sinyal ortalamasının iki yanındaki ardışık geçişler arası **yarım periyotlara** bölünür; her yarım periyottan bir genlik a_i ve bir süre alınır.

| Büyüklük | Tanım | Ne işe yarar |
|---|---|---|
| A | son çeyrekte yarım tepeden tepeye | salınım var mı (A ≥ A_min) |
| Zarf değişimi | ln a_i'nin zamana göre eğimi × analiz penceresi (son yarı) | büyüyor / sabit / küçülüyor |
| Büyüme yavaşlaması | 3. ve 4. çeyrekteki eğimler | üstel büyüme mi, çevrime yaklaşma mı |
| cv_T, cv_A | yarım periyot sürelerinin ve genliklerinin değişim katsayısı | periyodik mi |
| Zorlama payı | gücün zorlama frekansı ve ilk 5 harmoniği çevresindeki payı (Hann pencereli FFT) | salınım dışarıdan mı geliyor |

## Karar sırası

| Sınıf | Koşul |
|---|---|
| 4 kararsız | A > A_max, ya da zarf değişimi > %5 ve büyüme yavaşlamıyor (4. çeyrek eğimi ≥ 3. çeyreğin yarısı) |
| 0 denge | A < A_min ve başlangıçta A_min'i aşan yarım periyot sayısı < 2 (salınımsız dönüş ya da boşluk içinde duruş) |
| 1 sönümlü titreşim | A < A_min ama başlangıçta ≥ 2 yarım periyot A_min'in üstünde; ya da zarf değişimi < −%5 |
| 2 zorlanmış cevap | zorlama varsa ve gücün ≥ %80'i zorlama frekansı ve harmoniklerinde |
| 3 kalıcı çevrim | zarf sabit (ya da yavaşlayarak büyüyor: "yakınsıyor"), cv_T < 0,1 ve cv_A < 0,1 |
| 5 düzensiz | sürüyor, zarf sabit, periyodik değil |

- **A_min** ölçüm eşiği: benzetimde boşluğun %10'u, deneyde AS5600 çözünürlüğüne göre seçilecek. A_min'in altındaki titreşim "yok" sayılır, çünkü deneyde de görülemez.
- **Başlangıç koşulu:** her nokta birden fazla başlangıç sapmasıyla koşulur (testlerde 0,05°, 0,5°, 2°). Sınıflar farklı çıkarsa nokta "başlangıç koşuluna bağlı" diye işaretlenir. Çarpma rejiminde kalıcı çevrim ile boşluk içi denge birlikte var olabiliyor (Adım 4).

## Doğrulama

| Durum | Beklenen | Sonuç (0,05° / 0,5° / 2°) |
|---|---|---|
| Döner tabla, kp = 3,8 | denge | denge / denge / denge |
| Boşluksuz, kp = 8,3 | sönümlü titreşim | denge¹ / sönümlü / sönümlü |
| Boşluksuz + 3 Hz yük bozucusu | zorlanmış cevap | zorlanmış (3 Hz) × 3 |
| Şekil 7 (kalibre) | kalıcı çevrim | kalıcı çevrim (10,1 Hz) × 3; 0,05°'de "yakınsıyor" |
| Döner tabla, kp = 15, Tmax 360 | kalıcı çevrim | kalıcı çevrim (12,6 Hz) × 3 |
| Döner tabla, sürtünmesiz, kp = 18,3 | kararsız | kararsız × 3 |
| Şekil 8 (kalibre) | kalıcı çevrim | kalıcı çevrim / kalıcı çevrim / **denge²** |

¹ 0,05° başlangıçta ilk sapmadan sonraki aşma eşiğin (0,005°) altında: titreşim ölçülebilir değil, "denge" doğru.
² Gerçek birlikte var olma: büyük başlangıç sapmasında sistem boşluğun içinde duruyor.

Testlerin ilk sürümünde iki hata görüldü ve düzeltildi: (i) sönüm başlangıç geçişinde olduğu için ilk genlik, baştan atılan bölüm (T_at) kesilmeden ölçülmeli; (ii) çevrime yavaşça yaklaşan salınım (Şekil 7, küçük başlangıç) zarf büyümesi yüzünden "kararsız" çıkıyordu; üstel büyümeyi doyan büyümeden ayırmak için son iki çeyreğin eğimleri karşılaştırılıyor.

## Deneyde kullanım

- Aynı fonksiyon deney kayıtlarına doğrudan uygulanır (t, θ_kol − θ_hedef).
- Deneyde zorlama yalnız bilinçli olarak verildiğinde (f_z) aranır; tabandaki titreşim kaynakları (motor dişli kademesi, PWM) için ayrıca spektrum kontrolü gerekebilir.
- Sınıflandırma açı × kazanç taramasında her noktaya otomatik uygulanır (mimari.md, 4.2).

## Ek: yerçekimli düzenekte zorlanmış cevap ve iki kararlılık

Kod: [`zorlanmis_cevap.m`](zorlanmis_cevap.m). Kayıt: [`zorlanmis_cevap_log.txt`](zorlanmis_cevap_log.txt). Düzenek D (R = 1, mgℓ = 0,24 N·m, γ(90°) = 0,92), P–PI, kola sinüs yük bozucusu `p.dA sin(2π p.df t)` (`kol_benzetim`, isteğe bağlı `p.dT`'de kesilir).

| Durum | r_gs | Bozucu | Sınıf | Genlik | f | Boşlukta geçen süre |
|---|---|---|---|---|---|---|
| 90°, küçük bozucu | 0,6 | 0,03 N·m, 3 Hz | zorlanmış cevap | 0,35° | 3,00 Hz | %0 |
| 90°, ön yükü aşan bozucu | 0,6 | 0,30 N·m, 3 Hz | zorlanmış cevap | 8,3° | 3,00 Hz | %13 |
| 0°, küçük bozucu | 0,6 | 0,03 N·m, 3 Hz | zorlanmış cevap | 2,4° | 3,00 Hz | %61 |
| 0°, bozucusuz | 0,6 | yok | sönümlü titreşim | 0,18° | 1,30 Hz | %100 |
| 0°, güçlü çevrim + bozucu | 0,9 | 0,03 N·m, 4,5 Hz | **kalıcı çevrim** | 5,2° | 6,43 Hz | %26 |
| 0°, aynı, bozucu 3 Hz | 0,9 | 0,03 N·m, 3 Hz | zorlanmış cevap³ | 5,3° | 6,43 Hz | %26 |

³ Çevrim frekansı (6,43 Hz) bozucunun 2. harmoniğine (6 Hz) yakın olduğu için güç harmonik bandına sayılıyor. Zorlama frekansı çevrimin harmoniklerinden uzak seçilmeli; deneyde zorlama frekansı buna göre planlanır.

- 90°'de yerçekimi ön yükü küçük bozucuda temasın kopmasını önlüyor: cevap doğrusal ve yalnız zorlama frekansında. Bozucu ön yükü aşınca temas kopuyor, cevap yine zorlama frekansında ama genliği büyüyor.
- 0°'de kol, küçük başlangıç sapmasında boşluğun içinde sarkaç gibi asılı kalıyor (1,3 Hz, temas yok); bozucu dişleri temasa getirince r_gs 0,6'da salınım bozucuya kilitleniyor, r_gs 0,9'da kendi frekansında (6,43 Hz) çevrim sürüyor.

**İki kararlılık (yerçekimli DF'nin öngörüsü):** 90°, tork sınırsız; bozucu DF'nin çevrim frekansında 3 s uygulanıp kesiliyor, sınıf t > 4 s'den.

| r_gs | DF | Bozucu 0 / 0,02 / 0,05 / 0,10 / 0,20 / 0,40 N·m |
|---|---|---|
| 0,88 | çevrim, 6,60 Hz | hepsi sönüyor (bu kazançta benzetimde çevrim yok: DF'nin kazanç hatası) |
| 0,95 | çevrim, 7,12 Hz | sönüyor / sönüyor / sönüyor / **çevrim 7,08 Hz** / çevrim / çevrim |
| 1,00 | çevrim, 7,48 Hz | çevrim 7,48 Hz / sönüyor / çevrim / çevrim / çevrim / çevrim |

r_gs 0,95'te denge küçük sarsıntıya karşı kararlı, 0,10 N·m'lik sarsıntı kalıcı çevrimi başlatıyor; çevrim frekansı DF'ninkiyle %0,6 farklı. Benzetim haritalarındaki "başlangıç koşuluna bağlı" (`*`) noktaların açıklaması bu. Deney için sonuç: her noktada küçük ve büyük sarsıntılı iki ölçüm gerekir; sınır "salınım başlatılabilir" ve "kendiliğinden başlar" diye iki eğri olarak raporlanmalı.
