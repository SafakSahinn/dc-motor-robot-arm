# Framing, kapsam ve kısıtlar

Çalışma notunun 1. aşaması. **Güncel çerçeve: 0. bölüm, "GÜNCEL ÇERÇEVE KARARI (5 Kasım 2026 akşam)" alt bölümü: motor tarafı döngü + ofset tablosu + 180° çevresinde yalnız motor sinyalleriyle yüz kestirimi (ana katkı).** 0. bölümün geri kalanı (açıya göre kazanç planlaması) bu kararla arşive geçti. 1–8. bölümler ilk çerçevedir (24 Ekim): sınır öngörüsü analizi artık amacın kendisi değil, 1. bileşenin aracıdır ve bu yüzden geçerliliğini korur.

İlk çerçevenin seçimi ve gerekçesi: `framing_adaylari.md`. Literatür: `../literatur/son_tarama_2026-10-24.md` (ilk çerçeve), `../literatur/kontrol_taramasi/hedefli_tarama_2026-11-05.md` ve `../literatur/okuma_notlari.md` (güncel çerçeve).

## 0. Çerçeve güncellemesi (5 Kasım 2026): analizden tasarıma

### Neden değişti

İlk çerçeve salınım sınırını **öngörüyordu**. Danışmanla yapılan değerlendirmede, sınırı bilmenin asıl değerinin onu **kullanmak** olduğu sonucuna varıldı: sınır biliniyorsa kontrolcü, kolun hangi açıda olduğuna göre önceden ayarlanıp salınım hiç başlatılmayabilir. Ağırlık analizden tasarıma kaydı. DF + dijital ikiz analizi (4a–4b, 6. ve 7. bölümler) atılmadı; ayar tablosunu üreten araç oldu.

### Güncel ana soru

Yerçekimi etkisindeki tek motorlu, dişli boşluklu bir eklemde, kontrolcü kazancı ve gözlemci bant genişliği yerçekimi ön yükünün açıya bağlı değerine (mgℓ·sin θ₀) göre önceden planlanırsa, boşluk kaynaklı kendiliğinden salınım tüm çalışma açılarında, yük tarafı sensörü olmadan, sabit kazançlı en iyi ayardan daha iyi bir tepki hızıyla önlenebilir mi?

### Üç bileşen

| # | Bileşen | Rolü | Durum |
|---|---|---|---|
| 1 | **Açıya göre önceden planlanan kontrolcü ve gözlemci.** Kazanç ve DOB/ESO bant genişliği, θ₀'daki yerçekimi ön yüküne göre bir tablodan seçilir. Tablo, DF haritasından türetilir ve dijital ikizde doğrulanır. | Ana katkı | Literatürde doğrudan rakip bulunmadı (aşağıda) |
| 2 | **Yalnız motor tarafı sinyallerle salınım başlangıcı tespiti** (motor akımı + enkoder, yük tarafı sensörü yok). Planlama kaçırırsa (model hatası, aşınma) emniyet ağı. | Destek | Çok öncülü var, tek başına yeni değil; sabit hedefte kendiliğinden başlayan LC'nin tespiti olarak konumlanır |
| 3 | **ESP32 üzerinde 1 kHz gömülü gerçekleme.** | Uygulama | — |

AS5600 kol açısı sensörü düzenekte kalır ama **yalnız doğrulama için** kullanılır; kontrolcü onu görmez.

### Sensör kararı: θ_d ölçülür mü, kestirilir mi? (5 Kasım 2026)

180° için seçilen önlem **boşluk telafisi**: kontrolcü motor ile kol arasındaki açı farkını (θ_d = θ_M/N − θ_L) izler, tork yönü değişmesi gerektiğinde motoru boşluğun öbür yüzüne hızla atlatır, kolun serbest kaldığı süreyi kısaltır. Bunun için θ_d gerekir. Seçenekler:

| Yol | θ_d nereden gelir | Artısı | Eksisi |
|---|---|---|---|
| (i) Ölçmek | AS5600 + motor enkoderi | Kolay, doğrudan | "Kol sensörü yok" iddiası ve H6 düşer; motor enkoderi kol tarafında 0,27°, 3° boşluk ≈ 11 adım |
| (ii) Kestirmek | Yalnız motor akımı + enkoder (gözlemci: temas varken dişli torku ≠ 0, boşlukta ≈ 0) | Katkısı büyük; bileşen 2, H6, Dai 2026 ve Ruderman–Iwasaki 2016 ile uyumlu | Zor; kestirim hatası telafiyi bozabilir |
| **Ara yol (seçildi)** | İkizde önce (i), sonra (ii) | (i) üst sınır olur: θ_d'yi kusursuz bilsek bile telafi 180°'yi düzeltmiyorsa (ii)'ye hiç girilmez; düzeltiyorsa (ii)'nin kaybı (i)'ye göre ölçülür | Bir adım fazla iş |

**Neden ara yol:** zor işe (kestirim) girmeden önce fikrin kendisi ucuzca sınanıyor, son kontrolcünün "kol sensörü yok" iddiası korunuyor. (i) yalnız ikizde ve deneyde **referans** olarak kalır, son kontrolcüye girmez.

**Bununla gelen ikinci karar: konum döngüsü motor tarafına.** Bugüne kadarki ikiz konum hatasını kol açısından hesaplıyordu (`kol_benzetim.m`, `thm = olc(x(3,:), p.qL)`); bu, "kontrolcü kolu görmez" ilkesiyle çelişiyordu. Kontrolcü kolu görmeyecekse konum hatası da θ_M/N'den hesaplanmalı. Bu, 180° sorununu değiştirebilir (kol boşlukta devrilirken kontrolcü tepki vermez, ama kol hedefte değil boşluğun bir ucunda durur, ≤ ±b/2 kalıcı hata). `kol_benzetim.m`'ye varsayılanı kapalı bir seçenek eklenip `inceleme_180.m` bu ayarla yeniden çalıştırılacak; telafi bunun üzerine tasarlanacak.

**İlk sonuç (5 Kasım 2026, `../simulasyon/5_planlama/inceleme_180_motor.m`, `konum_kaynagi_karsilastir.m`): konum döngüsü motor tarafına alınınca boşluk salınımı ikizde kayboluyor, yerine kalıcı hata geliyor.** P–PI, 0–180° × r_gs 0,20–0,70, başlangıç 1°:

