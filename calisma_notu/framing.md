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
| B12 | Yüz kestirimi doğruluğu (onaylandı, 6 Kasım 2026) | Bant içinde (θ, 180°'nin 1° yakınında) her senaryoda **son yüz doğru**: son 1 s'deki temas örneklerinin çoğunluğunda kestirilen yüz gerçek yüzle aynı. Hedef %100 (42/42). Zaman içindeki ŝ doğruluğu ayrıca raporlanır ama ölçüt değil |
| B13 | Yoklamanın bedeli (onaylandı, 6 Kasım 2026) | Yoklama sırasında ve sonraki 0,3 s'de kolun en büyük hareketi **≤ 0,5°** |

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
- **Ölçüt önerisi:** H7 iş sırası (2)'den sonra yeniden yazıldı, güncel hâli aşağıda, "İş sırası (2)" alt bölümünün sonunda. B12 ve B13 onaylandı (6 Kasım 2026): B12 = her senaryoda son yüz doğru, B13 = yoklamada kol hareketi ≤ 0,5° (tanımlar "Ek başarı ölçütleri" tablosunda).
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
| var | AS5600 (0,0029°) | 10/42 | 42/42 | 20/42 | 42/42 | 31/42 | **42/42** (0,18°) | 42/42 |
| yok | ideal | 4/42 | 4/42 | 42/42 | 42/42 | 42/42 | **42/42** (0,00°) | 8/42 |
| yok | 0,017° | 4/42 | 4/42 | 42/42 | 42/42 | 20/42 | **42/42** (0,02°) | 12/42 |
| yok | 0,27° | 7/42 | 7/42 | 33/42 | 42/42 | 10/42 | **37/42** (0,54°) | 20/42 |
| yok | AS5600 (0,0029°) | 4/42 | 4/42 | 42/42 | 42/42 | 38/42 | **42/42** (0,03°) | 7/42 |

Bulgular:
- **Önerilen kestirici: olay + yoklama + rampa.** Motor enkoderi 0,017° ya da daha inceyse 4 koşu türünün hepsinde 42/42. Kalıcı hata ≤ 0,18°, yani üst sınırla aynı düzeyde. Yoklamada kolun en büyük hareketi ≤ 0,32° (B13 önerisi 0,5°). Yanlış yüze düşülen koşularda yakalama süresi (son |e| > 0,5° anı − olay anı) ortalama 2,3 s (ideal) / 2,8 s (0,017°), en çok 6,3 s; üst sınırda 2,2 s. Sürenin büyük kısmı düzeltme hareketinin kendisi (rampa + yerleşme).
- **Edilgen sign(u) sürtünmede çalışmıyor:** 20/42. Bozucusuz 14 senaryonun hiçbirinde tutmuyor: integratör yapışma sürtünmesine yaslanınca u ≈ 0,06 N m'ye çıkıyor, dişli torku ise 0,003. Sürtünmesizde 42/42. Bu, iş sırası 1'deki "durgun akım işareti kör" bulgusunun doğrudan sınanması; körlüğün nedeni sürtünme. Zaman içinde ŝ doğruluğu edilgende ort. 0,54, olay+yokta 0,996 (ideal).
- **İki yöntem birbirini tamamlıyor.** Olay tek başına, kol "sessizce" konunca kaçırıyor (0,017°'de 180,75° ve 181°'ye alttan gelişte 4 senaryo): kol karşı yüze yavaş düşüyor, çarpma F_s'yi aşmıyor, motor kıpırdamıyor, yani enkoder hiçbir şey görmüyor. Yoklama bunları yakalıyor. Yoklama tek başına ise düzeltme hareketinin kendisinin yol açtığı düşüşleri bir sonraki yoklamaya kadar göremiyor ve ince enkoderde 24/42'de kalıyor. 2 s'de bir ek yoklama (`/p`) hiçbir koşuda sonucu değiştirmedi.
- **Rampa sürtünmesizde şart:** basamakla 8/42, yüz seçimi son 3 s'de 9 kez değişiyor (iş sırası 2'deki röle benzeri salınım). Rampayla 42/42 ve hiç avlanma yok. Üst sınırın (basamak) sürtünmesizde 4/42'de kalması da aynı mekanizma. Sürtünmeli ikizde rampa ile basamak arasında fark yok.
- **Enkoder çözünürlüğü belirleyici; 0,27° yetmiyor.** Sürtünmeli ikizde 0,27°'lik enkoderle en iyi yöntem 4/42. Neden: çarpma ve 0,5°'lik yoklama itişi motoru bir enkoder adımı mertebesinde oynatıyor. Gözlemcinin dişli torku tahmini nicemleme gürültüsünde kayboluyor. Ön denemelerde 0,068° (×4) karışık, 0,017° (×16) ve daha incesi tutarlıydı. 0,017° kol tarafında ≈ 21 000 adım/tur, N = 30'la motor milinde ≈ 700 adım/tur (≈ 176 darbe/tur dörtlü kodlama); motor miline takılan 12 bitlik manyetik enkoder (ör. AS5600) kol tarafında ≈ 0,003° verir. Bu bir donanım kararı: **kol tarafında yine sensör yok**, yalnız motor enkoderi incelir.
- **Tasarım sırasında çıkan, yazıya geçmeye değer üç gözlem:** (i) yoklamada "temas mı" sorusuna yol süresiyle cevap verilemiyor. Dişli yayı yumuşak (K_s = 10 N m/rad), temasta da motor ilk 20–30 ms'de yay sıkışırken neredeyse serbest gibi ilerliyor. Ayırt eden şey gözlemcinin dişli torku tahmini (temasta ≈ 0,1 N m, boşlukta ≈ 0). (ii) Yoklama torku tutma torkunun üstüne eklenmemeli. Durgunlukta integratör sürtünmeye yaslanıp u'yu 0,06 N m'ye çıkarabiliyor; itiş mutlak tork olmalı. (iii) "Motor durgun" kararı kolun durduğunu söylemiyor. 0,3 s beklemede yoklama, kol boşlukta hâlâ 5°/s ile düşerken başladı; 1 s beklemede ise ince enkoder yapışma-kayma kıpırtısını gördüğü için motor hiç o kadar durgun sayılmadı. 0,5 s seçildi.
- **H7'ye göre:** H7 olay + yoklama ile, motor enkoderi ≤ 0,017° şartıyla ikizde sağlanıyor. Kalıcı hata yanlış yüzde ≈ 3°'den ≤ 0,18°'ye iniyor, edilgen yöntem sürtünmede 20/42 iken kestirici 42/42. Mevcut 0,27°'lik enkoderle sağlanmıyor.
- **B12 için not:** "son yüz doğru" ölçüsüyle olay+yok 42/42 (%100). Zaman içinde ŝ doğruluğu ortalaması ise ideal enkoderde 0,996, 0,017°'de 0,942 (en kötü koşu 0,40: sessiz konmadan sonra yoklamaya kadar geçen sürede ŝ yanlış). Karar: B12 "son yüz doğru" ölçüsüyle tanımlandı.
- **Sınırlar:** u ikizde uygulanan torkun kendisi, akım ölçüm gürültüsü (INA228) yok. Kontrolcünün hız terimi ikizde gerçek motor hızını kullanıyor; kestirici ise yalnız nicemli enkoderi görüyor. Sürtünme tanh ile yumuşatılmış (iş sırası 1'deki not; edilgen yöntem gerçekte daha da kötü olabilir). Gözlemci F_c, F_s, J_M, b_M'nin doğru bilindiğini varsayıyor; parametre hatasına duyarlılık sınanmadı.

**Kararlar (6 Kasım 2026, kullanıcı):**
- **Yöntem onaylandı:** olay + yoklama + rampa (ikizde `p.yuzKes = 'olay+yoklama'`, rampa 0,5 s).
- **Enkoder kararı:** AS5600 motor miline (arka mil ucu, eksenel mıknatıs) konur; motor tarafı konum kol tarafında ≈ 0,003° (12 bit × N = 30) çözünürlükle ölçülür, hedef ≤ 0,02°. Kol tarafında kontrolcüye giren sensör yine yok. Kol milindeki AS5600 doğrulama sensörü olarak kalır (kullanıcı kararı): iki AS5600, adresleri aynı (0x36) olduğundan motor tarafındaki I²C-0'da (1 MHz, INA228 ile), kol tarafındaki I²C-1'de (400 kHz, TMP117'lerle). Montaj, çok tur sayımı ve kalibrasyon: `mimari.md` §3, §4.1, §5.
- **B12 ve B13 onaylandı:** B12 = her senaryoda son yüz doğru (olay+yok 42/42, %100); B13 = yoklamada kol hareketi ≤ 0,5° (ölçülen en çok 0,32°; 1 kHz ayarlı kestiricide 0,43°, aşağıdaki ek).

**Ek: AS5600 motor milinde, gerçekçi zamanlama (6 Kasım 2026).** Betik `simulasyon/5_planlama/yuz_kestirici_as5600.m` (log yanında); aynı 42 senaryo ve H7. Yukarıdaki tablo ve `yuz_kestirici.m`'nin tüm sonuçları kontrolcü ve kestirici **10 kHz'te** (p.Ts = p.dt = 0,1 ms) çalışırken alındı; ESP32 döngüsü 1 kHz. İkize iki seçenek eklendi (varsayılan kapalı): motor ölçümüne gecikme `p.gM` [s] ve gürültü `p.nM` [rad, kol tarafı]. Kestiricide iki ayar eklendi (varsayılanlar eski davranış): `p.yokOrta` (yoklamanın geri dönüşünde geri itişten frene geçiş noktası, varsayılan 0,5) ve `p.vDurF` (durgunluk kararı için hız kestirimi süzgeci [Hz], varsayılan Inf). Gecikme 0,4 ms (SF = 11 filtresi 0,286 ms + iç örnekleme + I²C), gürültü 0,043° RMS motor milinde (veri sayfası, SF = 11) → kol tarafında 0,0014°.

| Sürtünme | Koşu | edilgen | olay+yok (eski ayar) | **olay+yok ayarlı** (yokOrta 0,6, vDurF 10 Hz) |
|---|---|---|---|---|
| var | 10 kHz | 20/42 | 42/42 (B13 0,28°) | 42/42 (0,36°) |
| var | 1 kHz | 20/42 | 42/42 (0,23°) | 42/42 (0,33°) |
| var | 1 kHz + 0,4 ms gecikme | 20/42 | 42/42 (0,24°) | 42/42 (0,33°) |
| var | 1 kHz + gecikme + gürültü | 20/42 | 41/42 (yoklama hiç başlamıyor) | **42/42** (0,43°) |
| var | zor: 1 ms gecikme + 3× gürültü | 10/42 | 37/42 (yoklama yok) | **42/42** (0,38°) |
| yok | 10 kHz | 42/42 | 42/42 (0,27°) | 42/42 (0,31°) |
| yok | 1 kHz | 42/42 | **30/42** (1,05°) | 42/42 (0,28°) |
| yok | 1 kHz + gecikme | 42/42 | **16/42** (3,54°) | 42/42 (0,30°) |
| yok | 1 kHz + gecikme + gürültü | 42/42 | 42/42 (yoklama yok) | 42/42 (0,30°) |
| yok | zor | 4/42 | 42/42 (yoklama yok) | 42/42 (0,29°) |

Ayarlı kestiricide kalıcı hata her satırda ≤ 0,21°, ŝ doğruluğu ortalaması ≥ 0,98 (en kötü koşu 0,63, zor koşulda).

- **AS5600 motor milinde yeterli.** İdeal zamanlamada 0,017°'lik enkoderle aynı sonuç: olay+yok iki sürtünmede de 42/42, en kötü 0,18° / 0,03°.
- **1 kHz'te yoklamanın geri dönüşü kolu devirebiliyor (sürtünmesizde).** Yoklama sırasında kol desteksiz kalıp ≈ 0,12° düşüyor. Motor bang-bang ile tam başlangıç açısına döndüğünde yayı fazladan sıkıştırıp kolu yukarı fırlatıyor. 10 kHz'te kol 180°'nin altında kalıyordu; 1 kHz'te fren biraz geç algılanınca kol 180°'yi aşıp karşı yüze düşüyor. Sürtünme kolu frenlediği için sürtünmeli ikizde görülmüyor. Çözüm: frene yolun %60'ında geçmek (yokOrta 0,6); motor başlangıcın ≈ %20 yol önünde durur, son yaklaşmayı kontrolcü yumuşak yapar. Bedeli: B13 0,23°'den 0,33°'ye.
- **Enkoder gürültüsü yoklamayı kapatıyor.** 0,0014° RMS gürültü gözlemcinin hız kestirimini 0,01 rad/s'lik durgunluk eşiğinin üstünde tutuyor; motor hiç "durgun" sayılmadığı için yoklama başlamıyor, kestirici yalnız olaya kalıyor (sürtünmede sessiz konmaları kaçırıyor). Çözüm: durgunluk kararını 10 Hz'te süzülmüş hız kestirimiyle vermek (vDurF 10). Olay sezicisinin kendisi gürültüden etkilenmedi.
- **Sonuç:** ayarlı olay+yoklama, AS5600 motor milinde, 1 kHz, 1 ms'ye kadar gecikme ve 3× veri sayfası gürültüsünde 10/10 koşu türünde 42/42; B13 en çok 0,43° (≤ 0,5° ölçütünün içinde ama pay azaldı); B12 her koşu türünde 42/42 (son yüz doğru, H7'nin parçası). Donanım için önerilen ayar bu.
- **Sınırlar (bu ek için):** AS5600'ün doğrusal olmama hatası (mıknatıs hizasına bağlı, motor milinde ±1°'ye kadar, kol tarafında ≈ 0,03°, her motor turunda tekrarlayan) modellenmedi; gürültü beyaz varsayıldı; I²C okuma hatası/atlaması yok. Yukarıdaki genel sınırlar (akım gürültüsü yok, kontrolcü hız teriminde gerçek motor hızı) burada da geçerli.

