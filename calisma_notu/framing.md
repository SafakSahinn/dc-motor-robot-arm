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