| Konum kaynağı | Salınımlı hücre | Kolun kalıcı hatası |
|---|---|---|
| Kol (eski, ideal) | 10 / 114 (hepsi 0° ve 180°'de) | ≈ 0 (en çok 0,27°) |
| Motor (ideal) | 0 / 114 | ort. 2,25°, en çok 2,89° (90°'de) |
| Motor (0,27° nicemli enkoder) | 3 / 114 (yalnız r_gs 0,20'de küçük düzensiz) | ort. 2,16°, en çok 2,88° |

`inceleme_180_motor.m`: 180°'de r_gs 0,15–0,70 ve üç başlangıcın hepsinde salınım yok (eskiden yalnız ≈ 0,15). Kalıcı hata öngörülebilir: ≈ r + m g l sin θ / K_s (boşluğun yarısı + dişli esnemesi), 0°'de ≈ 0 (yerçekimi kolu boşluğun ortasında tutuyor), 180°'de −1,5° (kol bir yüze devrilip dayanıyor). Yorum: boşluk geri besleme döngüsünün **dışında** kalınca çevrim oluşmuyor; bu, boşluk literatüründe bilinen bir ödünleşim (yük tarafı geri besleme → doğruluk ama LC riski; motor tarafı → kararlılık ama boşluk kadar hata).

**Önemli tutarsızlık:** sitedeki "3,5× daha hızlı" ve "10–170° salınımsız" sonuçları kol tarafı geri beslemeyle (kontrolcü AS5600'ü görürken) elde edildi; "0 kol tarafı sensörü" iddiası o sonuçlar için geçerli değildi.

**Ofset tablosu denendi (5 Kasım 2026, `../simulasyon/5_planlama/ofset_tablosu.m`).** Motor tarafı P–PI, motor hedefi φ_ref = θ_ref + sign(sin θ_ref)·r + m g l sin θ_ref / K_s (`kol_benzetim.m`, `p.ofset`). 0–180° × r_gs 0,3/0,5/0,7, 63 hücre, hiçbirinde salınım yok:

| Tablo | 10–170° kalıcı hata (ort / en çok) | 180° |
|---|---|---|
| Ofsetsiz | 2,43° / 2,88° | −1,54° |
| Tam model, ideal enkoder | 0,000° / 0,000° | **+3,07°** |
| Tam model, 0,27° enkoder | 0,13° / 0,27° (bir enkoder adımı) | +3,21° |
| r %20 yanlış | 0,30° / 0,31° (hata ≈ Δr, sabit) | +3,38° ya da −0,31° |
| K_s %20 yanlış | 0,15–0,23° / 0,23–0,34° (90°'de en büyük) | +3,07° |

- 0°, 5° ve 175° de düzeliyor; 0°'de ofsete hiç gerek yok (kol boşluğun ortasında kalıyor).
- **180° tek açık nokta:** ön yük sıfır, kolun hangi yüze devrileceği dinamiğe bağlı. Tablo yanlış yüzü varsayınca hata 2r ≈ 3° oluyor, yani ofsetsizden kötü. Burada kolun hangi yüze yaslandığını bilmek (θ_d'nin işareti) gerçekten gerekli; θ_d kestirimi için tek ama somut kullanım yeri.
- Doğruluğu tanılama belirliyor: r hatası doğrudan, K_s hatası sin θ ile ölçekli olarak kalıcı hataya geçiyor. Bu yüzden r ve K_s'nin motor sinyallerinden çevrim içi tanılanması doğal bir sonraki adım.
- Henüz sınanmadı: sürtünmeli durumda motor tarafı geri besleme + ofset; yük değişimi (m g l bilinmiyorsa).

**Açık karar (kullanıcıya ait):** çerçeve bu bulguya göre yeniden düşünülmeli. Kazanç planlaması boşluk LC'sini önlemek için gerekçelendirilmişti; motor tarafı geri beslemede bu salınım ikizde zaten yok. Seçenekler kullanıcıya metinle sunuldu.

**Geri dönüş noktası:** (ii) beklenenden çok zor ya da telafiyi bozacak kadar hatalı çıkarsa (i)'e dönülebilir; o zaman çerçeve "kol sensörlü telafi" olur, H6 ve "kol sensörü yok" iddiası düşer. Konum döngüsü motor tarafında 0–170°'deki başarıyı bozarsa kol tarafı geri beslemeye dönülür ve bu fark yazıda açıkça belirtilir.

### Kapsam kararı: boşluk kaynaklı salınım

Armstrong ve Amin (1996, *Automatica*) şunu kanıtlıyor: statik sürtünme (yapışma) varsa, integral etkili bir konum kontrolcüsünde (PID ya da eşdeğer integral etkisi taşıyan ESO/DOB) yapışma–kayma salınımı, **kararlılığı sağlayan her kazanç ayarında** olası bir harekettir; DF de bunu güvenilir öngöremez. Dolayısıyla:

- Ana katkı **boşluk kaynaklı** salınıma odaklanır. Bu salınımın sınırı açıya bağlıdır (yerçekimi ön yükü) ve planlamayla önlenebilir.
- **Sürtünme kaynaklı** yapışma–kayma salınımı kazanç planlamasıyla giderilmeye çalışılmaz. Bunun için bilinen bir önlem (integratör ölü bandı ya da integratör sıfırlama) ayrı bir katman olarak konur ve her iki kontrolcüde de (sabit ve planlanan) aynı tutulur. Böylece karşılaştırma adil kalır.
- İlk çerçevedeki **L bileşeni** (açı taramasıyla kaynak ayrıştırma) bu yüzden daha da önemli: deneyde görülen salınımın boşluktan mı sürtünmeden mi geldiği ayırt edilmeden planlamanın başarısı ölçülemez.

### Açı aralığı: 0–180° dahil (5 Kasım 2026 kararı)

İlk kazanç tablosu dijital ikizde 10–170°'de salınımsız çalıştı (`../simulasyon/5_planlama/tablo_ilk.m`). Tam 180°'de (kol dik yukarı) ise ön gerilim sıfır ve denge kararsız; orada r_gs ≥ 0,20 her kazançta salınım var, yalnız ≈ 0,15'te dar bir pencere kalıyor (`inceleme_180.m`). 5° ötede (175°) kol 0,55'e kadar sakin. **Karar: 0° ve 180° kapsamda kalıyor.** 180° için planlamaya ek bir önlem araştırılacak (ilk aday: integratör ölü bandı ya da sıfırlama; sürtünme katmanıyla aynı mekanizma). Önlem bulunamazsa 180° "yöntemin sınırı" olarak raporlanır.

**İlk önlem denendi, 180°'de işe yaramadı (5 Kasım 2026, `../simulasyon/5_planlama/olu_bant_180.m`, `tablo_surtunme.m`).** `kol_benzetim.m`'ye varsayılanı kapalı iki seçenek eklendi: `p.Iolu` (|e| < Iolu iken integral donar) ve `p.Isifirla` (hata işaret değiştirince z = 0). Sonuçlar:
- **180°:** ölü bant (0,25 / 0,5 / 1,0°) ve sıfırlama, sürtünmeli ya da sürtünmesiz, salınımsız pencereyi genişletmedi; ölü bant sürtünmesiz durumda tek sakin kazancı (0,15) da kaybettirdi. Yorum: 180°'deki salınım integral birikmesinden değil, kolun boşluk içinde serbestken yerçekimiyle devrilmesinden (ters sarkaç + ölü bölge) doğuyor; integratöre dokunan bir önlem bu mekanizmaya ulaşmıyor. 175°'nin 0,55'e kadar sakin olması, birkaç derecelik yerçekimi ön yükünün yettiğini gösteriyor.
- **Sürtünme (Fc 0,04, Fs 0,06 N m):** katmansız tabloda 10–170°'nin 12 açısında, sabit ayarda 18 açıda küçük düzensiz salınım (yapışma–kayma avlanması; genlik plan 0,03–0,08°, sabit 0,06–0,17°, yani AS5600'ün 1–2 basamağı) çıktı. 0,25° ölü bantla plan 4 açıya iniyor (150–180°), kalıcı hata ≤ 0,31°, yerleşme ortancası değişmiyor (0,91 s; sabit 3,56 s). Sabit ayarda ölü bant avlanmayı gidermiyor. 90°'de sürtünmeli tarama (r_gs 0,10–0,70): katmansız 3 sakin kazanç, 0,25° ölü bantla 8.
- **Sıfırlama** sürtünmeli 90°'de zararlı (0 sakin kazanç): orada kolu yerçekimine karşı tutan integralin kendisi.
- **Karar (5 Kasım 2026):** 180° için asıl önlem θ_d tabanlı **boşluk telafisi** (yukarıdaki sensör kararı). Hedefi birkaç derece kaydırıp yerçekimine ön yük yaptırmak, isteğe bağlı hızlı bir ön deneme olarak kalıyor. İkisi de tutmazsa 180° "yöntemin sınırı" olarak raporlanır.

### Ek hipotezler

- **H5.** Açıya göre planlanan kontrolcü, 0–180° aralığının tamamında boşluk kaynaklı salınım üretmez ve ortalama yerleşme süresi, aynı aralıkta salınımsız kalan en iyi sabit kazançlı ayara göre kısadır (sabit ayar en kötü açıya, yani 0° ve 180° civarına göre seçilmek zorunda olduğu için yavaştır).
- **H6.** Salınım başlangıcı yalnız motor akımı ve enkoderle, yük tarafı sensörüne göre birkaç salınım periyodu içinde tespit edilebilir.

### Ek başarı ölçütleri (öneri)

| # | Ölçüt | Hedef |
|---|---|---|
| B8 | Salınımsız açı aralığı | Planlanan: 0–180° tamamı (ölçülen tüm açılarda boşluk kaynaklı LC yok) |
| B9 | Tepki hızı | Ortalama yerleşme süresi, salınımsız en iyi sabit ayara göre en az %30 kısa |
| B10 | Tespit | Tespit gecikmesi ≤ 3 salınım periyodu; salınımsız deneylerde yanlış alarm ≤ %5 |
| B11 | Gömülü gerçekleme | 1 kHz döngüde tablo araması + gözlemci + tespit, döngü süresinin ≤ %50'si |

**Karşılaştırma tabanları:** (i) en kötü açıya göre ayarlanmış sabit kazanç, (ii) tepkisel bir yöntem (Piao 2020'nin hataya dayalı anahtarlama kuralı ya da benzeri), (iii) planlamasız ama tespit + kazanç düşürmeli sürüm.

### Literatür kontrolü (5 Kasım 2026)

Tarama: IEEE Xplore 13 sorgu, Web of Science 6 sorgu, web 9 sorgu; 8 makalenin tam metni okundu, 1'inin yalnız özeti. Ayrıntılar `../literatur/okuma_notlari.md`.

| Çalışma | Yerçekimi | Boşluk | Yük sensörsüz | Açıya göre planlama | LC analizi | Bizim için |
|---|---|---|---|---|---|---|
| Zhang 2023 *IJCIM* | ~ (duruşa bağlı boşluk) | ✓ | ✓ | ~ ileri besleme önerisi | ✗ | Açık çevrim telafi; risk değil |
| Li 2026 *Mechatronics* | ✗ | ✓ | ✗ | ✗ (açı bağımlılığı redüktör geometrisi) | ✗ | Risk değil |
| Dai 2026 *MSSP* | ✗ | ✓ | ✗ | ✗ | ✗ | Bileşen 2 öncülü |
| Piao 2020 *IFAC* | ✗ | ✗ | ✓ | ✗ (tepkisel anahtarlama) | ✓ DF | Yöntem kaynağı, karşılaştırma tabanı |
| Weigand 2021 *RCIM* | ✓ ileri beslemede | ✓ | ✗ | ✗ | ✗ | Risk değil |
| Ruderman–Iwasaki 2016 *TIE* | ✓ mgℓ·sin q | ✗ (histerezis) | ✓ | ✗ | ✗ | **En yakın kurulum**, anılmalı |
| Armstrong–Amin 1996 *Automatica* | ✗ | ✗ | — | ✗ | ✓ kesin | Kapsam kararının dayanağı |
| Han 2016 *Nonlinear Dyn.* | ✗ | ✓ | ✓ | ✗ | ✗ | Bileşen 2 öncülü |
| Ahangarian Abhari 2019 *TIMC* (özet) | ? | ✓ | ? | ✗ | ✗ | Özete göre düşük risk |
| **Bu çalışma** | ✓ | ✓ | ✓ | ✓ | ✓ | |

**Sonuç:** "Yerçekimi ön yükünün açıya bağlı değerine göre önceden planlanan kazanç ve gözlemci bant genişliğiyle boşluk kaynaklı salınımı önlemek" yapan bir çalışma bulunamadı. Destekleyici yan kanıt: Ruderman–Iwasaki 2016'da kayan kip ek terimi kol 0°'deyken salınım üretiyor, 90°'de üretmiyor.

### GÜNCEL ÇERÇEVE KARARI (5 Kasım 2026 akşam, kullanıcı onayladı)

**Seçilen:** Temel (motor tarafı döngü + açıya göre ofset tablosu, bilinen yöntem, anılır) + **Katkı 1 ana katkı** (180° çevresinde, yerçekimi ön yükü sıfırken kolun boşluğun hangi yüzüne yaslandığını yalnız motor akımı + enkoderle kestirip ofset işaretini seçmek). **Katkı 2 kapsam dışı:** r ve K_s bilinen bir yöntemle (motor akımı + enkoder; Márton–Lantos 2009 / Gebler–Holtz 1998 tarzı) bir kez ölçülüp tabloya yazılır.

**Gerekçe:** amaç EEM alanında bir kontrol algoritması; çevrim içi mekanik parametre tanılaması kullanıcının alanının dışında kalıyor. Danışmanın belirttiği gibi, birden fazla bilinen yöntemi birleştirerek yapılan çalışma geçerli; özgünlük, birleşimin çözdüğü köşe durumda (sıfır torkta yüz belirsizliği).

**Bu karardan çıkan iş sırası:** (1) sürtünmeli ikizde motor tarafı + ofset; belirsiz bandın tanımı (akım işaretinin yüzü söylemediği açılar); (2) üst sınır: ölçülen θ_d işaretiyle ofset seçimi 180°'yi düzeltiyor mu (sensör kararındaki ara yolun (i) adımı); (3) yalnız motor sinyalleriyle yüz kestirici (tork gözlemcisi + küçük tork darbesiyle yoklama); (4) mgℓ değişimine duyarlılık.

**Bu kararla geçersizleşen/arşive giden:** üç bileşen tablosundaki 1. bileşen (açıya göre kazanç/gözlemci planlaması) ve 2. bileşen (salınım başlangıcı tespiti), H5, B8–B10 önerileri; bunlar kol sensörlü döngü için kurulmuştu. Geri dönüş noktası olarak duruyorlar. Yeni hipotez ve ölçütler belirsiz bant tanımlandıktan sonra yazılacak.

**Geri dönüş noktaları:** yüz kestirici yalnız motor sinyalleriyle tutmazsa → kol sensörlü geri besleme + kazanç planlaması; deneyde r ya da K_s zamanla belirgin değişirse → Katkı 2 yeniden açılır; 180° hiçbir yolla düzelmezse → "yöntemin sınırı".

### İş sırası (1): sürtünmeli ikizde motor tarafı + ofset ve belirsiz bant (6 Kasım 2026)

Betikler: `simulasyon/5_planlama/surtunme_ofset.m`, `belirsiz_bant.m` (D düzeneği, Fc 0,04, Fs 0,06 N m, mgℓ 0,240 N m, r 1,5°, motor tarafı P-PI, ofset = sign(sin θ)·r + mgℓ sin θ / K_s, kol hedefe alttan ve üstten).

- **Ofset tablosu sürtünmede de tutuyor.** Boşluk salınımı yok. Kalan "düzensiz" sınıflar yapışma-kayma titremesi, genlik 0,1° altında. 10–170°'de kalıcı hata ideal enkoderle ≤ 0,38°, 0,27°'lik enkoderle ≤ 0,51° (sürtünmesizde ≤ 0,27° idi).
- **Yanlış yüz yalnız 180°'nin 1° içinde.** 170–180° arası 0,25° adımla, 6 koşu türü: kol yanlış yüze 179–180°'de düşüyor (üstten gelişte 179°'den, alttan gelişte 179,5–180°'den itibaren), hata ≈ 2r ≈ 3,1–3,4°. 179°'nin altında yerçekimi kolu her zaman doğru yüze yaslıyor, yani yüz hedef açıdan zaten belli. **Yüz kestirimi gereken bant |θ − 180°| ≤ 1° (< r).**
- **Durgun akım işareti bu bantta kör.** Durgunken u = τ_s + τ_f, |τ_f| ≤ Fs, bu yüzden sign(u) yüzü ancak mgℓ|sin θ| > Fs iken kesin söyler: analitik kör bant ±14,5° (Fs/mgℓ = 0,25). İkizde sign(u) 5° ve 175°'de zaten yanlış (u ile τ_s arası ≈ Fc farkı). Yüzün gerçekten belirsiz olduğu ±1°'lik bantta kolu yüzde tutan tork ≤ 0,004 N m, yani Fc'nin onda biri. **Sonuç: "akımın işaretine bak" türü edilgen kestirim bu düzenekte çalışamaz.** Bu, Katkı 1'in "önemsiz görülme" riskine karşı somut cevap.
- **Devrilme olayının motor tarafında izi var.** 180°'de devrilen koşuda kol boşluğu geçip karşı yüze çarpınca dişli torku −0,07 N m'ye iniyor (Fc'den büyük), motor torku 30 ms içinde +0,046'dan −0,026 N m'ye dönüyor. Yani durgun işaret kör ama **çarpma olayı gözlenebilir**. Kestirici için iki aday: (a) olay tabanlı: tork gözlemcisiyle çarpma darbesini yakalayıp yüzü güncellemek, (b) etken yoklama: küçük tork darbesiyle boşluğu bilerek kapatıp hangi yönde serbest hareket olduğuna bakmak.
- **Ölçüt önerisi:** H7 iş sırası (2)'den sonra yeniden yazıldı, güncel hâli aşağıda, "İş sırası (2)" alt bölümünün sonunda. B12: bant içi yüz doğruluğu ≥ %95; B13: yoklama varsa kol hareketi ≤ 0,5° (B12, B13 onay bekliyor).
- **Not (sınanmadı, iş sırası 2'de bakılacak):** tam 180° hiçbir yüzde durgun denge değil (sin θ = 0 iken yüzde tutan tork sıfır). Yüz kusursuz bilinse bile en iyi sonuç 180° ∓ küçük bir pay olabilir; üst sınır deneyi bunu ölçecek.
- Benzetim sürtünmesi tanh ile yumuşatılmış (veps 2e-3 rad/s): durgunlukta τ_f → 0 eğilimli, yani ikiz akım işaretini gerçekte olduğundan **daha iyi** gösteriyor; kör bant donanımda daha geniş olabilir, daha dar olamaz.

### İş sırası (2): üst sınır, yüz kusursuz bilinse (6 Kasım 2026)

Betik: `simulasyon/5_planlama/ust_sinir.m` (log ve `.mat` yanında). İkize varsayılanı kapalı `p.ofsetYuz` seçeneği eklendi: ofset = s·r + mgℓ sin θ_ref / K_s, s ikizin **gerçek** temas yüzünden, sign(δ = φ − θ). İki çeşit: `anlik` (her kontrol örneğinde, temas varken; boşlukta s tutulur) ve `durunca` (yalnız kol 20 ms durgunken). Karşılaştırma: iş sırası 1'in tablosu (s = sign(sin θ_ref)). Hedef 175–185° (0,25° adım), kol ±1,1° uzaktan, enkoder ideal / 0,27°, sürtünmeli (Fc 0,04, Fs 0,06) ve sürtünmesiz; 24 koşu türü × 41 açı. (İlk denemede kol ±1° uzaktan geliyordu; 179°/181° hedefinde kol tam 180°'den, boşluğun ortasından başlayıp kararsız dengede asılı kaldı. Yapay durum, adım 1,1° yapıldı.)

- **Tam 180° düzelmiyor, yüz kusursuz bilinse bile.** 180° hedefinde son 1 s ortalama hata koşuya göre 0,1° ile 2,7° arasında dağılıyor, en büyük anlık sapma 3,7°'ye çıkıyor. Hiçbir koşu 180°'de yüzde durmuyor.
- **Neden (zaman serisinden):** kol bir yüze yaslıyken integratör onu yavaşça 180°'ye doğru itiyor. 180°'yi geçtiği an yerçekimi öbür yöne dönüyor, kol boşluğu (2r ≈ 3°) geçip karşı yüze düşüyor. Yüz seçimi değişiyor, ofset 2r sıçrıyor, döngü kolu geri çekiyor, kol yine 180°'yi geçiyor. Sürtünmeli ikizde bu ~4 s'lik yavaş bir avlanma, 180°'den en büyük sapma ≈ 3,5°. Yani 180° yapısal olarak "anahtarlama yüzeyi": kolu θ'da tutan yüz sign(θ − 180°) ile belirleniyor ve hedef tam bu sınırın üstünde.
- **180°'nin ±0,5–1°'si düzeliyor (sürtünmeli).** 179–179,5° ve 180,5–181°'de gerçek yüzle ofset seçmek her iki yönden ve her iki enkoderle hatayı ≈ 3,2°'den ≤ 0,36°'ye indiriyor (en büyük anlık sapma ≤ 0,36°). Tablo yönteminde bu açılarda kol karşı yönden gelince yanlış yüzde kalıyordu. **Kestiricinin değeri burada: |θ − 180°| ∈ [0,5°, 1°] bandı.**
- **±0,25° içi güvenilmez.** 179,75° ve 180,25°'de bazı koşular doğru (≤ 0,2°), bazıları avlanıyor (0,27°'lik enkoderle 179,75°'de ortalama hata 0,94–1,73°, anlık 3,8°). ε = 0,25° bir enkoder adımı kadar; yerçekimi tutma torku 0,001 N m.
- **Sürtünmesizde yüz bilgisi kendi salınımını üretiyor.** 179,25–180,75°'de `anlik` seçim son 6 s'de ~24 yüz değişimi, kol ±3° genlikle ~2 Hz'de boşluğu geçip duruyor; `durunca` değişimi yarıya indiriyor ama bitirmiyor. Mekanizma röle benzeri: her yüz değişimi referansı 2r sıçratıyor, bu sıçrama kolu karşı yüze fırlatıyor. Sürtünme bunu ±0,5°'nin dışında söndürüyor. Gerçek düzenekte sürtünme var, ama bu bulgu **kestiricinin yüz değiştirdiğinde ofseti basamakla değil yumuşak (rampa) değiştirmesi** gerektiğini düşündürüyor (sınanmadı).
- `anlik` ile `durunca` arasında açık bir kazanan yok; sürtünmeli 0,27°'lik enkoderde `anlik` alttan, `durunca` üstten gelişte daha kötü.
- **Ölçütlere etkisi:** eski H7'deki "180°'de hata ≈ 3°'den ≤ 0,5°'ye" tam 180° için kusursuz yüz bilgisiyle bile tutmuyor. İki yol vardı: (a) hedefi 180° ∓ ε olarak tanımlamak, (b) tam 180°'yi "yöntemin sınırı" sayıp ölçütü |θ − 180°| ≥ 0,5° bandına daraltmak. **Kullanıcı (a)'yı seçti (6 Kasım 2026).**
- **Hedef kaydırma kuralı (a):** |θ_ref − 180°| < ε istenirse kontrolcü hedefi θ_ref' = 180° − ε·sign(kolun geldiği taraf) yapar; ε = 0,5°. Kol 180°'nin altından geliyorsa 179,5°'de, üstünden geliyorsa 180,5°'de durur. Bu açıda yerçekimi kolu doğru yüze yaslar, yani yüz ilke olarak hedefin işaretinden belli. Ama kol bir bozucuyla ya da geçiş sırasında karşı yüze düşebilir; kestiricinin işi bunu fark edip ofseti düzeltmek. Kaydırma 180°'nin kendisini bir bulgu olarak gösterir: tam 180°, kolu tutan yüzün işaret değiştirdiği nokta olduğu için yapısal olarak ulaşılamaz.
- **H7 (yeni, kullanıcı onayladı):** "|θ − 180°| ≤ 1° bandında, tam 180° istekleri 180° ∓ 0,5°'ye kaydırılarak, yalnız motor sinyalleriyle (akım + motor enkoderi) çalışan yüz kestirici kolun yanlış yüzde kaldığı durumları yakalayıp düzeltir. Kalıcı hata yanlış yüzde ≈ 3°'den, kaydırılmış hedefe göre ≤ 0,5°'ye (istenen 180°'ye göre ≤ 1°'ye) iner; edilgen akım işaretine bakan yöntemden anlamlı ölçüde iyidir (edilgen yöntemin bant içi doğruluğu henüz ölçülmedi)." Üst sınır (kusursuz yüz bilgisi) bu bantta ≤ 0,36° veriyor; ölçütteki 0,5° kestiricinin payını içeriyor.

### İş sırası (3): yalnız motor sinyalleriyle yüz kestirici (6 Kasım 2026)

Betik: `simulasyon/5_planlama/yuz_kestirici.m` (log yanında). İkize varsayılanı kapalı `p.yuzKes` seçeneği eklendi; kestirici yalnız motor enkoderini (nicemli), uygulanan torku u ve kendi durumunu görür, θ ve δ'yı görmez. Ofset = ŝ·r + mgℓ sin θ_hedef / K_s; ofsetteki yüz ŝ'ye rampayla gider (varsayılan 0,5 s, −1'den +1'e). Gerileme kontrolü: `belirsiz_bant` logunda yalnız tarih satırı değişti.

**Yöntemler.**
- **Tork gözlemcisi** (ortak parça): motor tarafı model J_M φ̈ = u − b_M φ̇ − d, d = τ_f + τ_s; Luenberger, üçlü kutup 2π·40 rad/s. Sürtünme yalnız aralık olarak bilinir: motor dönerken τ_f = sign(ω̂)·[F_c, F_s], dururken [−F_s, F_s]. Buradan dişli torku için bir aralık [lo, hi] çıkar.
- **edilgen:** motor 20 ms durgunken ŝ = sign(u) (karşılaştırma tabanı).
- **olay:** aralık sıfırı 0,015 N m payla 10 ms boyunca dışarıda bırakırsa ŝ = o işaret. Çarpmayı da, tork aktaran her hareketi de yakalar; motor yapışma sürtünmesiyle duruyorsa F_s'yi aşmayan çarpmayı göremez.
- **yoklama:** hedef bandın içindeyken (|θ_hedef − 180°| ≤ 1°) motor 0,5 s durgun kalınca kontrolcü dondurulur, inanılan BOŞLUĞA doğru mutlak 0,12 N m itiş uygulanır. Gözlemcinin itiş yönündeki dişli torku tahmini 0,04 N m'yi aşarsa temas var: ŝ = itiş yönü, itiş kesilir. Motor önce 0,5° serbest yol alırsa ŝ doğru; motor bang-bang (fren, geri it, fren) ile başlangıca döndürülür. Bir yüz değişiminden sonra motor oturunca yeniden yoklanır (en çok 6).
- **olay+yok:** ikisi birlikte. Ayrıca `olay+yok/p` (bant içinde 2 s'de bir ek yoklama) ve `olay+yok/b` (rampa yok, basamak) değişkenleri.
- Referans çizgileri: `tablo` (ŝ = sign(sin θ_hedef) sabit) ve `ust_sinir` (ikizin gerçek yüzü, anlık, basamak; hile).

**Senaryolar:** istek 179, 179,25, 179,75, 180, 180,25, 180,75, 181°; |istek − 180°| < 0,5° olanlar hedef kaydırma kuralıyla 179,5 / 180,5°'ye kayar. Kol ±1,1° uzaktan, iki yönden gelir. Bozucu: yok / t = 3 s'de kola 180°'ye doğru 0,05 N m, 20 ms yük darbesi / yanlış başlangıç yüzü. Toplam 42 senaryo; enkoder ideal, 0,017° (0,27°/16), 0,27°; sürtünmeli (F_c 0,04, F_s 0,06) ve sürtünmesiz. **H7 geçti** = son 1 s ortalama |e| ≤ 0,5° (kaydırılmış hedefe göre), son 1 s en büyük sapma ≤ 1° (avlanmıyor) ve son yüz doğru.

| Sürtünme | Enkoder | tablo | üst sınır | edilgen | olay | yoklama | **olay+yok** | olay+yok basamak |
|---|---|---|---|---|---|---|---|---|
| var | ideal | 10/42 | 42/42 | 20/42 | 42/42 | 42/42 | **42/42** (en kötü 0,18°) | 42/42 |
| var | 0,017° | 10/42 | 42/42 | 20/42 | 38/42 | 24/42 | **42/42** (0,17°) | 42/42 |
| var | 0,27° | 10/42 | 42/42 | 23/42 | 17/42 | 2/42 | **4/42** | 3/42 |
| yok | ideal | 4/42 | 4/42 | 42/42 | 42/42 | 42/42 | **42/42** (0,00°) | 8/42 |
| yok | 0,017° | 4/42 | 4/42 | 42/42 | 42/42 | 20/42 | **42/42** (0,02°) | 12/42 |
| yok | 0,27° | 7/42 | 7/42 | 33/42 | 42/42 | 10/42 | **37/42** (0,54°) | 20/42 |

Bulgular:
- **Önerilen kestirici: olay + yoklama + rampa.** Motor enkoderi 0,017° ya da daha inceyse 4 koşu türünün hepsinde 42/42. Kalıcı hata ≤ 0,18°, yani üst sınırla aynı düzeyde. Yoklamada kolun en büyük hareketi ≤ 0,32° (B13 önerisi 0,5°). Yanlış yüze düşülen koşularda yakalama süresi (son |e| > 0,5° anı − olay anı) ortalama 2,3 s (ideal) / 2,8 s (0,017°), en çok 6,3 s; üst sınırda 2,2 s. Sürenin büyük kısmı düzeltme hareketinin kendisi (rampa + yerleşme).
- **Edilgen sign(u) sürtünmede çalışmıyor:** 20/42. Bozucusuz 14 senaryonun hiçbirinde tutmuyor: integratör yapışma sürtünmesine yaslanınca u ≈ 0,06 N m'ye çıkıyor, dişli torku ise 0,003. Sürtünmesizde 42/42. Bu, iş sırası 1'deki "durgun akım işareti kör" bulgusunun doğrudan sınanması; körlüğün nedeni sürtünme. Zaman içinde ŝ doğruluğu edilgende ort. 0,54, olay+yokta 0,996 (ideal).
- **İki yöntem birbirini tamamlıyor.** Olay tek başına, kol "sessizce" konunca kaçırıyor (0,017°'de 180,75° ve 181°'ye alttan gelişte 4 senaryo): kol karşı yüze yavaş düşüyor, çarpma F_s'yi aşmıyor, motor kıpırdamıyor, yani enkoder hiçbir şey görmüyor. Yoklama bunları yakalıyor. Yoklama tek başına ise düzeltme hareketinin kendisinin yol açtığı düşüşleri bir sonraki yoklamaya kadar göremiyor ve ince enkoderde 24/42'de kalıyor. 2 s'de bir ek yoklama (`/p`) hiçbir koşuda sonucu değiştirmedi.
- **Rampa sürtünmesizde şart:** basamakla 8/42, yüz seçimi son 3 s'de 9 kez değişiyor (iş sırası 2'deki röle benzeri salınım). Rampayla 42/42 ve hiç avlanma yok. Üst sınırın (basamak) sürtünmesizde 4/42'de kalması da aynı mekanizma. Sürtünmeli ikizde rampa ile basamak arasında fark yok.
- **Enkoder çözünürlüğü belirleyici; 0,27° yetmiyor.** Sürtünmeli ikizde 0,27°'lik enkoderle en iyi yöntem 4/42. Neden: çarpma ve 0,5°'lik yoklama itişi motoru bir enkoder adımı mertebesinde oynatıyor. Gözlemcinin dişli torku tahmini nicemleme gürültüsünde kayboluyor. Ön denemelerde 0,068° (×4) karışık, 0,017° (×16) ve daha incesi tutarlıydı. 0,017° kol tarafında ≈ 21 000 adım/tur, N = 30'la motor milinde ≈ 700 adım/tur (≈ 176 darbe/tur dörtlü kodlama); motor miline takılan 12 bitlik manyetik enkoder (ör. AS5600) kol tarafında ≈ 0,003° verir. Bu bir donanım kararı: **kol tarafında yine sensör yok**, yalnız motor enkoderi incelir.
- **Tasarım sırasında çıkan, yazıya geçmeye değer üç gözlem:** (i) yoklamada "temas mı" sorusuna yol süresiyle cevap verilemiyor. Dişli yayı yumuşak (K_s = 10 N m/rad), temasta da motor ilk 20–30 ms'de yay sıkışırken neredeyse serbest gibi ilerliyor. Ayırt eden şey gözlemcinin dişli torku tahmini (temasta ≈ 0,1 N m, boşlukta ≈ 0). (ii) Yoklama torku tutma torkunun üstüne eklenmemeli. Durgunlukta integratör sürtünmeye yaslanıp u'yu 0,06 N m'ye çıkarabiliyor; itiş mutlak tork olmalı. (iii) "Motor durgun" kararı kolun durduğunu söylemiyor. 0,3 s beklemede yoklama, kol boşlukta hâlâ 5°/s ile düşerken başladı; 1 s beklemede ise ince enkoder yapışma-kayma kıpırtısını gördüğü için motor hiç o kadar durgun sayılmadı. 0,5 s seçildi.
- **H7'ye göre:** H7 olay + yoklama ile, motor enkoderi ≤ 0,017° şartıyla ikizde sağlanıyor. Kalıcı hata yanlış yüzde ≈ 3°'den ≤ 0,18°'ye iniyor, edilgen yöntem sürtünmede 20/42 iken kestirici 42/42. Mevcut 0,27°'lik enkoderle sağlanmıyor.
- **B12 için not:** "son yüz doğru" ölçüsüyle olay+yok 42/42 (%100). Zaman içinde ŝ doğruluğu ortalaması ise ideal enkoderde 0,996, 0,017°'de 0,942 (en kötü koşu 0,40: sessiz konmadan sonra yoklamaya kadar geçen sürede ŝ yanlış). B12'nin hangi ölçüyle tanımlanacağı karar bekliyor.
- **Sınırlar:** u ikizde uygulanan torkun kendisi, akım ölçüm gürültüsü (INA228) yok. Kontrolcünün hız terimi ikizde gerçek motor hızını kullanıyor; kestirici ise yalnız nicemli enkoderi görüyor. Sürtünme tanh ile yumuşatılmış (iş sırası 1'deki not; edilgen yöntem gerçekte daha da kötü olabilir). Gözlemci F_c, F_s, J_M, b_M'nin doğru bilindiğini varsayıyor; parametre hatasına duyarlılık sınanmadı.

### Önerilen yeni çerçeve ve literatür kontrolü (5 Kasım 2026 akşam; karar yukarıda)

Motor tarafı geri beslemede boşluk salınımı ikizde kaybolunca (yukarıda, sensör kararı) kazanç planlamasının gerekçesi zayıfladı. Yerine önerilen çerçeve:

- **Temel:** kol sensörsüz motor tarafı kontrol + açıya göre ofset tablosu (φ_ref = θ + sign(sin θ)·r + mgℓ sin θ / K_s).
- **Katkı 1:** yerçekimi ön yükünün sıfıra indiği bölgede (180° ve çevresi) kolun hangi yüze yaslandığını yalnız motor akımı + enkoderle kestirip ofseti buna göre seçmek.
- **Katkı 2:** r ve K_s'yi motor sinyallerinden, yerçekimini bilinen ve açıyla değişen bir yük olarak kullanıp çevrim içi tanılamak.
- **Doğrulama:** AS5600 yalnız hakem.

Hedefli kontrol: IEEE 15 sorgu, web 7 sorgu, 4 yeni tam metin (Gebler–Holtz 1998, Márton–Lantos 2009, Neubauer 2015, Yao 2026), 8 özet/patent; önceki okumalar bu iki soru için yeniden tarandı. Ayrıntı `../literatur/kontrol_taramasi/hedefli_tarama_2026-11-05.md` (4. tur) ve `../literatur/okuma_notlari.md`.

| Parça | Hüküm | En yakın kaynaklar |
|---|---|---|
| Temel | **Yapılmış** | Neubauer 2015 *Mech. Sci.* (sign(motor torku)·boşluk + esneklik, aynı kural), Ruderman 2016 *TIE*, Weigand 2021 *RCIM*, CNC lost motion telafisi |
| Katkı 1 | **Boşluk var, dar** | Doğrudan yapan yok. Neubauer sign(0) = 0 bırakıyor, Yao 2026 yüzü son hız işaretinden seçiyor; Malzahn 2014 ve Kollár 2002 sorunu yalnız gözlüyor. Yapı taşları biliniyor: tork gözlemcisi (Ruderman–Iwasaki 2016), temas kipi kestirimi (Lagerberg–Egardt 2007, Kaiser 2023), tork darbesiyle yoklama (Gebler–Holtz 1998) |
| Katkı 2 | **Kısmen yapılmış** | r motor sinyalleriyle: Gebler–Holtz 1998, Márton–Lantos 2009, Han 2016; yerçekimini ölçüm aracı yaparak r: **Giovannitti 2022**; K_s motor tarafından: Neubauer 2015 (çevrimdışı), Li 2026 *TIA* (çevrim içi + kazanç planlama). Kalan yalnız birleşim (sabit hedefte, r ve K_s birlikte, çıkış sensörsüz) |

**Sonuç:** çerçeve "bilinen yöntemlerin birleşimi + dar bir yeni parça" olarak kalıyor. Özgünlük iddiası Katkı 1'e dayanmalı ve şu üç şeyi göstermeli: (1) yüzün tork işaretinden okunamadığı bandın tanımı (|mgℓ sin θ| ≲ sürtünme + akım gürültüsü), (2) bu bantta yalnız motor sinyalleriyle yüzün gözlenebilirlik sınırı, (3) çalışan bir yöntem (ilk aday: Gebler–Holtz tarzı küçük tork darbesiyle aktif yoklama). Katkı 2 destek katmanı; anılan öncüllerin üzerine kurulur.

**Teknik uyarı (Katkı 2):** durağan durumda φ = θ + sign·r + τ_g/K_s ve θ bilinmiyor; r ile K_s yalnız motor konumundan ayrılamaz. Ya akımdan τ_g okunup θ'ya çevrilir (mgℓ bilinmeli, 90° civarında duyarsız) ya da dinamik uyarım gerekir. İkizde önce gözlenebilirlik sınanmalı.

**Geri dönüş noktası:** kullanıcı Katkı 1'i dar bulursa (a) kol tarafı geri besleme + kazanç planlaması (ilk 5 Kasım çerçevesi, literatürde doğrudan rakipsiz ama sensörlü) ya da (b) çift döngü seçenekleri açık kalıyor.

### İlk çerçeveden ne değişti, ne kaldı

| Konu | İlk çerçeve (24 Ekim) | Güncel (5 Kasım) |
|---|---|---|
| Amaç | Sınırı öngörmek ve deneyle doğrulamak | Sınırı kullanarak salınımı önleyen kontrolcü |
| DF + dijital ikiz | Sonucun kendisi | Ayar tablosunu üreten araç |
| Kol açısı sensörü (AS5600) | θ_d ölçümü için | Yalnız doğrulama; kontrolcü görmez |
| L (kaynak ayrıştırma) | Zorunlu bileşen | Zorunlu; kapsam kararıyla daha da önemli |
| O (açıya göre harmanlama) | Uzantı | 1. bileşenin içine girdi (planlama) |
| H (dengeleme) | Motivasyon + ölçüt | Motivasyon olarak kalır |
| Donanım, düzenek, deney protokolü | — | Değişmedi |

**Açı tanımı:** θ = 0° kol aşağı sarkık, 90° yatay, 180° dik yukarı. Yerçekimi torku T_g = mgℓ·sin θ: 90°'de en büyük, 0° ve 180°'de sıfır.

## 1. Problem

Dişli kutulu bir eklemde boşluk (backlash), kapalı çevrimde sabit bir hedefte bile kendiliğinden süren bir salınıma (limit cycle, LC) yol açabilir. Bu salınımın kazanca bağlı sınırı DF ile öngörülebiliyor (Ghaffari 2013, C. Wang 2017, Bai 2024). Ancak bu analizler yatay eksenler için yapılmış; dişliye etkiyen ortalama tork sıfır ya da simetrik bir mekanik ön yük olarak alınıyor.

Düşey düzlemde dönen bir robot kolunda durum farklı. Yerçekimi torku dişliyi tek bir yüze bastıran **doğal, tek yönlü bir ön yük** gibi davranır ve büyüklüğü kol açısıyla değişir: kol yataya yakınken dişli bastırılı kalır, düşeye yakınken boşlukta serbesttir. Bu etki nitel olarak biliniyor (Karim 2018, Xu 2023) ve sönümlü titreşim için ölçülmüş (Malzahn 2014). Fakat salınımın başladığı sınırın açıya ve kazanca birlikte nasıl bağlı olduğu ne haritalanmış ne de öngörülmüş.

Pratikteki sonucu şu: tek bir açıda ayarlanmış bir kontrolcü başka bir açıda salınabilir. Yerçekimi dengelemesi (karşı ağırlık, yay) de motor torkunu azaltırken bu doğal ön yükü fark ettirmeden ortadan kaldırır.

## 2. Araştırma sorusu

**Ana soru:** Yerçekimi etkisindeki tek motorlu, dişli boşluklu bir eklemde, sabit hedef açısı θ₀ ve kontrol kazancına bağlı olarak kendiliğinden süren salınımın başlama sınırı, Ghaffari'nin simetrik ön yük çerçevesi tek yönlü ve açıya bağlı yerçekimi ön yüküne genişletilerek ne doğrulukla öngörülebilir?

**Alt sorular:**
- **AS1.** Sınırı hangi boyutsuz sayılar belirler? Adaylar: yerçekimi oranı γ = mgℓ·sin θ₀ / (K_s·r), kazanç–sertlik oranı ρ = ω_c/ω_rez (Ghaffari'nin r_gs'si ile ilişkisi r_gs = ρ·√(J/J_eff)) ve sürtünme oranı φ = F_C / (K_s·r).
- **AS2.** Deneyde gözlenen salınım gerçekten boşluktan mı geliyor? Açı taraması sürtünme ve nicemleme kaynaklı salınımı ayırt edebilir mi? (L)
- **AS3.** Yerçekimi dengeleme oranı sınırı nasıl kaydırır? Hangi orandan sonra salınım başlar? (H)

## 3. Hipotezler

- **H1.** Kritik kazanç, |γ| büyüdükçe artar. 90° civarında salınımsız bir bölge oluşur, bu bölge kazanç arttıkça daralır. Simülasyonda gözlenen ölçekleme γ_sınır ≈ 3·ρ³ (ρ ≤ 0,33) bunun nicel biçimidir. Sınır 90°'ye göre simetrik değildir: 180° tarafında yerçekimi kolu dengeden uzaklaştıran bir "negatif yay" gibi davranır, bu yüzden salınım orada daha düşük kazançta başlar (simülasyonda da görüldü).
- **H2.** Simetrik ve yerçekimsiz DF (Ghaffari 2013) bu açı bağımlılığını öngöremez. Tek yönlü kaymayı içeren (iki girişli) DF öngörebilir.
- **H3.** Sürtünme ve nicemleme kaynaklı salınım açıdan bağımsızdır; boşluk kaynaklı salınım açıya bağlıdır.
- **H4.** Dengeleme oranı arttıkça etkin γ küçülür ve salınımsız bölge daralır. Tam dengelemede sınır, yerçekimsiz (yatay) eksenin sınırına iner.

## 4. En yakın literatür

✓ var · ✗ yok · ~ kısmen

| Çalışma | Yerçekimi modelde | Açı taranıyor | Kazanç taranıyor | Sabit hedefte LC | Sınır öngörüsü | Tek tahrik motoru | Fiziksel deney |
|---|---|---|---|---|---|---|---|
| Ghaffari 2013 (TMECH) | ✗ | ✗ | ✓ (r_gs) | ✓ | ✓ DF | ✓ | ✓ |
| C. Wang 2017 (TIE) | ✗ | ✗ | ✓ | ✓ | ~ frekans | ✓ | ✓ |
| Bai 2024 (TPEL) | ✗ | ✗ | ✓ | ✓ | ✓ DF | ✓ | ✓ |
| J. Wang 2024 (Nonlinear Dyn.) | ✗ | ✗ | ✓ | ✓ | ✓ DF | ✓ | ✓ |
| Yang 2017 (Proc. IMechE C) | ✗ | ✗ | ✓ | ✓ | ~ bölge | ✓ | ✓ |
| Kollár 2003 (EJDE) | ~ üst denge | ✗ | ✓ (P–D) | ✓ | ✓ kesin çözüm | ✓ | ✓ |
| Sun 2023 (TIE) | ✓ | ✗ (yalnız 90°) | ~ (2 değer) | ✓ | ✗ | ✗ (çift motor) | ✓ |
| Xu 2023 (RA-L) | ~ nitel | ~ ofset, hareket halinde | ✗ | ✗ | ✗ | ✗ (çift motor) | ✓ |
| Malzahn 2014 (tez) | ✓ | ✓ (10°) | ✗ | ✗ (sönümlü) | ✗ | ✓ | ✓ |
| Giovannitti 2022 (JIM) | ✓ | ~ sürekli dönüş | ✗ | ✗ | ✗ | ✓ | ✓ |
| Márton 2009 (ECC) | ✗ | ✗ | ✓ | ✓ | ~ yaklaşık | ✓ | ✗ |
| Karim 2018 (M2VIP) | ~ pozla değişen tork, nitel | ~ birkaç poz | ✗ | ✗ | ✗ | ✓ | ✓ (KUKA) |
| G. Sun 2021 (IET CTA) | ✗ | ✗ | ~ gözlemci kazancı hataya göre | ✗ (sinüs izleme) | ✗ | ~ çok motorlu tezgâh | ✓ |
| Ruderman 2019 (JDSMC) | ✗ | ✗ | ✗ (röle) | ✓ (bilerek uyarılan) | ~ | ✓ | ✓ |
| Lu 2015 (Robotica) | ✗ | ✗ | ✗ (açık çevrim) | ✗ (zorlanmış cevap) | ✗ | ✓ | ✗ |
| **Bu çalışma (hedef)** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

Danışmanın listesindeki 13 kaynağın hepsi tabloda. J. Wang 2024 ile C. Wang 2017 ayrı gruplardır. Ek olarak Yang 2017 ve Ruderman 2019 son taramada eklendi.

### Boyutsuz oranlar ve kontrolcü parametrelerinin eşlemesi

Danışmanın uyardığı gibi kaynaklarda aynı sembol farklı büyüklükleri gösteriyor. Bu çalışmada kullanılacak tanımlar:

| Büyüklük | Kaynaktaki tanım | Bu çalışmadaki karşılığı |
|---|---|---|
| Ghaffari 2013, sertlik oranı r_gs | √(k_p k_v / K_s); P konum (k_p, 1/s) + PI hız (k_v, N·m·s/rad) | r_gs = ω_c √(J/K_s) = ρ·√(J/J_eff) |
| C. Wang 2017, "r_s" | Ghaffari'nin r_gs'siyle aynı tanım | Aynı. Bizim eski "r_s" ile karıştırılmaması için bizim oran **ρ** |
| Bu çalışma, ρ | ω_c / ω_rez, ω_rez = √(K_s / J_eff), J_eff = J_M J_L / (J_M + J_L) | PID'de K_p = J ω_c², K_d = 1,4 J ω_c, K_i = K_p ω_c / 4 |
| Bu çalışma, γ | mgℓ·sin θ₀ / (K_s·r): yerçekimi torku / boşluğun yarısını kapatan temas torku | Ghaffari'deki ön yük oranının (τ_p / K_s r) tek yönlü, açıya bağlı karşılığı |
| Bu çalışma, φ | F_C / (K_s·r) | Sürtünmenin baskın olduğu rejimi ayırır |
| Sun 2023, K_p = 20 / 50 | P konum (K_p, 1/s) + PI hız; hız PI katsayıları makalede yok | k_v gözlenen 9 Hz'den tahmin: r_gs ≈ 0,15 / 0,23, γ(90°) ≈ 0,024 ([`esleme_tablosu.md`](../simulasyon/4a_ghaffari/esleme_tablosu.md)) |

Kademeli P–PI ile PID birebir aynı yapı değil (bizde K_d K_p'ye bağlı ve integral var). Bu yüzden deneylerde Ghaffari'nin P–PI yapısı da koşulur (bkz. `mimari.md`).

## 5. Önerilen katkı (Yol 2: yöntem geliştirme)

**Temel alınan yöntem:** Ghaffari 2013. Çok döngülü sistemi tek döngüye indirgeme, DF ve sertlik oranına göre rejim sınıflaması (kararsız / rezonans LC / çarpma).

**Giderilen eksiklik:** Ghaffari'de ön yük simetrik (±τ_p, yaylı anti-boşluk mekanizması) ve sabit. Yerçekimi ön yükü ise tek yönlü ve açıya bağlı.

**Katkılar:**
1. Ghaffari çerçevesinin tek yönlü, açıya bağlı ön yük için genişletilmesi (iki girişli DF ile). Sonuç: θ₀ × kazanç düzleminde salınım sınırının öngörüsü ve düzenekten bağımsız boyutsuz biçimi (γ, ρ).
2. Öngörünün tek motorlu, düşük maliyetli bir düzenekte deneysel doğrulanması: üç düzenek (uç kütlesi ya da boşluk genişliği değiştirilerek), iki sensörle θ_d ölçümü.
3. Gözlenen salınımın kaynağının açı taramasıyla ayrıştırılması (boşluk / sürtünme / nicemleme).
4. Sonucun tasarım kuralına çevrilmesi: verilen açı aralığı için en büyük güvenli kazanç ve izin verilebilir yerçekimi dengeleme oranı.

**İddia edilmeyenler:**
- Kaymalı (iki girişli) DF'nin kendisi yeni değil; boşluk için 1973'ten beri var.
- "Yerçekimi dişliyi bastırır" ilkesi nitel olarak biliniyor (Ahmad 1985, Karim 2018, Xu 2023).
- Kazanç düzleminde sınır çıkarma fikri de yeni değil (Kollár 2003, Yang 2017).

Yenilik bu üçünün yerçekimli bir eklemde açı eksenine taşınması, Ghaffari çerçevesine bağlanması ve deneyle doğrulanmasıdır.

## 6. Başarı ölçütleri (öneri, danışmanla netleşecek)

| # | Ölçüt | Hedef | Dayanak |
|---|---|---|---|
| B1 | Her θ₀'da kritik kazancın öngörü hatası (deneye göre) | Medyan ≤ %20; yerçekimsiz Ghaffari öngörüsünden en az 2 kat daha iyi | Ghaffari'nin frekans hatası %2–24 |
| B2 | Açı yönünde sınırın öngörü hatası (sabit kazançta) | ≤ 5° | Açı tarama adımı ve sınırın keskinliği |
| B3 | LC frekansı ve genliğinin öngörü hatası | Frekans ≤ %15, genlik ≤ %30 | C. Wang 2017'de frekans uyumu %1–3; genlik DF'de daha zayıf |
| B4 | Genellenebilirlik | Üç düzenekte sınır noktaları (γ, ρ) düzleminde aynı eğri üzerinde (dağılım ≤ 2×) | Simülasyonda ideal modelde 2–3×, gerçekçi modelde ~5× |
| B5 | Kaynak ayrıştırma (L) | Kontrollü senaryolarda doğru sınıflama ≥ %90 | Senaryolar: kaplin boşluğu, keçe pabuçla eklenen sürtünme, yazılımda bit atılarak üretilen nicemleme |
| B6 | Tekrarlanabilirlik ve belirsizlik | Her sınır noktası ≥ 3 tekrar; yayılım ve ölçüm belirsizliği raporlanır | Danışmanın 6. aşama beklentisi |
| B7 | Dengeleme kuralı (H) | Dengeleme oranına göre sınır kaymasının öngörüsü B1 ile aynı doğrulukta | H4 |

**Karşılaştırma yöntemleri (referans):** (i) yerçekimsiz Ghaffari / simetrik DF, (ii) sayısal benzetim (kesin), (iii) yalnız θ₀ = 90° için Sun 2023 benzeri tek açı ölçümü.

## 7. Kapsam ve kısıtlar

| Kısıt | Değer | Gerekçe |
|---|---|---|
| Eklem sayısı | 1 (omuz), düşey düzlemde döner | Açı bağımlılığını tek değişkene indirger. İki eklem ileriki çalışma (Malzahn'daki θ₂+θ₃ kanyonu). |
| Hareket aralığı | 0–180° | Ön yükün sıfırdan (0°, 180°) en büyüğe (90°) bütün aralığı. 180° = Kollár'ın üst denge durumu. |
| Hareket türü | Sabit hedef θ₀ + küçük adım (≈5°) | Hareket halinde boşluk geçişi kapsam dışı. |
| Hedef hız | Adım yanıtında kapalı çevrim bant genişliği ω_c ≈ 30–45 rad/s (yükselme ≈ 0,05–0,1 s); kol hızı birkaç rad/s'yi geçmez. Yüksek hız bir hedef değil. | Araştırılan olay sabit hedefteki salınım; hız, kazanç ekseninin bir sonucu. |
| Hedef hassasiyet | Sınırın ölçüm hassasiyeti: açıda ±1° (sınır bölgesinde 1–2° adım), kazançta bir tarama adımı (≈ %10). Salınım genliği ve θ_d ölçümünde ±0,27° (motor enkoderi). Konumlama doğruluğu bir hedef değil. | Başarı ölçütleri (B1–B3) bu çözünürlüklerin üstünde tanımlandı. |
| Açı taraması | Genelde 10°, 0° ve 180° civarında 1–2° | Simülasyonda sınır bölgeleri bu açılarda. |
| Kol ve yük | 15 cm alüminyum lama (≈20 g) + değiştirilebilir uç kütlesi 0 / 20 / 50 g → mgℓ ≈ 0,015 / 0,044 / 0,088 N·m | γ'yı açıdan bağımsız değiştirme düğmesi. Karşı ağırlık H için aynı düğme. |
| Boşluk | Motorun kendi boşluğu + ayarlanabilir kaplin 0 / 1,5 / 3 / 5° | Simülasyonda en güçlü düğme; kaplinin katkısı bilinen boşluk. 0° ayarı motorun kendi boşluğunu ölçmek için. |
| Kazanç (bant genişliği) | ω_c ≈ 30–45 rad/s (JGB37'nin tork sınırı, `simulasyon/motor_jgb37.m`); hedef ρ ≈ 0,25–0,40 (r_gs ≈ 0,5–0,8) | Ghaffari'nin rezonans LC rejimi (DF geçerli); simülasyonda ölçekleme yasası burada sağlam. ρ ve r_gs değerleri JGA25 parametreleriyle hesaplandı; JGB37'nin tanılanan J_M ve K_s değerleriyle yeniden hesaplanacak. Hedef bölge kaçarsa kaplin malzemesi (K_s) ile ayarlanır. |
| Kontrolcü | PID (türev motor enkoderinden) ve karşılaştırma için Ghaffari'nin P–PI yapısı | Ghaffari ile birebir karşılaştırma. |
| Ölçüm çözünürlüğü | Kol açısı AS5600 12 bit = 0,088°; motor enkoderi kol tarafında 0,27° (JGB37-520 1:30: 11 darbe × 4 kenar × 30 = 1320 sayım/tur) | θ_d çözünürlüğünü motor enkoderi sınırlar: 3° boşluk ≈ 11 adım. Bu sınır makalede açıkça yazılacak. |
| Örnekleme | 1 kHz (ESP32) | Simülasyonun gerçekçi modeliyle aynı. |
| Tork ve akım | JGB37-520 nominal ≈ 0,34 N·m @ 1 A, durma ≈ 0,49 N·m / 2,3 A; DRV8874 akım sınırı ≈ 2 A | Salınım deneyleri kısa; akım INA228 ile, sıcaklık TMP117 ile izlenir. |
| Bütçe | Sabit bir tavan yok; 3. aşamada birden fazla malzeme listesi (ekonomik / dengeli / üst sınıf) hazırlanacak, seçim danışmanla yapılacak. Bugünkü dengeli liste ≈ 639 TL + 13 € + 70 $ (motor + elektronik, mekanik hariç). | Ölçüm kalitesi ile maliyet arasındaki seçim, mimari belli olunca yapılmalı. |
| Süre | Sınav takvimine bağlı değil; projenin yapılabilir süresi ≈ 4–5 ay (aşama tablosu aşağıda) | Teori ve donanım kolları paralel yürütülür |

**Kapsam dışı:** hareket halinde boşluk geçişi, esnek kol, çok eklemli kol, çift motorlu aktif ön yük. Gözlemci tasarımı ve açıya göre geri besleme harmanlama (O) ana katkı tuttuktan sonra uzantı olarak ele alınır.

**Yapılabilir süre (aşama aşama):**

İki kol paralel yürür: **teori kolu** (4a–4b) ve **donanım kolu** (5a–5c). Deneyler (6a) iki kolun buluştuğu yerde başlar.

| Aşama | İş | Süre | Bağımlılık |
|---|---|---|---|
| 1–3 | Framing, donanım/yazılım planı, malzeme listeleri; danışmanla netleştirme | 1 hafta | — |
| 4a | Literatür sonucunun yeniden üretimi (önce Ghaffari 2013, sonra Sun 2023), oran eşlemesi | 2–3 hafta | 1–3 |
| 4b | İki girişli DF türetimi, sınır öngörüsü; simülasyonla karşılaştırma; rejimlerin ayrımı (sönümlü / zorlanmış / LC / kararsız) | 3–4 hafta | 4a |
| 5a | Sipariş ve teslim; bu sürede firmware iskeleti ve veri kayıt betiği yazılır | 2–3 hafta | 3; 4a ile paralel |
| 5b | Mekanik tasarım ve 3B baskı (kaplin, gövde, kol), montaj, kablolama | 2 hafta | 5a; 4b ile paralel |
| 5c | Sensör kalibrasyonu, alt sistem testleri, sistem tanılama (J, b, K_s, boşluk, sürtünme, ölü bant) | 2–3 hafta | 5b |
| 6a | Açı × kazanç deneyleri: 3 kurulum × ≈20 açı × ≈6 kazanç × 3 tekrar ≈ 1080 kısa deney (otomatik betikle) | 2–3 hafta | 5c, 4b |
| 6b | Kaynak ayrıştırma senaryoları (L) ve dengeleme deneyleri (H) | 1–2 hafta | 6a |
| 6c | Analiz, belirsizlik, model–deney farkları, makale yazımı (yöntem bölümleri 6a sırasında başlar) | 3–4 hafta | 6a–b |

**Toplam ≈ 4–5 ay (16–21 hafta).** Kritik yol donanım kolu: 1–3 → 5a → 5b → 5c → 6a → 6b → 6c. Teori kolu (5–7 hafta), donanım hazırlığının (6–8 hafta) içine sığıyor.

## 8. Riskler ve B planları

| Risk | Belirti | B planı |
|---|---|---|
| DF türetimi gecikir ya da tutmaz | 4b uzar; öngörü simülasyondan uzak | Deneyler durmaz; deney önce simülasyonla karşılaştırılır. DF'nin bozulduğu bölgede kesin parçalı doğrusal çözüm (Kollár / Esbrook) kullanılır. |
| Motorun kendi boşluğu çok büyük ya da düzensiz (eksantriklik, açıya göre değişen boşluk) | Kaplin 0° ayarında θ_d genişliği açıya göre değişir | Boşluk her θ₀'da ölçülür ve γ hesabına o açının boşluğu girer. Gerekirse daha düzgün dişli kutulu motor (yükseltme yolu). |
| Sürtünme baskın (φ büyük), boşluk salınımını maskeler | Salınım her açıda; θ_d kenarlara değmez | Daha yüksek kazanç ya da daha büyük kaplin boşluğuyla ρ ve γ hedef bölgeye çekilir. L senaryosu zaten sürtünme etkisini ayrıca ölçer. |
| Motor tork ya da ısı sınırı | Akım doyumu; motor gövdesi ısınır | Kısa deneyler, soğuma beklemesi (betikte otomatik), uç kütlesi 50 g yerine 20 g. |
| Hız kestirimindeki nicemleme ve gecikme | Türev terimi gürültülü; sınır filtre ayarına duyarlı | Filtre sabit tutulur, kaydedilir ve modele girer; gerekirse enkoder kenar zamanlamasıyla hız ölçümü (bkz. `mimari.md`). |
| Ölçülen sınır deneyler arasında dağınık | Tekrarlar arası yayılım büyük | Sıcaklık eşitleme, tekrar sayısını artırma, başlangıç koşulunu sabitleme (simülasyonda iki kararlı durum şeridi görülmüştü). |
| Sipariş gecikmesi | 5a uzar | Teori kolu ve firmware iskeleti paralel; yerli muadil parçalar (3. aşamadaki ekonomik liste). |