### İş sırası (4): yük ve model parametresi duyarlılığı (6 Kasım 2026)

Betik: `simulasyon/5_planlama/duyarlilik.m` (log yanında). Gerçekçi koşul: 1 kHz, AS5600 motor milinde, 0,4 ms gecikme, 0,043° RMS gürültü (motor milinde), ayarlı olay+yoklama (yokOrta 0,6, vDurF 10 Hz). Aynı 42 senaryo; ölçüt H7 (B12 = son yüz doğru dahil) ve B13 ≤ 0,5°. Her satırda tek büyüklük değişir. **mgℓ, K_s, r:** ikizin gerçeği değişir, ofset tablosu ve kestirici nominal değeri bilir (ikize `p.rN`, `p.KsN`, `p.mglN` eklendi, varsayılan = gerçek). **F_c, F_s, J_M, b_M:** ikiz nominal, gözlemcinin bildiği değer yanlış. Kontrolcü kazançları her satırda nominal. mgℓ değişirken J_L sabit (yalnız yerçekimi torku değişir).

| Büyüklük | Güvenli aralık (sürtünmeli; H7 42/42 ve B13 ≤ 0,5°) | Bozulduğu yer | İkizdeki tanılama doğruluğu (`deney_protokolu.md`) |
|---|---|---|---|
| mgℓ (gerçek) | ×0,8–1,2 (sınanan uçlar) | — | %0,1 |
| K_s (gerçek) | ×0,8–1,2 | — | %0,5–1 |
| r (gerçek) | ×0,9–1,2 (en kötü 0,36°) | ×0,8: 21/42, B12 31/42 | %0,2 |
| F_c (gözlemcinin bildiği) | ×0,5–1,2 | ×1,3: B13 3,6° (H7 42/42); ×1,5: 31/42 | %1 |
| F_s (bildiği) | ×0,5–1,5 | — | %1–2,5 |
| J_M (bildiği) | ×0,8–1,3 | ×0,7: 33/42 (sürtünmesiz 26/42); ×1,5: B13 3,65° | %0,5 |
| b_M (bildiği) | ×0,5–1,5 (sonuç hiç değişmiyor) | — | %1,4 |

Sürtünmesiz ikizde mgℓ, K_s, r, b_M bütün satırlarda 42/42; J_M ×0,7'de 26/42 (×0,5 ve ×0,6'da 42/42, tekdüze değil).

- **Kestirici yükten ve dişli sertliğinden bağımsız.** mgℓ ve K_s ±%20'de sonuç değişmiyor: 180° çevresinde sin θ ≈ 0,01–0,02, ofsetin mgℓ/K_s kısmı ≈ 0,02°, hatası ölçülemeyecek kadar küçük. Uç kütlesi değiştirildiğinde tablonun yeniden ölçülmesi gerekmiyor.
- **En hassas büyüklük boşluk r, ama tek yönlü.** r olduğundan büyük bilinirse (gerçek ×0,8) ofset kolu boşluğun ötesine iter, 180°'nin hemen yanında kolu tepeden aşırır: 21/42, yüz bile yanlış (B12 31/42). Küçük bilinirse (gerçek ×1,2) yalnız kalıcı hata büyür (0,35°). ±%10'da güvenli. D4'ün doğruluğu (%0,2) bu payın 50 katı küçük.
- **F_c fazla bilinirse yoklama temas kaçırıyor.** Temas kararı "itiş yönündeki dişli torku − F̂_c > eşik"; F̂_c büyükse temas torku eksik görülür, itiş yokTmax'a kadar sürer, kolu 3,6° oynatır. Eksik bilinmesi zararsız (×0,5'te 42/42). **Sonuç:** asimetri var; donanımda F̂_c tanılanan değerin biraz altında (ör. ×0,9) seçilmeli. Bu önemli, çünkü F_c ısınmayla değişebilir (dişli yağı); D1'in %1'lik doğruluğu sıcaklık kaymasını kapsamıyor. TMP117 kaydıyla F_c'nin sıcaklığa bağımlılığı ölçülmeli.
- **J_M eksik bilinirse gözlemci kararsızlaşmaya yaklaşıyor.** ×0,7 ve altında kalıcı hata 1–2°'ye çıkıyor (yüz doğru, kontrol döngüsü avlanıyor); fazla bilinmesi ×1,3'e kadar zararsız, ×1,5'te bir yoklama temas kaçırıyor. D1'in doğruluğu (%0,5) bol pay bırakıyor.
- **H7'ye göre:** gerçekçi tanılama hatalarıyla (D1–D5'in ikizdeki doğrulukları) H7 ve B13 sağlanıyor; güvenli aralıklar bu hataların 10–50 katı. Asıl risk tanılama değil, **zamanla kayma**: F_c (sıcaklık) ve r (aşınma). İkisi için de güvenli taraf belli (F̂_c'yi düşük, r̂'yi düşük seçmek).
- **Sınırlar:** tek büyüklük değişimi (birleşik hatalar sınanmadı); F_c'nin sıcaklıkla değişimi zaman içinde değil, sabit bir sapma olarak sınandı; akım ölçüm gürültüsü yok (u gerçek tork).

### İş sırası (5a): gözlemcinin torku INA228 ölçümünden (6 Kasım 2026)

Betik: `simulasyon/5_planlama/akim_gurultu.m` (log yanında). Şimdiye kadar tork gözlemcisi uygulanan torku (komut u) hatasız görüyordu. Donanımda tork k_t·i, i Adafruit INA228'den. İkize iki seçenek eklendi (varsayılan kapalı, gerileme temiz: `belirsiz_bant` ve `yuz_kestirici_as5600` loglarında yalnız tarih değişti):

- `p.tOlc`: gözlemci u yerine ölçümü görür: kazanç × (gerçek torkun dönüşüm penceresi `tPen` boyunca ortalaması, `tGec` önce biten) + ofset + beyaz gürültü (her kontrol örneğinde bir; ayrı rastgele akış).
- `p.akimW`: tesise uygulanan tork komutu birinci derece izler (akım döngüsünün bant genişliği).

**Sayılar.** Veri sayfası (TI INA228): dönüşüm süresi 50 µs – 4,12 ms (8 seçenek), ortalama 1–1024; şant ofseti en çok ±1 µV, kazanç hatası en çok ±%0,05. Adafruit kartının şantı 15 mΩ (ürün sayfası). k_t kol tarafında 12 V / 333 rpm = 0,344 N·m/A, yani 0,001 N·m ≈ 2,9 mA. Ofset 1 µV / 15 mΩ = 67 µA ≈ 2·10⁻⁵ N·m, kazanç hatası ihmal edilebilir. **Gürültü veri sayfasında yalnız grafikte verildiği için taranıyor (doğrulanmadı).** PWM dalgalanması (20 kHz, L_a 2,5 mH, 12 V: tepeden tepeye ≈ 60 mA ≈ 0,02 N·m) 0,54 ms'lik dönüşümde ≈ 11 PWM periyodu üzerinden ortalanır, bu nedenle beklenen RMS birkaç mA (≈ 0,001 N·m) mertebesinde; bu da doğrulanmadı.

**Taban:** pencere 0,54 ms (1 kHz döngüye sığan en uzun tek dönüşüm), okuma gecikmesi 0,1 ms, akım döngüsü 500 Hz. Koşul `duyarlilik.m` ile aynı (1 kHz, AS5600 motor milinde, ayarlı olay+yoklama), aynı 42 senaryo. Her satırda tabandan tek değişiklik.

| Büyüklük | Güvenli aralık (iki ikizde de H7 42/42 ve B13 ≤ 0,5°) | Bozulduğu yer | Beklenen donanım değeri |
|---|---|---|---|
| Taban (INA228, ölçüm açık) | 42/42, B13 0,33° (sürtünmesiz 0,30°) | — | — |
| Gürültü (RMS) | ≤ 0,02 N·m (≈ 58 mA) | 0,03: 40/42 (sürtünmesiz 38/42, B13 1,03°); 0,05: 34/42 ve 25/42, yoklama hiç başlamıyor | ≈ 0,001 N·m (doğrulanmadı) |
| Okuma gecikmesi | ≤ 2 ms | 5 ms: 28/42 ve 29/42 | ≈ 0,1 ms |
| Dönüşüm penceresi | ≤ 4,2 ms (1,052 ms × 4) | 16,8 ms: 39/42, sürtünmesiz 16/42 | 0,54 ms |
| Akım döngüsü bandı | 500 Hz (taban) | sürtünmesiz 100 Hz: B13 0,98° (H7 42/42); 50 Hz: 0/42 | 500 Hz hedef |
| Ofset | ±0,01 N·m (≈ 29 mA) | ±0,02: sürtünmeli 24–29/42, sürtünmesiz 16/42, B13 3,7° | 2·10⁻⁵ N·m (veri sayfası) |
| Kazanç (k_t hatası) | ×0,9–1,1 | ×0,8: sürtünmeli B13 3,69°; ×1,2: sürtünmesiz B13 1,06° (H7 her yerde 42/42) | k_t tanılaması %0,3 |

- **Gürültüye pay geniş.** 0,02 N·m'ye kadar sonuç tabanla aynı. Beklenen düzeyin (≈ 0,001) yaklaşık 20 katı. Bozulma 0,03'te başlıyor; 0,05'te yoklama hiç başlamıyor, çünkü gürültü w^'yi durgunluk eşiğinin üstünde tutuyor (iş sırası 3'teki enkoder gürültüsüyle aynı mekanizma). Eşiklerin (`yokEsik` 0,04, `tauEsik` 0,015) yeniden ayarlanması gerekmedi.
- **Tohum kontrolü:** 0,001 N·m satırında B13 0,63° çıktı (0,003'te 0,41°, tekdüze değil). 5 tohumla yinelendi (gürültü 0, 0,0003, 0,001, 0,003; iki ikiz): H7 her koşuda 42/42. B13 > 0,5° 40 koşu × 28 senaryo içinde yalnız bir kez (0,001, tohum 1); öbür koşularda B13 en çok 0,39°. Kaynak tek bir yoklamada rastlantı; ölçüt sınırında, izlenmeli.
- **Ofset ve kazanç, F̂_c ile aynı mekanizma.** Temas kararı "itiş yönündeki dişli torku tahmini − F̂_c > eşik". Torkun eksik ölçülmesi (ofset ya da k_t ×0,8) temas torkunu küçük gösteriyor, itiş yokTmax'a kadar sürüyor, kol 3,7° oynuyor. İş sırası (4)'te F̂_c +%30 (≈ +0,012 N·m) aynı sonucu vermişti. Burada sınır ±0,01–0,02 N·m arasında. INA228'in kendi ofseti bunun ~400'de biri, asıl risk sıfır kalibrasyonu ve k_t·i ile gerçek motor torku arasındaki fark (örn. dişli verimi). **Öneri:** akım sıfırı her deneyden önce motor kapalıyken ölçülsün (`mimari.md` kalibrasyon adımı 3'e eklenebilir).
- **Gecikme ve pencere:** 1 kHz döngüde tek dönüşüm (0,54 ms) ya da 4'lük ortalama rahat. Uzun ortalama (≥ 16 ms) gözlemciyi bozuyor. INA228'i 500 Hz'te okumak (`mimari.md` seçeneği) ≈ 2 ms gecikme demek, güvenli bölgede.
- **Akım döngüsü yavaşlarsa** (ölçüm değil, tesise giden tork) sürtünmesiz ikizde yoklama bozuluyor: 100 Hz'te B13 0,98°. Mod 3'ün akım döngüsü (500 Hz tasarım) en az 200 Hz olmalı; 100 ile 500 Hz arası sınanmadı.
- **Sınır (elektrik modeli):** `kol_benzetim` tork girişli (mod 3 ideal + burada eklenen birinci derece akım döngüsü). Mod 1'in (gerilim sürüşü) zıt EMK'sı ve R_a, L_a dinamiği yalnız Simscape modelinde (`sm_model_kur(..., 'elektrik')`). Yüz kestirici mod 1'de çalıştırılacaksa ayrıca Simscape'te sınanmalı; bu turda yapılmadı. Ayrıca PWM dalgalanmasının örtüşmesi (aliasing) beyaz gürültüyle temsil edildi.

### İş sırası (5b): zamanla kayan sürtünme ve birleşik hatalar (8 Kasım 2026)

Betik: `simulasyon/5_planlama/kayan_surtunme.m` (log yanında). İkize `p.FcKay` eklendi: tesisteki F_c ve F_s birlikte m(t) = 1 + (FcKay − 1)·min(t/FcKayT, 1) ile çarpılır; kestiricinin bildiği F̂_c değişmez (varsayılan kapalı, gerileme temiz: `belirsiz_bant` ve `yuz_kestirici_as5600` loglarında yalnız tarih değişti). Taban 5a'nın "INA228 taban" koşulu (1 kHz, AS5600 motor milinde, ayarlı olay+yoklama, gözlemci torku INA228'den). Kestirici iş sırası (4)'ün önerisiyle **F̂_c = 0,9 × nominal**. Aynı 42 senaryo.

| Durum | H7 | B13 en çok | Not |
|---|---|---|---|
| F̂_c nominal (×1,0), gerçek nominal | 42/42 | 0,33° | Karşılaştırma |
| F̂_c ×0,9, gerçek F_c sabit ×0,7 … ×1,3 (7 satır) | 42/42 her satırda | 0,33–0,57° | En kötü \|e\| 0,25° |
| F̂_c ×0,9, gerçek F_c koşu boyunca rampa 1 → ×0,5 / 0,7 / 1,3 / 1,5 | 42/42 her satırda | 0,34–0,37° | Darbe kaymanın ortasında |
| ±%10–20 köşeler (gerçek r ×0,9 / 1,1, Ĵ_M ×0,8 / 1,2, gerçek F_c ×0,7 / 1,3; hepsinde gerçek mgl ×1,2, K_s ×0,8), 8 köşe | 21–42/42 (4 köşe 42/42) | 0,35–1,69° | Bozulan köşelerin hepsinde ya gerçek r ×0,9 (boşluk olduğundan büyük biliniyor) ya da Ĵ_M ×0,8 + F_c ×0,7 var |
| Aynı 8 köşe + INA228 ofseti +0,005 N·m ve gürültü 0,003 N·m | 23–42/42 | 0,35–3,92° | INA hatası tek başına zararsızdı (5a) |
| **Gerçekçi köşeler** (gerçek r ×0,95 / 1,05, Ĵ_M ×0,9 / 1,1, gerçek F_c ×0,7 / 1,3, mgl ×1,2, K_s ×0,8), 8 köşe | 7 köşe 42/42, 1 köşe 40/42 | 0,38–3,79° | 40/42: r ×0,95, Ĵ_M ×1,1, F_c ×1,3; 179–179,25° üstten, yanlış yüz |
| Aynı gerçekçi köşeler + INA hatası | 4 köşe 42/42, diğerleri 37–41/42 | 0,38–3,79° | — |
| Sürtünmesiz ikiz, r ve Ĵ_M ±%10–20 köşeleri | 42/42 her köşede | 0,31–1,09° | — |

- **Kayma tek başına sorun değil.** F̂_c = 0,9 × nominal sabit tutulurken gerçek sürtünme ×0,5 ile ×1,5 arasında (sabit ya da koşu içinde kayarak) değişse de her satır 42/42, B13 ≤ 0,57°. Isınma kaynaklı F_c kaymasının (tipik ±%10–30) payı geniş. İş sırası (4)'te F̂_c'nin %30 fazla bilinmesi yoklamayı bozmuştu; burada gerçek ×0,7 (F̂_c gerçeğin 1,29 katı) zararsız çıktı. Fark: burada F_s de aynı oranda düşüyor ve gözlemci torku INA228'den geliyor. İki durum aynı değil, ikisi de logda.
- **Hatalar birleşince bozuluyor.** Tek parametre değişiminde güvenli bulunan aralıklar (iş sırası 4: r ×0,9–1,2, Ĵ_M ×0,8–1,3) birlikte uygulanınca bazı köşelerde H7 21/42'ye iniyor. En tehlikeli yön boşluğun olduğundan büyük bilinmesi (gerçek r ×0,9): ofset kolu fazla itiyor, sürtünme yüksekse yanlış yüze düşen kol yakalanmıyor.
- **Gerçekçi büyüklükte bile pay dar.** Tanılama doğruluğunun (r %0,2, J_M %0,5) 10–25 katı hatalarla (r ±%5, Ĵ_M ±%10) H7 37–42/42. İki ayrı belirti var:
  1. **Yanlış yüz** (r ×0,95 + F_c ×1,3): kol 179–179,25°'de üstten gelirken yanlış yüzde kalıyor (e ≈ 3,2°). Yalnız 1–2 senaryoda.
  2. **B13 ihlali** (Ĵ_M ×1,1 + gerçek F_c ×0,7, INA hatası olsun olmasın): H7 42/42 ama yoklama kolu 3,5–3,8° oynatıyor. Motor ısınıp sürtünme düşünce sabit 0,12 N·m'lik yoklama itişi kolu boşluğun karşı yüzüne kadar taşıyor, sonra kontrolcü geri topluyor.
- **Yorum.** Bu köşeler gerçek tanılama hatalarından çok büyük, bu yüzden "yöntem çalışmıyor" anlamına gelmiyor. Ama zamanla kayan sürtünme ile küçük model hatalarının üst üste binmesi gerçek bir risk. Donanımda da görülürse iki önlem aday: (a) yoklama itişini (`yokA`) ve temas eşiğini sabit değil, son ölçülen sürtünmeye göre ölçeklemek; (b) F̂_c'yi deneyler arasında kısa bir D1 tekrarıyla güncellemek (deney protokolü §5.4'teki kayma sınaması bunu ölçecek). (a) ikizde sınanmadı.
- **Sınır:** mod 1'in (gerilim sürüşü) zıt EMK'sı burada da yok (5a'daki sınır geçerli). → İş sırası (5c)'de kapatıldı.

### İş sırası (5c): yüz kestirici mod 1'de, motorun elektrik tarafıyla (8 Kasım 2026)

Soru: D7 mod 1'de (gerilim sürüşü, V = R_a·u/K_m) koşacak. Kestirici şimdiye kadar yalnız tork girişli ikizde sınanmıştı. Mod 1'de tesis torku u − (K_m²/R_a)·φ̇ olur. Zıt EMK ek bir sönüm getirir (K_m²/R_a = 0,0141 N·m·s/rad ≈ 7·b_M), yoklama itişi motor hızlandıkça zayıflar.

- **Model.** `kol_benzetim.m`'ye `p.motorElk` eklendi (varsayılan kapalı). Beşinci durum akım: L_a·di/dt = V − R_a·i − K_m·φ̇, tesis torku K_m·i. Sürücü `blok_surucu.m`'nin vektör yazımı: mod 1 gerilim, mod 2 zıt EMK kompanzasyonu (V'ye K̂_m·v eklenir; `p.elkV = 'gozlemci'` ise v yerine gözlemcinin ŵ'si), mod 3 akım PI'ı (10 kHz, ölçüm bir adım gecikmeli). Ardından DRV8874 akım sınırı (0,43 N·m eşdeğeri) ve ±12 V. Eşdeğer motor `sim_param.m` ile aynı: K_m 0,344 V·s/rad, R_a 8,43 Ω, L_a 2,5 mH. INA228 gerçek akımı (K_m·i) görür. Firmware'in bildiği değerler `p.KmN` ve `p.RaN`.
- **Gerileme temiz.** `belirsiz_bant` ve `yuz_kestirici_as5600` loglarında yalnız tarih satırı değişti.
- **Simscape çapraz kontrolü** (`simulink/dogrula_elk.m` → log): `sm_motor_model`'e karşı 30/60/90° × r_gs 0,9 / 1,3, iki sensör düzeyi, mod 1–3 (36 hücre; 30'u ölçütü sağladı). Sönen ve 60–90°'deki salınan hücrelerde sınıf aynı, genlik ve frekans farkı ≤ %0,5 (çoğu ≤ %0,1). Ölçütü sağlamayan hücrelerin hepsi 30°/r_gs 1,3'te; bu hücre kritik sınırın (0,9–1,0) çok üstünde, V zamanın %35–50'sinde doyumda ve rejim düzensiz. Genlik ve frekans yine %0,02–1,8 içinde uyuşuyor, yalnız sınıf etiketi 1/4/5 arasında oynuyor. Aynı hücrede eski `tarama_5b` koşusu da Simscape mod 1'de sınıf 1, mod 2–3'te sınıf 5 vermişti, başlangıç sapmasına göre de değişiyordu. Ayrıca gerçekçi sensörde 60° mod 2'de bir hücre genlik 0,007°'de (eşik 0,05°) sınıf 0/1 ayrımına takıldı, bu nicemleme düzeyi.
- **Kestirici** (`5_planlama/mod1_kestirici.m` → log): taban kayan_surtunme ile aynı (F̂_c = 0,9 × nominal, gözlemci torku INA228'den), 42 senaryo.

| Durum | tork ref. | mod 1 | mod 2 | mod 2 (ŵ) | mod 3 |
|---|---|---|---|---|---|
| Nominal, sürtünmeli | 42/42 | 42/42 | 42/42 | 42/42 | 42/42 |
| Nominal, sürtünmesiz | 42/42 | 42/42 | 42/42 | — | 42/42 |
| Gözlemci INA228 yerine komut u'yu görür | 42/42 | 42/42 (sürtünmesiz de) | — | — | — |
| +INA228 ofseti 0,005 / gürültü 0,003 N·m | — | 42/42 | — | — | 42/42 |
| Firmware R̂_a eksik (gerçek R_a ×1,25, sargı ısındı) / ×0,9 | — | 42/42 / 42/42 | — | — | — |
| Gerçekçi köşeler + INA hatası (8 köşe, sıra: r0.95/1.05 × Ĵ_M 0.9/1.1 × F 0.7/1.3) | 37, 40, 42, 41, 40, 42, 42, 42 (toplam 326) | 39, **38**, 42, **37**, **38**, 42, 42, 42 (toplam 320) | — | — | — |
| F_c ×1,3 köşeleri (r ×0,95, Ĵ_M ×0,9 / 1,1), 3 gürültü tohumu | 40/40/40, 41/41/42 | **38/38/38, 37/38/38** | 40/40/40, 41/41/42 | 40/40/40, 42/40/42 | 40/40/40, 41/41/42 |

- **Mod 1 nominal koşullarda sorunsuz.** Yöntemin sınadığı her durumda 42/42, B13 ≤ 0,5°. Akım tepesi 0,37 A; V hiç doyuma gitmiyor. Gözlemci INA228 yerine komutu görse bile 42/42: zıt EMK farkı (K_m²/R_a)·ŵ gözlemcide d̂'ye karışıyor, ama 179–181°'de motor neredeyse durgun olduğundan bu fark küçük.
- **Mod 1, kırılgan köşeyi biraz genişletiyor.** 8 gerçekçi köşenin toplamında mod 1, tork girişliye göre 6 senaryo daha kaybediyor (326 → 320 / 336). Kayıp iki yerde toplanıyor: gerçek sürtünme %30 fazla ve boşluk %5 küçükken (2–4 senaryo), bir de r ×1,05, Ĵ_M ×0,9, F ×0,7 köşesinde (2 senaryo). Buna karşılık r ×0,95, Ĵ_M ×0,9, F ×0,7 köşesinde mod 1 iki senaryo daha iyi. Fark üç gürültü tohumunda da aynı, yani şans değil. Yeni kaybedilenler 181°'ye alttan gelişler: 5b'deki "179°'ye üstten gelişte yanlış yüz" belirtisinin dikin öbür tarafındaki aynası. Mod 2 (zıt EMK kompanzasyonu) kaybı tamamen geri getiriyor. Gerçek hız yerine gözlemcinin ŵ'si kullanılınca da geri getiriyor. Demek ki neden zıt EMK sönümü.
- **Yorum.** Bu köşeler tanılama doğruluğunun 10–25 katı hatalar (5b). Mod 1 D7 için kullanılabilir, ama kırılganlığa biraz katkı yapıyor. Mod 2 (ŵ ile) firmware'de tek satır: V'ye K̂_m·ŵ eklenir, ŵ zaten hesaplanıyor. Mod 3'ün (10 kHz akım döngüsü) donanımda karşılığı yok (deney protokolü §4/1).
- **Sınır:** PWM anahtarlaması yok (ortalama model). L_a tahmini (2,5 mH), K_m ve R_a veri sayfası eşdeğeri; D1 bunları ölçecek.
- **Karar (8 Kasım, onaylandı):** D7 mod 1'de; sürücü kodunda mod 2 (ŵ) yedek seçenek olarak yer alır, 179/181°'de yanlış yüz görülürse D7 mod 2'de tekrarlanır (`deney_protokolu.md` §4/6).

### Kontrolcünün hızı = gözlemcinin w^'si (6 Kasım 2026, ESP32 adım 4'ten sonra)

Betik: `simulasyon/5_planlama/hiz_gozlemci.m` (log yanında). Önceki bütün 42 senaryo sonuçlarında `p.fv = Inf` idi, yani P-PI'nin hız terimi motor hızını **hatasız** görüyordu. Donanımda bu hız tork gözlemcisinden gelecek (`mimari.md` §4.1; kartta `kontrol::HIZ_GOZLEMCI`). İkize `p.vKaynak = 'gozlemci'` eklendi (varsayılan eski davranış; gerileme temiz, `belirsiz_bant` ve `yuz_kestirici_as5600` loglarında yalnız tarih değişti). Sıra kartla aynı: v, o örnekte yüz kestirici bloğunda güncellenen w^. Kurulum (5a)'nın INA228 tabanı. Kazançlar (KV, KI, kp = 0,50²·K_s/KV) değişmedi.

| Satır | Sürtünmeli H7 / B13 | Sürtünmesiz H7 / B13 | u RMS son 1 s (sürtünmeli / sürtünmesiz) [N·m] |
|---|---|---|---|
| İdeal hız (eski sonuç) | 42/42 / 0,33° | 42/42 / 0,30° | 0,0377 / 0,0031 |
| **w^, gozW 40 Hz (taban)** | **42/42 / 0,32°** | **42/42 / 0,30°** | 0,0381 / 0,0041 |
| w^, gozW 30 Hz | 42/42 / 0,32° | 42/42 / 0,30° | 0,0365 / 0,0035 |
| w^, gozW 50 Hz | 42/42 / 0,36° | 42/42 / 0,30° | 0,0383 / 0,0051 |
| w^, gozW 20 Hz | 38/42 / 3,71° | 42/42 / 0,30° | 0,0388 / 0,0032 |
| w^, gozW 80 Hz | 41/42 / 0,37° | 39/42 / 0,29° | 0,0384 / 0,0112 |

- **Sonuç: w^ ideal hızın yerini tutuyor.** Tabanda (gozW 40 Hz) iki ikizde de H7 42/42, B13 ≤ 0,32°; kalıcı hata (en kötü 0,18°) ideal hızdakiyle (0,21°) aynı mertebede. Gürültünün torka yansıması küçük: sürtünmesiz ikizde u RMS 0,0031'den 0,0041 N·m'ye çıkıyor, doyum hiç yok. Kazanç ayarı gerekmedi.
- **gozW payı 30–50 Hz.** 20 ve 80 Hz'teki bozulmanın çoğu hız kaynağından değil, yüz kestiricinin kendisinden: aynı gozW ideal hızla da bozuluyor (20 Hz: B13 3,70°, çünkü yokTmin = 3/gozW uzuyor ve d^ yavaşlıyor; 80 Hz: ideal hızla da sürtünmeli 40/42, sürtünmesiz 41/42). w^'nin 20 Hz'te eklediği: sürtünmeli 4 senaryoda yanlış son yüz (B12 38/42); 80 Hz'te sürtünmesiz u RMS'i 3,6 katına çıkıyor (0,0112). gozW 40 Hz'te kalınıyor.
- **Kart eşdeğerliği bu modda** (`6_esp32/ktl_esdeger.m`, `KTL_VKAYNAK=gozlemci`, log `ktl_esdeger_gozlemci_log.txt`): 84 senaryonun 81'inde ayrık kararlar 8000 örneğin hepsinde aynı, |Δw^| ≤ 1,5e-7 rad/s, |Δd^| ≤ 4,5e-8 N·m. Kalan 3'ü (sürtünmeli j 12, 18, 26) **tek örneklik bir eşitlik durumu**, hız kaynağıyla ilgisiz: yoklamanın "geri itme → fren" geçişi `yol <= ykDm·yokOrta`, ykDm = 275 sayım, eşik 0,6·275 = 165, yol tam 165. İkiz bunu radyanla double hesapta "geçmedi" buluyor, kart sayım × float 0,6f ile (165,0000066) "geçti" buluyor. Kart 1 ms erken frenliyor, sonraki bütün örnekler aynı (yoklama sayıları eşit). Sonuca etkisi yok. İstenirse ileride iki tarafta da tamsayı karşılaştırmaya (10·yol ≤ 6·ykDm) çevrilebilir.

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
| Ölçüm çözünürlüğü | Kol açısı AS5600 12 bit = 0,088° (yalnız doğrulama); motor açısı arka mildeki ikinci AS5600'le kol tarafında 0,0029° (Hall enkoder 0,27°, yedek) | θ_d çözünürlüğünü artık kol AS5600'ü sınırlar: 3° boşluk ≈ 34 adım (yalnız Hall enkoderle ≈ 11 adımdı). Bu sınır makalede açıkça yazılacak. |
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
