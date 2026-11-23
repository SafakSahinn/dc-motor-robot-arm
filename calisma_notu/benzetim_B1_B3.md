# Benzetim B1–B3: önceki yöntemlerle karşılaştırma ve ön yük

Rapora eklenmez; sonraki haftaya ve yayın hazırlığına çalışma notu. Literatür ve patent dayanağı `literatur/genisletme_2026-11-21.md` §2.4–2.6.

## B1. Komut tabanlı yüz kuralları ile yalnız motor sinyalli kestirici (2026-11-21)

**Soru.** Önceki patentlerdeki kurallar (yüzü komut ya da dönüş yönünden, ya da tork işaretinden *varsayan*) 179–181° çevresinde, yani yerçekimi ön yükü sıfıra yakınken, bizim kestiricinin yaptığını zaten yapıyor mu?

**Yöntemler.** Hepsi aynı ofset tablosunu (φ_ref = θ_ref + s·r + mgℓ sin θ_ref / K_s) ve aynı 0,5 s rampayı kullanır; yalnız s'yi seçen kural farklı.

| Yöntem | Kural | Kaynak |
|---|---|---|
| Tablo | s = sign(τ_g) sabit (Toyoda'nın eşik = 0 hali) | iş sırası 1 |
| Panasonic türü | \|τ_g\| küçükken s = sign(hız komutu), büyükken doğrusal geçişle sign(τ_g) | WO2026074901A1 |
| Toyoda türü | s = sign(τ_g), küçükse dönüş yönü (motor hızının işareti) | JPH07200018A |
| Lenze türü | s = sign(tork), histerezisli (tork sıfır geçişi) | US12259034B2 |
| Önerilen | olay + yoklama kestirici (`ikiz_dogrula.m` kanonik ayarı) | — |
| Üst sınır | ikizin gerçek yüzü (hile, yalnız referans) | — |

Taban kurallar kendi lehlerine kuruldu: ideal motor hızını görürler (bizimki gözlemci hızı); ölü bant ya da histerezis üç değerle tarandı, en iyisi özetlendi (Panasonic, Toyoda kuralV ∈ {0,01; 0,05; 0,2} rad/s; Lenze kuralU ∈ {0,005; 0,01; 0,03} N·m).

**Düzen.** D düzeneği, P–PI r_gs 0,5, 1 kHz, AS5600 motor milinde (0,4 ms gecikme, 0,043° RMS gürültü), akım döngüsü 500 Hz. 7 istek (179–181°) × 2 geliş yönü × 3 gürültü tohumu = 42 koşu her senaryoda; sürtünmeli (F_c 0,04, F_s 0,06 N·m) ve sürtünmesiz.

| Senaryo | Tanım |
|---|---|
| temel | hedefe ±1,1° uzaktan basamak |
| a1 darbe | t = 3 s'de kola 180°'ye doğru 0,05 N·m, 20 ms |
| a2 yük | t ≥ 3 s kola sabit 0,02 N·m, kolu öbür yüze iten yönde (doğru son yüz değişir) |
| b salınım | t ≥ 3 s kola 0,01 N·m, 1 Hz sinüs (yerçekimi torkundan büyük: yüz değişir, komut yönü değişmez); son yüz tanımsız, yalnız B12 |
| c yaklaşma | referans hedefin 5° gerisinden 2°/s rampayla gelip durur |
| d yön değiştirme | referans hedefi 1,5° aşar, geri döner, durur |

Kod: `simulasyon/kol_benzetim.m`'ye `p.yuzKural`, `p.refYol`, `p.dB` (varsayılan kapalı; eski sürümle beş yapılandırmada θ ve u birebir aynı, kanonik 42/42). Betik `simulasyon/7_karsilastirma/b1_kural_karsilastirma.m`, log `b1_log.txt`, şekil `b1_karsilastirma.png` (`b1_sekil.m`).

**Sonuç (H7 geçen, temel + a1 + a2 + c + d = 210 koşu; B12 tüm senaryoların ortalaması).**

| Yöntem | Sürtünmeli H7 | Sürtünmeli B12 | Sürtünmesiz H7 | Sürtünmesiz B12 |
|---|---|---|---|---|
| Tablo | 60/210 | 0,36 | 42/210 | 0,22 |
| Panasonic türü (en iyi) | 120/210 | 0,55 | 210/210 | 0,96 |
| Toyoda türü (en iyi) | 120/210 | 0,51 | 198/210 | 0,84 |
| Lenze türü (en iyi) | 120/210 | 0,78 | 210/210 | 1,00 |
| **Önerilen** | **210/210** | **0,99** | **210/210** | **0,99** |

Senaryo başına (sürtünmeli):
- **temel, c:** Panasonic ve Toyoda 30/42. Kaybettikleri 12 koşunun hepsi geliş yönünün yerçekimi yüzüne ters düştüğü dört istek: 180,75 ve 181° alttan, 179 ve 179,25° üstten. Kol duruşta yerçekimi yüzüne yaslanıyor, kural ise yaklaşma yüzünü varsayıyor; hata 2r ≈ 3,2°. Beklentimiz "c'de iki yöntem yakın" idi; çıkmadı, çünkü yavaş yaklaşmada da duruş yüzünü yaklaşma yönü belirlemiyor.
- **a1 darbe:** Tablo, Panasonic, Toyoda 0/42. Darbe kolu öbür yüze atıyor, komut yönü değişmediği için kural yüzü düzeltmiyor, kol 2r kayık kalıyor. Lenze en iyi 24/42.
- **a2 yük:** Panasonic ve Toyoda yalnız uygun ölü bantta 30/42, Lenze 42/42 (yük tork işaretini çeviriyor, kural bunu doğru okuyor).
- **b salınım:** B12 Panasonic 0,10, Toyoda 0,10, Lenze 0,75, önerilen 0,96.
- **Lenze sürtünmeli temel 0/42:** durgunken tork işareti sürtünmeyle belirsiz, kural yüzü sürekli değiştiriyor, kol 3–6,6° tepeden tepeye avlanıyor (kendi yarattığı limit cycle).
- Önerilen: her senaryoda 42/42, B13 (yoklama sırasında kol hareketi) en çok 0,33°.

**Yorum.**
1. Katkının kanıtı **sürtünmeli** durumda: en iyi ayarlı taban kural 120/210, önerilen 210/210. Sürtünme, komut ya da tork işaretini dişli yüzünden koparan şey; gerçek dişli kutusunda sürtünme var.
2. **Sürtünmesiz durumda taban kurallar da başarılı** (Panasonic ve Lenze 210/210). Bu dürüstçe yazılmalı: sürtünme yokken tork işareti dişli torkunun işaretine eşit, basit kural yetiyor. Katkı iddiası "sürtünmeli gerçek dişlide" diye sınırlanmalı.
3. **Taban kuralların en iyi ayarı tesise bağlı:** Panasonic için en iyi ölü bant sürtünmeliyken 0,05, sürtünmesizken 0,01 rad/s; yanlış ayarda 30–54/210'a düşüyor. Önerilen tek ayarla iki durumda da 210/210.
4. **Üst sınır (anlık, basamaklı gerçek yüz) sürtünmesizde 96/210:** yüz anında, rampasız değiştirildiğinde 1 kHz ve gecikmeyle kol ±3° salınıyor (ortalama hata küçük, genlik büyük). Gerçek yüzü bilmek tek başına yetmiyor; rampalı geçiş gerekiyor. Bu, rampa kararını destekleyen yan bulgu (iş sırası 3'te seçilmişti).
5. Hakem itirazına cevap: "önceki yöntemler bunu zaten yapıyor" itirazı sürtünmeli durumda geçerli değil. Önceki kurallar yüzü *varsayıyor*; varsayım duruşta, bozucuda ve salınımda tutmuyor.

**Sınırlar.** Taban kurallar patent metinlerinden yeniden kuruldu, ürün kodları değil; eşik ve ölü bant sayıları patentlerde yok, taranarak kural lehine seçildi. Sonuçlar ikizde; donanım D7'de doğrulanacak.

### B1 PIL: kartın kestiricisi yeni senaryolarda (2026-11-21)

Kullanıcı kararı: iki yol da denenip karşılaştırılsın. (1) Yalnız MATLAB (yukarıdaki 42 koşu/senaryo, vektör koşusu). (2) Adım kilitli PIL: kartın C++ kontrolcüsü (`firmware/src/kontrol.cpp`, olay + yoklama) ikizi sürer, MATLAB kontrolcüsü gölge olarak aynı ölçümlerle koşar. Taban kurallar firmware'e yazılmadı; karşılaştırma tesis tarafında, PIL yalnız önerilen yöntemin kartta aynı çalıştığını gösterir.

- a2 ve b (sabit hedef): mevcut firmware'le, `simulasyon/7_karsilastirma/pil_b1.m`.
- c ve d (zamanla değişen referans): firmware'de hedef yalnız başlatmada geliyordu. Yeni paket `T_KTL_ADIM_REF` (0x24: double referans + ölçüm, cevap aynı) ve `Kontrolcu::hedefAyarla()` (hedef + ofsetin yerçekimi terimi) eklendi; eski paketler değişmedi. `pil_b1_yol.m`. Yeni firmware'le eski PIL'in ilk 4 senaryosu yeniden koşuldu: 8/8, kart-gölge kararları aynı, |du| ≤ 3e-7 N·m (gerileme yok).

Her senaryoda 14 koşu (7 istek × 2 yön, tohum 1), PIL ve yalnız MATLAB (n = 1, aynı tohum) yan yana:

| Senaryo | Sürtünme | H7 PIL / MATLAB | B12 PIL / MATLAB | Kart-gölge kararları aynı | En büyük \|du\| [N·m] |
|---|---|---|---|---|---|
| a2 yük | sürtünmeli | 14/14 / 14/14 | 0,996 / 0,996 | 14/14 | 3,8e-7 |
| a2 yük | sürtünmesiz | 14/14 / 14/14 | 0,996 / 0,996 | 12/14 | 5,0e-3 * |
| b salınım | sürtünmeli | — | 0,959 / 0,959 | 13/14 | 3,9e-3 * |
| b salınım | sürtünmesiz | — | 0,941 / 0,941 | 13/14 | 2,6e-3 * |
| c yaklaşma | sürtünmeli | 14/14 / 14/14 | — | 14/14 | 3,2e-7 |
| c yaklaşma | sürtünmesiz | 14/14 / 14/14 | — | 13/14 | 5,5e-4 * |
| d yön değ. | sürtünmeli | 14/14 / 14/14 | — | 14/14 | 4,0e-7 |
| d yön değ. | sürtünmesiz | 14/14 / 14/14 | — | 14/14 | 3,0e-7 |

\* Ayrışmaların hepsi PC tarafındaki Windows/USB takılmasından: 896 bin pakette 5 kez cevap 2 s'de gelmedi, kart o örnekte son torku tuttu (adım kilitli düzende "kayıp" sayılır). Kartta CRC, sıra ya da uzunluk hatası 0. Hiçbir senaryonun H7/B12 sonucunu değiştirmedi. Kart adımı ort. 3,5 µs, en uzun ~9 µs (1 ms bütçe).

**Karşılaştırma (iki yol).** Kartın kestiricisi altı senaryonun hepsinde yalnız MATLAB'la aynı sonucu veriyor: H7 aynı, B12 üç basamağa kadar aynı, ayrık kararlar (yüz, yoklama evresi) kayıpsız koşularda örnek örnek aynı. Yani B1'deki "önerilen 210/210" yalnız benzetim kodunun değil, karta gömülen C++ kodunun da sonucu. 42 koşuluk vektör sonuçla (yol 1) PIL'in tek tohumluk sonucu arasında da fark yok.

**Sonraki.** B2 (yay ön yüklü ikiz + açı × ön yük haritası) planı ve onayı.

## B2. Mekanik ön yük (makas dişli) ile yazılım kestiricisi: açı × ön yük haritası ve bedel (2026-11-21)

**Soru.** Endüstri (Toyoda 1993, Lenze 2019, Panasonic WO2026074901A1) boşluğu yazılımla düzeltmeyi seçmiş. Mekanik ön yük (hocanın örneği yaylı ikinci dişli) yüz belirsizliğini bizim düzenekte ne ölçüde kaldırıyor, bedeli ne? Hocanın dişlisi yalnız örnek; amaç, mekanik çözümün sınırını ve bedelini sayıyla göstermek.

**Model** (`kol_benzetim.m`, `p.onYuk`, varsayılan kapalı). Makas dişli tek yönlü: asıl yarı A, δ = +r'de sert temas (K_s). Yaylı yarı B pinyonu öbür yüzden τ_p ön yükle A'ya bastırır. B'nin yayı K_p = 0,1 K_s = 1 N·m/rad; 2r sıkışınca B, A'nın dayanağına oturur (δ = −r'de K_s).

τ_s = max(K_s(δ−r) + c_s δ̇, 0)[δ>r] − max(τ_p + K_p(r−δ), 0) + min(K_s(δ+r) + c_s δ̇, 0)[δ<−r]

Durağan eğri tekdüze:
- τ > −τ_p: kol A yüzünde, boşluk yok, sertlik K_s + K_p.
- −τ_p − 2rK_p < τ < −τ_p: tork yumuşak B yayından geçer.
- Daha küçük τ: B dayanağına oturur.

Ön yükün sürtünme bedeli: F_c, F_s += μ_p τ_p. Bizim dişli için kaynak sayısı yok; μ_p ∈ {0; 0,25; 0,5} taranıyor (0,5 ≈ Roozing 2025'teki "sürtünme 2 kata kadar" üst ucu). `p.taupFn` (zamanla gevşeyen ön yük) B3 için hazır. Ek kayıt `p.kayitEk` (motor hızı, akım, gerilim). Gerileme: HEAD sürümüyle beş yapılandırmada (kanonik olay+yok, tablo, ust_sinir, mod1, edilgen) θ ve u farkı 0; taup = Kp = 0 iken açık bayrak da birebir aynı.

**Düzen.** B1 kanonik ayarı: D, P–PI r_gs 0,5, 1 kHz, AS5600 motor milinde (0,4 ms gecikme, 0,043° RMS gürültü), akım döngüsü 500 Hz.

| Eksen | Değerler |
|---|---|
| Hedef açı | 90–357,5°, adım 2,5° (108 açı; 180 = dik yukarı, 360 = dik aşağı) |
| τ_p | {0; 0,03; 0,06; 0,12; 0,18; 0,24; 0,36; 0,48} N·m. 0 = dişlisiz, saf boşluk. mgℓ = 0,24, F_s = 0,06 |
| Geliş yönü × tohum | 2 × 3 |
| Taban sürtünme × μ_p | {sürtünmeli, sürtünmesiz} × 3 |
| Senaryolar | B1'in genellemesi; bozucu, kolu durağan yüzünden öbür yüze iten yönde: temel, a1 darbe, a2 yük 0,02, a2 yük 0,06, b salınım, c yaklaşma, d yön değiştirme |

Toplam 6 ortam × 7 senaryo × 3 kontrolcü, ~200 bin koşu.

Kontrolcüler:
- **Dişli + tablo:** ofset dişlinin durağan eğrisinin tersi. τ_p, K_p, r, K_s, mgℓ bilinir; dış yük bilinmez. Ön yüklü dişliyle yazılabilecek en iyi kestiricisiz kod; τ_p = 0'da B1 tablosu.
- **Kestirici:** olay+yoklama, kanonik ayar. Ön yükü bilmez, anlamlı satırı τ_p = 0.
- **Üst sınır:** ikizin gerçek yüzü, yalnız τ_p = 0.

H7 burada konum ölçütü: son 1 s ortalama |e| ≤ 0,5° ve en büyük ≤ 1°. Yanlış yüz ~3° hata verdiği için yüz kontrolünü kapsar. Toplam, b hariç 6 senaryo: 3888 koşu.

Bedel ayrı betikte: motorElk 3 (akım döngüsü, DRV8874 sınırı, 12 V). Profiller P1 30° basamak, P2 30° rampa (10°/s), P3 c yaklaşma. Açılar {135, 200, 225, 270}° × 2 yön × 3 tohum.

Kod `simulasyon/7_karsilastirma/b2/`:
- `b2_kurulum.m`, `b2_harita.m` (6 süreç paralel, 42 parça), `b2_birlestir.m` → `b2_log.txt`
- `b2_bedel.m`, `b2_bedel_ozet.m` → `b2_bedel_log.txt`
- `b2_sekil.m` → `b2_harita.png`, `b2_disliz.png`, `b2_bedel_surtunmeli.png`, `b2_bedel_surtunmesiz.png`

**Sonuç 1: harita (H7 / 3888).**

| Kontrolcü | τ_p | Sürtünmeli μ_p 0 | μ_p 0,25 | μ_p 0,5 | Sürtünmesiz μ_p 0 | μ_p 0,25 | μ_p 0,5 |
|---|---|---|---|---|---|---|---|
| Dişlisiz + tablo (B1) | 0 | 3726 | 3726 | 3726 | 3720 | 3720 | 3720 |
| **Dişlisiz + kestirici** | 0 | **3879** | **3879** | **3879** | **3873** | **3873** | **3873** |
| Üst sınır | 0 | 3888 | 3888 | 3888 | 3843 | 3843 | 3843 |
| Dişli + tablo | 0,03 | 3639 | 3642 | 3639 | 3636 | 3636 | 3642 |
| Dişli + tablo | 0,06 | 3606 | 3591 | 3591 | 3603 | 3609 | 3612 |
| Dişli + tablo | 0,12 | 3561 | 3528 | 3492 | 3522 | 3558 | 3555 |
| Dişli + tablo | 0,18 | 3411 | 3384 | 3072 | 3396 | 3402 | 3405 |
| Dişli + tablo | 0,24 | 3636 | 3636 | 3105 | 3642 | 3639 | 3615 |
| Dişli + tablo | 0,36 | 3888 | 3528 | 2289 | 3888 | 3888 | 3006 |
| Dişli + tablo | 0,48 | 3888 | 3276 | 1041 | 3888 | 3849 | 2088 |

**Yorum.**
1. **Ön yük belirsizliği yok etmiyor, taşıyor (Verl–Engelberth 2018'in bizim düzenekteki karşılığı).** Kayıp bandı, durağan yüz değişimi θ* (mgℓ sin θ* = −τ_p) çevresinde. τ_p büyüdükçe 180° ve 360°'den 270°'ye (yatay) doğru kayıyor (şekil `b2_harita.png`, siyah çizgiler). Bandın genişliği |mgℓ sin θ + τ_p| < d kestirimiyle örtüşüyor; d bilinmeyen dış yük. Örnek, sürtünmeli, a2 0,06: τ_p 0'da 165–195°, τ_p 0,12'de 195–250° ve 292,5–342,5°.
2. **İkinci kayıp mekanizması: yumuşak yay bölgesi** (önceden öngörülmemişti). τ_g < −τ_p olan açılarda kol B yayının üstünde duruyor. Sertlik K_p = 1 N·m/rad, yani 0,02 N·m'lik yük 1,1° kaydırıyor. τ_p 0,18'de bu bölge 228,5–311,5°; a2 0,02'de 232,5–307,5° kaybediliyor. Küçük ve orta ön yük bu yüzden dişlisizden de kötü: τ_p 0,03–0,24'te 3411–3642, dişlisiz tablo 3726.
3. **Mekanik çözümün tutması için τ_p > mgℓ + d_en büyük gerekiyor.** Burada 0,24 + 0,06 = 0,30; τ_p 0,36 ve 0,48 sürtünme bedeli yokken (μ_p 0) 3888/3888. Yani ön yük, kolun en büyük yerçekimi torkundan ve bilinmeyen yükten büyük seçilmeli. Bu, endüstrideki "anma torkunun %10–30'u" kuralından (Steinle 2025) çok daha büyük: bizde anma torkunun (0,49) %73'ü ve üstü.
4. **Sürtünme bedeli bunu bozuyor.** μ_p 0,25'te τ_p 0,48 3276; μ_p 0,5'te τ_p 0,36 2289, 0,48 1041. Kayıplar sürtünmeden doğan kalıcı konum hatası: μ_p 0,25, τ_p 0,48, a2 0,02'de e ≈ +0,58°; μ_p 0,5, τ_p 0,48, temel'de |e| ort 1,2°. Sürtünmeli tabanda ve μ_p > 0'da hiçbir ön yük, dişlisiz kestiricinin 3879'una ulaşmıyor; en iyisi 3642.
5. **Dişlisiz kestirici:** sürtünmeli 3879/3888, sürtünmesiz 3873/3888; tablo 3726/3720. Kestiricinin ön yüklü satırları (τ_p > 0'da 0–1710) anlamsız: model simetrik boşluk varsayıyor ve ön yükü bilmiyor. Sadece "yazılım ile mekanik ön yük birlikte kullanılacaksa kestirici ön yükü bilmeli" diye not edilir.

**Kestiricinin dürüst açıkları (B1'in 179–181° penceresinde görülmemişti).**
- **Dik aşağı (360°) çevresi:** yoklama yalnız |θ_ref − 180°| ≤ 1° bandında. c yaklaşma 357,5°'de kol boşlukta kalıyor (e +2,5°, 3 koşu). a2 0,06, 347,5°'de olay modu yüz değişimini yakalamıyor (e −1,9°, 6 koşu). 360° yerçekimi torkunun yine sıfır olduğu ikinci nokta; yoklama bandı oraya da uygulanmalı.
- **Sürtünmesizde 175° ve 185°, a2 0,02:** 12 koşuda 7,2° tepeden tepeye limit cycle. Yük, yerçekimini neredeyse dengeliyor. Sürtünme yokken kestirici ile kontrolcü arasında yüz avlanması gibi duruyor; nedeni ayrıca incelenmeli.
- b salınım 180°'de 6 koşu (H7 toplamına girmiyor; B1'de de son yüz tanımsızdı).

**Sonuç 2: bedel** (`b2_bedel_log.txt`, 24 koşu ortalaması; E = sürücüden çekilen enerji, hareket penceresinde).

| Sürtünmeli, P2 rampa 30° | RMS akım hareket [A] | RMS akım tutma [A] | E [J] | H7 |
|---|---|---|---|---|
| Dişlisiz + kestirici | 0,494 | 0,483 | 10,07 | 24/24 |
| Dişli τ_p 0,36, μ_p 0 | 0,498 | 0,483 | 10,02 | 24/24 |
| Dişli τ_p 0,36, μ_p 0,25 | 0,563 | 0,488 | 15,18 (+51 %) | 24/24 |
| Dişli τ_p 0,36, μ_p 0,5 | 0,709 | 0,635 | 23,50 (+133 %) | 15/24 |
| Dişli τ_p 0,48, μ_p 0,5 | 0,805 | 0,690 | 27,11 (+169 %) | 9/24 |

Sürtünmesiz tabanda aynı eğilim: τ_p 0,36'da E 8,89 → 12,15 J (μ_p 0,25) ve 19,23 J (μ_p 0,5). τ_p 0,48, μ_p 0,5'te P1 ve P2'de H7 3/24. μ_p 0'da ön yükün akım ve enerji bedeli yok: iç kuvvet motor torkuna binmiyor. Bedel tamamen ön yüke bağlı sürtünmeden geliyor; Du 2025 ve Roozing 2025 bunun gerçekte var olduğunu gösteriyor. Enerjinin çoğu yerçekimini tutmanın bakır kaybı (her ortamda aynı); hareketteki artış oranı bu yüzden tabloda olduğundan daha büyük. Ayrıca θ* çevresindeki açılarda (ör. 200°, τ_p 0,06) yay bölgesinde 1–1,6° tepeden tepeye salınım çıkıyor (`b2_bedel_*.png`, alt satır).

**Kanıt zincirine katkı.** (4. halka) Bizim düzenekte mekanik ön yük:
- (i) küçük/orta değerde belirsizliği taşıyor ve yumuşak yay bölgesi yüzünden dişlisiz tablodan da kötü;
- (ii) ancak τ_p > mgℓ + d (anma torkunun ~%73'ü) olunca tutuyor;
- (iii) o değerde ön yüke bağlı sürtünme varsa hareket enerjisi %51–169 artıyor ve konum hatası geri geliyor.

Dişlisiz kestirici aynı haritada 3879/3888.

**Sınırlar.**
- μ_p, K_p ve "ön yük sürtünmesi doğrusal" varsayımı kaynaktan değil, taranarak seçildi.
- Makas dişlinin tek yönlü modeli bir temsilci; elektriksel (çift motorlu) ön yük ayrıca modellenmedi.
- Bedel 4 açıda ölçüldü.
- Simscape çapraz kontrolü kol tarafı geri beslemeli kontrolcüyle yapıldı (Simulink kontrol bloğunda motor tarafı ofset ve kestirici yok). Haritanın kendisi Simscape'te koşulmadı.
- Donanım D7'de.

**Simscape çapraz kontrolü** (`simulasyon/simulink/dogrula_b2.m`, `sm_model_kur(..., 'ideal', true)`, `blok_yuk_onyuk.m`).
- Kurulum: A teması ve −r dayanağı Simscape Hard Stop'ta; B kolunun torku, yerçekimi ve sürtünmeyle aynı tork kaynaklarından.
- Hücreler: 5 açı × τ_p {0,06; 0,24; 0,48} × μ_p {0; 0,5} × bozucu {yok, 0,05 N·m 1 Hz}.
- Sonuç: 60/60 hücrede rejim sınıfı aynı, salınan hücrelerde genlik ve frekans farkı < %1, en büyük |Δθ| 0,03°.
- 200° / τ_p 0,06'da (yumuşak yay bölgesi, θ* = 194,5°'nin hemen ötesi) kol tarafı geri beslemeyle 1,43° genlikli 2,5 Hz çevrim çıkıyor. İki modelde de aynı, adım boyutu 4 kat küçülünce değişmiyor. Bu, yay bölgesinin yalnız yükle kaymaya değil, kendi başına limit cycle'a da yol açtığını gösteriyor (bedel şekillerindeki τ_p 0,06 tepesinin kaynağı).
- Not: ilk koşuda yay sertliği `sim_param`'da PID kazancı `S.Kp` ile aynı adı taşıdığı için yanlış değer aldı (22/60). `S.KpB` olarak düzeltildi; sonuçlar düzeltilmiş koşudan.

## Açıklar: yoklama bölgesi ve θ* hedef kaydırma (2026-11-22)

**Soru.** B2'de kestiricinin (dişlisiz) kaybettiği koşular, yoklama bölgesi genişletilerek kapanır mı?

**Teşhis** (`simulasyon/7_karsilastirma/acik/acik_teshis.m`, log `acik_teshis_log.txt`). Kayıpların hepsi net durağan torkun (yerçekimi + dış yük) küçük olduğu yerlerde:

| Kayıp | Net tork [N·m] | Ne oluyor |
|---|---|---|
| sürtünmeli a2 0,06, 347,5° (6 koşu) | +0,008 | yük kolu öbür yüze geçiriyor; olay modu görmüyor (d^ 0,040, sürtünme aralığında), yoklama yok |
| c yaklaşma 357,5°, yön −1 (iki ortam, 6 koşu) | −0,0105 | kol boşlukta 360°'ye sarkıyor, s^ yanlış, yoklama yok |
| sürtünmesiz a2 0,02, 175/185° (12 koşu) | ±0,0009 | yüz avlanması, 7,24° çevrim |

(b salınım 180° kayıpları H7 toplamına zaten girmiyor: b'de son yüz tanımsız.)

**Denenen.** `kol_benzetim.m`'ye `p.yokBolge` (varsayılan `'180'`, eski davranış; gerileme 5 yapılandırmada θ ve u farkı 0, kanonik 42/42):
- A `'180+360'`: ±`yokBant` (1°) bandı 360°'ye de.
- B `'tork'`: 180 bandı YA DA durgunken |d^| ≤ FsN + `yokTorkEsik` (1°/2°/3° eşdeğeri). d^ gözlemcinin dişli torku tahmini (yerçekimi ve yükü zaten içeriyor).

Betikler `acik_karsilastir.m` (5 paralel süreç, ~5 dk), `acik_birlestir.m` → `acik_log.txt`.

| Varyant | B2 sürtünmeli (3888) | B2 sürtünmesiz (3888) | B1 sürtünmeli / sürtünmesiz (210) |
|---|---|---|---|
| 180 (eski) | 3879 | 3873 | 210 / 210 |
| 180+360 | 3879 | 3873 | 210 / 210 |
| tork 1° | 3738 | 3877 | 210 / 210 |
| tork 2° | 3743 | 3877 | 210 / 210 |
| tork 3° | 3735 | 3874 | 210 / 210 |

**Sonuç: iki çözüm de açıkları kapatmadı.**
1. A hiçbir şey değiştirmedi: ızgarada 360° yok, en yakın 357,5° ±1° bandının dışında.
2. B sürtünmesizde yalnız 357,5° c'yi (3 koşu) kapattı. Sürtünmeli durumda yoklama 150–210° ve 330–357,5°'ye yayıldı (sürtünme aralığı 0,06 N·m) ve **141 koşu kaybettirdi** (e 0,5–1,3°, App ~2°; yoklama kolu oynatıyor, B13 en çok 0,22° → 3–4°).
3. 175/185° çevrimi ve 347,5° a2 0,06, yoklama yapılsa da sürüyor. Bunlar "yüz bilinmiyor" değil, net torkun kolu bir yüze bastıramayacak kadar küçük olduğu durumlar: 180°'nin yüksüz hali gibi, bilinmeyen sabit yük yerçekimini dengeleyip yeni bir sıfır tork noktası (θ*) yaratıyor. Yöntem 180°'de bunu hedef kaydırmayla (ε = 0,5°) çözüyordu; θ*'da bunu yapmıyor.

**θ* hedef kaydırma (kullanıcı kararı: dene, olmazsa sınır olarak yaz).** 180°'deki ε = 0,5° kuralının genellemesi: net torku küçük hedefte hedefi en çok 0,5° kaydır. `kol_benzetim.m`'ye `p.thYildiz` (+ `p.tyArama`), varsayılan kapalı, gerileme 0 fark.

- **Kâhin testi** (`acik_ty_tek.m`, log `acik_ty_tek_log.txt`; 175°, sürtünmesiz, 0,02 yük): yükü bilerek hedef 0,275° kaydırılınca (net tork = mgl sin 0,5°) çevrim tamamen kalkıyor (App 7,24° → 0,11°, e −0,16°). Fikir doğru.
- **Yük kestirimiyle (`thYildiz`)**: süzülmüş d^'dan yük kestirilip gereken kaydırma hesaplanıyor. Çalışmadı (kaydırma −0,13°, App 6,66°): çevrim sürerken kolun ortalama açısı hedeften ~0,7° sapıyor, yük kestirimi bu kadar bozuluyor.
- **Arama (`tyArama`)**: referans dururken s^ ~2 s'de 2 kez değişirse (yüz avlanması) hedef 0,25°/s ile kaydırılır (net tork sign(n0) yönüne; en çok 0,5°; uçta 1 s daha avlanırsa bir kez öbür yön), avlanma durunca tutulur. 175° ve 185°'de 0,035° kaydırmayla çevrim kalktı (App 0,18°).

| Varyant | B2 sürtünmeli (3888) | B2 sürtünmesiz (3888) | B1 sürtünmeli / sürtünmesiz (210) | B13 en çok |
|---|---|---|---|---|
| 180 (eski) | 3879 | 3873 | 210 / 210 | 0,22° / 0,23° |
| θ* kestirim | 3879 | 3873 | 210 / 210 | 0,22° / 0,23° |
| **θ* arama** | **3879** | **3885** | **210 / 210** | 0,22° / 0,23° |

**Sonuç.** Arama 175/185° çevrimini (12 koşu) kapattı, başka hiçbir koşuyu bozmadı (B1 dahil; B12 0,990 / 0,987). Kaydırma yalnız yüz avlanmasında devreye giriyor, diğer koşularda kontrolcü eskisiyle aynı.

**Kalan sınırlar (yayında yazılacak), toplam 7776 koşunun 12'si:**
1. **Sürtünmeli, 347,5° + 0,06 N·m yük (6 koşu):** yük yerçekimini aşıp kolu öbür yüze geçiriyor, net tork +0,008 N·m sürtünme aralığının (±0,06) içinde. Olay modu d^'yı sürtünmeden ayıramıyor; yoklama da bu yüzden sonradan tetiklenmiyor (yokPer = Inf, s^ değişmedi). Kol 2r kayık kalıyor (e −1,9°).
2. **357,5°'ye yukarıdan yaklaşma (iki ortamda 3'er koşu):** 360° kararlı denge; kol boşlukta 360°'ye sarkıyor, dişliye dayanmadığı için ne olay ne d^ bir şey gösteriyor (e +2,5°). Yoklama bandını 360°'ye ±1° genişletmek ızgarada etkisiz (357,5° bandın dışında); net torka göre geniş yoklama sürtünmeli durumu bozuyor (yukarıda).
- Ortak nokta: ikisi de net torkun sürtünmeye göre küçük olduğu, kolun dişliyi yüklemediği ya da yüklediğinin motor tarafından ayırt edilemediği durumlar. Yalnız motor sinyaliyle çalışan bir kestiricinin gözlenebilirlik sınırı.

**PIL (kart).** Arama kuralı `firmware/src/kontrol.cpp`'ye taşındı (`kontrol::AyarEk`, `calisma_notu/esp32.md`). `acik/pil_acik.m`, 16 koşu (175/185° 0,02 yük sürtünmesiz ve sürtünmeli, 347,5° 0,06 sürtünmeli, B1 temel 179,25/179,5/180,75° iki ortamda):

- H7 PIL 14/16, MATLAB 14/16 (kaybedilen ikisi 347,5°: kartta da sınır).
- 175/185° sürtünmesiz: kartta da çevrim yok (App 0,17–0,18°, e ±0,08°).
- Kart-gölge ayrık kararları 16/16 aynı, en büyük |du| 4,6e-7 N·m, kayıp 0, kart hata sayaçları 0.
- Eski PIL (`6_esp32/pil.m`, 84 koşu) yeni firmware'le 84/84, kararlar aynı, |du| ≤ 3,6e-7 (gerileme yok).
- Not: 179,5° sürtünmesiz yüksüz koşuda da arama bir kez devreye girdi (−0,05°); H7 etkilenmedi.

---

## B1-L. Literatürdeki yalnız motor sinyalli kestiricilerle karşılaştırma ve dayanıklılık (2026-11-22)

**Neden.** B1'deki tabanların hepsi patent kuralı. Hakemin "literatürdeki gözlemci/kestirici yöntemlerle neden karşılaştırmadınız?" sorusuna cevap. Yayın hedefi nedeniyle olası bütün itirazlar ayrıca sınandı (aşağıda "Hakem soruları").

**Yeniden kurulan yöntemler** (`kol_benzetim.m`, `p.yuzKes`, varsayılan kapalı; gerileme 9 yapılandırmada θ ve u farkı 0):
- **L1 `momentum`:** Ruderman–Iwasaki 2016 *TIE* sanal sensörünün tork kısmı. Genelleştirilmiş momentum gözlemcisi r = L(J_M w − ∫(u − b_M w + r)), r → −d. Dişli torku = −r − sign(ŵ)·F_cN (hareketteyken). Yüz = işaret, histerezis eşiği. Hız: enkoder farkı (makaledeki gibi) ya da gözlemci ŵ.
- **L2 `sta`:** Ruderman–Fridman 2019 *TCST*, model içermeyen süper-burulma türevleyicisi (denklem 5–6), k2 = 1,1 L, k1 = 2,028 √k2. PDF metninde "k1 = 2,028 k2" okunuyor; birimler gereği kök işareti metin çıkarımında kaybolmuş. Makale yöntemi kayıt üzerinde çevrimdışı uyguluyor; burada çevrim içi kural: |e| > eşik ve sgn e = −sgn ŵ (ani yavaşlama) → yüz = sgn ŵ. **L2 + uyarım:** makalenin S1 adımı, 180° bandında durgunken U sin(2πft) 1 s, integral donuk, en çok 3 kez.
- **L3 `edilgen`:** Neubauer 2015 *Mech. Sci.* kuralı, durgunken s = sign(u).
- **Ablasyon `olay`:** bizim kestirici yoklamasız.

**Betikler.** `7_karsilastirma/b1_literatur_taban.m` (B1 senaryo/ölçütleri; `B1L_SOGUK`: başlangıç inancı ters, `B1L_MOMEK`: L1'e büyük eşikler), `b1l_ozet.m`, `b1d_dayaniklilik.m` (`B1D_SURT`: sürtünme bilgisi ince tarama), `b1d_ozet.m`, `b1l_sta/sta_tespit.m`. Günlükler: `b1l_log.txt`, `b1ls_log.txt`, `b1lm_log.txt`, `b1d_log.txt`, `b1dS_log.txt`, `b1l_sta/sta_tespit_log.txt`. Kontrol: `olay+yok` satırı B1'i aynen verdi (210/210, B12 0,989 / 0,985); hiç tetiklenmeyen STA ayarları 60/210 = B1'deki sabit tablo kuralı.

**1. Ana tablo** (H7 / 210, temel+a1+a2+c+d, 3 tohum; tabanlar kendi lehine en iyi ayarla):

| Yöntem | Izgara | Sürtünmeli | Sürtünmesiz |
|---|---|---|---|
| L1 momentum | L {30,100,300} × eşik {0,005..0,03} × hız {fark, ŵ} | 138 (temel 0/42, App 6,6°: yüz avlanması) | 210 |
| L1, eşik ≥ F_s (`b1lm`) | eşik {0,045..0,15} | 186 (en iyi eşik = F_s = 0,06) | 210 |
| L2 STA | L {10,30,100,300} × eşik {3,10,30} q_M | 71 | 49 |
| L2 STA + uyarım | 4 STA ayarı × U {0,03, 0,06, 0,12} × f {2, 5} Hz | 22 | 46 |
| L3 sign(u) | – | 96 | 210 (avl 376) |
| olay (ablasyon) | – | 210 | 210 |
| olay+yok (bizim) | – | 210 | 210 |
| olay+yok + θ* arama | – | 210 (B12 0,990) | 210 (0,987) |

- L1'in enkoder farkıyla hızı AS5600 gürültüsünde L = 100–300'de saniyede yüzlerce yüz değişimi (avl 229–1242). ŵ ile sakin.
- Büyük eşik L1'i 186'ya çıkarıyor, ama ancak F_s bilinirse (en iyi eşik tam F_s). Bizim farkımız yalnız büyük eşik değil: hareketteyken F_c, dururken ±F_s aralığı ve kalıcılık (N_per). Kalan fark temel ve a1'de (30/42 vs 42/42).

**2. Soğuk başlangıç (başlangıç inancı ters, `b1ls`).** olay 210, olay+yok 210, L1 en iyi 163, lenze 168, panasonic 108, toyoda 60, sign(u) 126, STA 69, STA+uyarım 45 (sürtünmeli). Sürtünmesizde patent kuralları ve L1 210, STA ≤ 56. Kol boşluğun ortasından başlıyor ve ilk hareketteki temas olayı yanlış inancı düzeltiyor.

**3. L2 neden çalışmıyor: tespit edilebilirlik (`sta_tespit`).** Ölçüt: çarpma ±10 ms içindeki max|e| / geçişlerden ≥ 50 ms uzak örneklerin %99'u (eşiksiz, kestirici lehine).
- Pozitif kontrol (makalenin §III-D örneği; m2, sertlik, sönüm makalede yok, varsayıldı): tepe yalnız sert temas (√(k/m1) = 7500 rad/s) + 0,1 ms örnekleme + nicemsiz durumda belirgin (44×, 3,6×). 750 rad/s'de ya da 1 ms'de ya da 12 bit nicemde oran ≈ 1.
- Bizim tesis (√(K_s/J_M) = 52,7 rad/s): 3 senaryo × 2 sürtünme × Ts {0,1, 1} ms × {12, 16, 20} bit × gürültü, oranların ortancası 0,6–1,8; tek aykırı 11,6 (20 bit, 0,1 ms, gürültüsüz, tek çarpma). AS5600 + 1 kHz'de hiçbir koşulda ayırt edilemiyor.
- Yorum: STA'nın varsayımı "çarpma dürtü biçiminde bozucu". Yumuşak dişli (K_s = 10 N·m/rad) ve 180°'de kolun boşlukta yavaş düşmesi çarpmayı dürtü olmaktan çıkarıyor; 1 kHz'te ayrık STA'nın kendi titreşimi (≈ k2·Ts²) tabanı belirliyor. Makalenin kendisi "düşük örnekleme ve nicemlemeye duyarlılığı" gelecek çalışmaya bırakıyor; bu sonuç o sorunun bizim tesis için cevabı.

**4. Dayanıklılık (`b1d`, `b1dS`), H7 doğru / ters başlangıç, sürtünmeli tesis:**

| Koşul | olay | olay+yok | L1 (L100 e0,06 ŵ) | lenze 0,03 | sign(u) |
|---|---|---|---|---|---|
| AS5600 (kanonik) | 210 / 210 | 210 / 210 | 186 / 210 | 120 / 168 | 96 / 126 |
| enkoder 0,017° | 180 / 204 | 207 / 210 | 183 / 180 | 117 / 165 | 102 / 123 |
| enkoder 0,068° | 165 / 138 | 198 / 210 | 189 / 198 | 114 / 162 | 105 / 129 |
| J_MN × 0,8 / × 1,2 | 210 / 210, 210 / 204 | 210 / 210 her ikisi | ≈ 186 / 210 | aynı | aynı |
| sürtünme bilgisi × 0 | 114 / 126 | 155 / 168 | 144 / 138 | – | – |
| × 0,25 | 131 / 143 | 180 / 168 | 144 / 138 | – | – |
| × 0,5 | 198 / 210 | 210 / 210 | 144 / 138 | – | – |
| × 0,75 | 210 / 210 | 210 / 210 | 160 / 160 | – | – |
| × 1,1 | 210 / 204 | 210 / 210 | 186 / 210 | – | – |
| × 1,25 | 210 / 185 | 210 / 210 | 186 / 210 | – | – |
| × 1,5 | 165 / 160 | 159 / 138 | 198 / 192 | – | – |
| × 2 | 38 / 36 | 41 / 22 | 210 / 197 | – | – |
| sürtünmesiz tesis, bilgi 0,04/0,06 | 4 / 6 | 52 / 29 | 210 / 210 | – | – |

Sürtünmesiz tesiste (enkoder satırları) olay ve olay+yok hep 210; L1 117–198, 0,068°'de 84.

**Bulgular.**
1. **Literatür tabanları:** sürtünmeli dişlide 180°'de hiçbiri 210'a ulaşmıyor (en iyi L1, F_s'yi bilerek 186). Sürtünmesiz dişlide L1 ve patent kuralları da 210, yani katkı yine sürtünmeli dişlide (B1 ile aynı sonuç).
2. **Yoklamanın katkısı AS5600'de görünmüyor**, ne B1 senaryolarında ne soğuk başlangıçta (eski `5_planlama/yuz_kestirici_as5600` ile tutarlı: orada da olay tek başına 42/42, yalnız 0,017°'de 38/42). Katkı **daha kaba enkoderde ve yanlış başlangıçta**: 0,068°'de olay 165 / 138, olay+yok 198 / 210. Yayında yoklama "ucuz enkodere ve yanlış başlangıca karşı güvenlik ağı" olarak sunulmalı, AS5600'de zorunlu diye değil.
3. **Sürtünme bilgisi asıl donanım riski.** olay+yok penceresi: gerçek sürtünmenin 0,5–1,25 katı (her iki başlangıçta 210). Fazla tahmin daha tehlikeli (× 1,5: 159 / 138, × 2: 41 / 22): sürtünme aralığı gerçek dişli torkunu yutuyor, olay hiç oluşmuyor, yoklamanın temas eşiği (−F_cN) de temas göremiyor. Eksik tahmin × 0,5'e kadar zararsız. **Deneyden önce F_c ve F_s ölçülmeli ve kestiriciye düşük tarafta (≈ 0,75 ×) verilmeli.** L1'in sabit büyük eşiği bu belirsizliğe daha dayanıklı (× 2'de 210), ama kanonik durumda 186'da kalıyor; iki yaklaşımı birleştirmek (ör. eşik = max(F_s aralığı, sabit taban)) açık bir seçenek, denenmedi.
4. J_M'nin ±%20 hatası etkisiz.

### Hakem soruları ve cevapları (çalışma için, rapora değil)

1. **"Literatürdeki kestiricilerle karşılaştırma yok."** Var: L1 (Ruderman–Iwasaki 2016), L2 (Ruderman–Fridman 2019, uyarımlı ve uyarımsız), L3 (Neubauer 2015), kendi lehlerine ızgarayla, aynı algılayıcılarla, ayrıca soğuk başlangıçta.
2. **"STA'yı yanlış kurdunuz."** Pozitif kontrol: makalenin örneğinde sert temas + hızlı örneklemede tepeler belirgin; bizim tesiste hiçbir çözünürlük/örneklemede değil. Neden: yumuşak dişli + 180°'de yavaş konma + 1 kHz. Sınır: pozitif kontrolde makalede verilmeyen m2/sertlik varsayıldı.
3. **"Olay kipinin farkı yalnız büyük eşik."** L1'e F_s'yi aşan eşikler verildi: en iyisi 186/210 (eşik = F_s), olay 210.
4. **"Yoklama gereksiz."** AS5600'de evet, test edilen senaryolarda sonucu değiştirmiyor. Kaba enkoder ve yanlış başlangıçta gerekli (0,068°: 138 → 210). Dürüstçe böyle yazılmalı.
5. **"Gerçek donanımda çalışır mı?"** Benzetimde AS5600 nicemleme + gürültü + gecikme, INA228 ölçümü, akım döngüsü, Coulomb + statik sürtünme var; kestirici ESP32 kartında PIL ile MATLAB'la aynı karar veriyor. Modelde olmayanlar: dişin doğrusal olmayan temas sertliği, konuma bağlı sürtünme, motor dişli (cogging) torku, sıcaklıkla sürtünme değişimi. En büyük bilinen risk sürtünme bilgisi (madde 3): pencere −%50 / +%25. Henüz sınanmayanlar: konuma bağlı/değişken sürtünme, cogging, Stribeck. (23 Kasım güncellemesi: B1-M'de sınandı. Cogging ≥ 0,25 F_c ve r'nin %40 yanlış bilinmesi asıl riskler. AS5600 harmonik hatası ve Stribeck biçimi zararsız. Ayrıntı B1-M bölümünde.)
6. **"Neubauer 2015'ten sonra konuyu bıraktı; belki çözülemediği için."** Kayıtlı bilgi: Neubauer 2017'den sonra robotik yayını yok, ulaşım/lojistik alanına geçmiş (OpenAlex, `literatur/genisletme_2026-11-21.md`). Ekip (Gattringer, JKU Linz) 2017'de boşluklu kalibrasyonu sürdürmüş. Amaçları endüstriyel robot kalibrasyonu; sıfır tork duruşlarından kaçınmak onlar için yeterli, yani sorunu çözmeye ihtiyaçları yoktu. "Çözemedikleri için bıraktılar" iddiası için kanıt yok, tersi için de yok; yalnız olgular yazılır. Ruderman çizgisi boşluk üzerinde çalışmaya devam ediyor, yani alan terk edilmiş değil; bizim açık (tork sıfırken yüz) kapatılmamış.
7. **"Sonuç çıkmazsa?"** Benzetim tarafı zaten sonuç verdi. Donanımda kestirici çalışmazsa bile karşılaştırmanın kendisi (patent kuralları, literatür yöntemleri, ön yük bedeli, STA'nın düşük maliyetli algılayıcıda uygulanamazlığı, sürtünme bilgisi penceresi) yayınlanabilir bir katkı; ama ana iddia buna göre daraltılır.
8. **"Motor tarafı boşluk içindeki çıkış konumunu göremez (gözlenebilirlik)."** (23 Kasım ek taramasında bir blog yazısında görülen itiraz, `literatur/genisletme_2026-11-21.md` §2.7.) Biz boşluk içindeki sürekli konumu değil, ayrık temas yüzünü kestiriyoruz. Yüz yalnız tork aktaran geçişlerde değişir ve bu geçişler motor tarafında tork gözlemcisinde iz bırakır (olay). İzsiz kalan tek durumda (yerçekimi sıfır, tork aktarılmıyor) yoklama yüzü etkin olarak sorgular. Gözlenebilirlik edilgen değil, etkin algılamayla sağlanıyor.

## B1-M. Modelde olmayan etkiler altında dayanıklılık (2026-11-23)

**Neden.** "Gerçek donanımda patlar mı?" kaygısı (tur 61). B1-D bilinen belirsizlikleri (enkoder, sürtünme bilgisi, J_M) sınamıştı. Burada kestiricinin hiç bilmediği tesis ve sensör etkileri sınanıyor. Amaç: siparişten önce riski ölçmek, tanılama deneyinin devam/dur ölçütlerini sayıyla yazmak.

**Yöntem.** `kol_benzetim.m` dosyasına varsayılanı kapalı dört tesis/sensör seçeneği eklendi (başlıkta "Model dışı etkiler"). Eski sürümle (9c2379a) 9 yapılandırmada gerileme yapıldı, θ ve u farkı 0.
- cogging: motor torkuna `cogA sin(12 N φ + faz)` eklenir. Kol tarafında 0,004 / 0,01 / 0,02 N m (= 0,1 / 0,25 / 0,5 F_c), motor milinde 0,13 / 0,33 / 0,67 mN m.
- Stribeck biçimi: tesiste v_s 0,01 ya da 0,2 rad/s (varsayılan 0,05), F_s/F_c 1 ya da 2 (varsayılan 1,5). Kestirici 0,04/0,06 bilir.
- konuma bağlı sürtünme: sürtünme × (1 + a sin(Nφ + faz)), mil turu başına bir kez, a = 0,2 / 0,4 / 0,6.
- açıya bağlı boşluk: r(θ) = r (1 + b sin(r_K θ + faz)). r_K = 1 çıkış dişlisi eksantrikliği, r_K = 6 pinyon varsayımı. b = 0,2 / 0,4. Kestirici ve ofset r_N = r'yi sabit bilir.
- AS5600 harmonik hatası: mil açısı ölçümüne E sin(ψ + f1) + E/2 sin(2ψ + f2) eklenir. E = 0,25° / 0,5° / 1° (veri sayfasındaki sistem INL'si, mıknatıs kaymasız ±1°).
- birleşik: cogging 0,25 F_c + a 0,4 + b 0,2 (r_K 1) + E 0,5°.

Fazlar tohuma bağlı. Kurulum, senaryolar ve H7 ölçütü B1-D ile aynı (AS5600 kanonik, 5 senaryo × 14 × 3 tohum = 210, doğru/ters başlangıç). Tek fark: son yüz dişli torkunun işaretinden okunuyor. r değişkenken eski delta ≥ r ölçütü yanıltıyor (logda "d" sütunu, denetim satırında ikisi aynı). Betik `simulasyon/7_karsilastirma/b1m_model_disi.m`, özet `b1m_ozet.m`, log `b1m_log.txt`.

**olay+yok için en kötü hücre (tesis × başlangıç, /210):**

| Etki | hafif | orta | ağır |
|---|---|---|---|
| cogging (0,1 / 0,25 / 0,5 F_c) | 210 | 186 | 66 (sürtünmesiz tesiste 115) |
| Stribeck (v_s 0,01 / 0,2; F_s/F_c 1 / 2) | 210 / 210 | 210 | 183 (F_s/F_c 2) |
| konuma bağlı sürtünme (a 0,2 / 0,4 / 0,6) | 210 | 201 | 190 |
| r(θ), r_K 1 (b 0,2 / 0,4) | 185 | 84 | |
| r(θ), r_K 6 (b 0,2 / 0,4) | 210 | 84 | |
| AS5600 harmonik (0,25° / 0,5° / 1°) | 210 | 210 | 210 |
| birleşik orta | sürtünmeli 123, sürtünmesiz 182 | | |

Karşılaştırma (aynı en kötü hücre): momentum (L1) her koşulda daha kötü (denetimde bile 117). lenze denetimde 120, ağır cogging ve birleşik sürtünmesizde olay+yok'tan biraz iyi (81 / 190), r(θ) b 0,4 sürtünmesizde eşit (84). Bütün yöntemler aynı etkilerde bozuluyor. Hiçbir koşulda bir taban, kestiriciyi açık farkla geçmiyor.

**Başarısızlığın türü** (olay+yok, |e| son 1 s ortalaması): |e| > 1,5° yanlış yüz izi, 0,5–1,5° konum kayması, |e| ≤ 0,5° ama e_max > 1° salınım.
- **r(θ) b 0,4:** başarısızlıkların neredeyse hepsi kayma (sürtünmesiz 0/252 yüz izi, ortalama |e| 0,6°; sürtünmeli 3/141). **Kestirici yüzü doğru buluyor.** Ofset tablosu ise r_N'yi kullandığı için kol (r − r_N) kadar kayık duruyor. Yani sorun yüz kestirimi değil, tablonun r bilgisi. r_K 1'de θ ≈ 180° çevresinde r(θ) neredeyse sabit, yani bu aslında "r %40'a kadar yanlış bilinirse" durumu. r ±%20 içinde biliniyorsa sorun yok (sürtünmesizde 210).
- **cogging 0,25 F_c (sürtünmeli):** 40 başarısızlığın 24'ü yüz izi, 12'si kayma. Cogging, dişli torkunun sürtünme aralığından ayrılmasını gölgeliyor (olay ya geç ya da yanlış oluşuyor). 0,5 F_c'de bütün yöntemler çöküyor, sürtünmesiz tesiste bile (çoğu kayma + salınım: cogging motoru detent'e çekiyor, konum kontrolü o hassasiyete inemiyor).
- **konuma bağlı sürtünme ve F_s/F_c 2:** az sayıda, karışık (yarısı yüz izi). Sürtünme bilgisi penceresinin (B1-D, 0,5–1,25×) yerel ihlali gibi davranıyor.
- **AS5600 harmonik hatası 1°'ye kadar etkisiz.** Mil tarafındaki hata dişliden sonra 30'a bölünüyor (kol tarafında ≤ 0,033°), olay da hız/tork izine bakıyor, mutlak açıya değil.
- **birleşik orta (sürtünmeli 123):** tek tek zararsız ya da hafif olan etkiler birlikte belirgin bozulma veriyor (69 yüz izi, 73 kayma). En büyük pay büyük olasılıkla cogging 0,25 F_c (tek başına 186) ve r ±%20'nin (tek başına 185) birleşimi. Birer birer çıkarma (leave-one-out) denenmedi.

**Devam/dur ölçütleri taslağı** (tanılama deneyinde ölçülecek; hepsi kol tarafı ve B1 senaryoları için):

| Ölçülen | Devam | Dikkat (önlem gerekir) | Dur / donanım değiştir |
|---|---|---|---|
| Boşluk r ve açıya göre değişimi | r_N gerçek r'nin ±%20'si içinde, her açıda (ya da r(θ) haritası ofsette) | harita olmadan ±%20–40: r(θ) haritası ölçülüp ofset tablosuna konmalı (B1-M ek: kayma tamamen kalkıyor) | (dur gerekmez; haritayla ±%40'ta sürtünmeli tesiste 192–194 kalıyor) |
| Cogging genliği | ≤ 0,2 F_c (motor milinde ≲ 0,27 mN m; B1-M ek: 0,125–0,2 hepsi 210) | 0,2–0,25 F_c (0,25'te 186, kenar keskin) | ≥ 0,5 F_c: motor değişmeli ya da cogging telafisi (denenmedi) |
| Konuma bağlı sürtünme değişimi | ≤ ±%40 | ±%40–60 | ölçülmedi (> ±%60) |
| F_s/F_c oranı | ≤ 1,5 (1 de güvenli) | ≈ 2: F_sN seçimi yeniden ayarlanmalı | |
| F_c, F_s bilgisi (B1-D) | 0,5–1,25 × gerçek | | > 1,25× |
| AS5600 açı hatası | ≤ 2° (mil; 2°'de 208, B1-M ek) | | > 2° denenmedi |

**Sınırlar.** (1) Her etki ayrı, birleşim tek noktada sınandı. (2) Cogging tek harmonik ve mil turu başına 12 periyot. Gerçek motorun periyodu ve genliği ölçülmeli. (3) r_K = 6 bir varsayım (son kademe oranı bilinmiyor). (4) AS5600'de mıknatıs kayması için ±1°'nin üstü denenmedi.

**Açık sorular (kullanıcıya):** (a) r(θ) bilinirse (ofset r_N(θ) haritasıyla) kayma kayboluyor mu? Bu, "sorun tabloda, kestiricide değil" savının doğrudan kanıtı olur. (b) Birleşik koşulda birer birer çıkarma: hangi etki baskın? (c) AS5600 2° (mıknatıs kayması). (d) Cogging 0,1–0,25 F_c ince taraması. Cogging telafisi yeni bir yöntem olur, sorulmadan girilmez.


### B1-M ek. Açık soruların koşuları (2026-11-23, tur 66)

**Değişiklik.** `kol_benzetim.m` dosyasında `p.rN` artık benzetim başına bir değer (1 × n) alabiliyor (`sOf.*rN`). 59421c6 ile 9 yapılandırmada gerileme yapıldı, θ ve u farkı 0. Ayrıca r_N = r·1 vektörü skalerle bire bir aynı sonucu veriyor. Betik `b1m_model_disi.m` (`B1M_EK=1`, önek `b1mE`), özet `B1M_ONEK=b1mE b1m_ozet`, başarısızlık türü yeni kalıcı betik `b1m_tur.m`, log `b1mE_log.txt`. Kurulum B1-M ile aynı: 5 yöntem, iki tesis, iki başlangıç, tohuma bağlı faz.

**(a) Ofsette r(θ) haritası.** r_N = r (1 + b sin(r_K θ_hedef + faz)), yani tablo gerçek r(θ)'yi hedef açıda okuyor. Bu bir yaklaşıklık: kararlı durumda θ ≈ hedef olduğu için yeterli, geçişte tablo hedefteki r'yi kullanıyor.

| olay+yok, en kötü hücre /210 | harita yok (B1-M) | harita var |
|---|---|---|
| r_K 1, b 0,2 | 185 | 210 |
| r_K 1, b 0,4 | 84 | 194 (sürtünmesiz 210) |
| r_K 6, b 0,2 | 210 | 210 |
| r_K 6, b 0,4 | 84 | 192 (sürtünmesiz 210) |

Haritayla **kayma tamamen kalkıyor** (kayma 0/420, her koşulda). b 0,4 sürtünmeli tesiste kalan 27–28 başarısızlığın hepsi yüz izi, ortalama |e| 1,9–2,1°. Böylece "B1-M'deki r(θ) başarısızlığı kestiriciden değil, ofset tablosunun r bilgisinden" savı doğrudan doğrulanmış oluyor. Kalan küçük pay sürtünmeli tesise özgü: ±%40'lık r değişimi olay penceresini (dişlinin boşlukta kaldığı süre) değiştiriyor. Tek etki olarak dayanılabilir düzeyde.

**(b) Birleşik orta, birer birer çıkarma** (olay+yok, en kötü hücre /210; birleşik: sürtünmeli 123, sürtünmesiz 182):

| Çıkarılan etki | sürtünmeli | sürtünmesiz |
|---|---|---|
| cogging 0,25 F_c | **186** | 210 |
| konum sürt. a 0,4 | 169 | 182 |
| r(θ) b 0,2 | 155 | 210 |
| AS5600 0,5° | 127 | 185 |

**Baskın etki cogging.** Onu çıkarmak sürtünmeli tesiste 123'ü 186'ya çıkarıyor. Bu değer, cogging tek başına uygulandığında alınan 186 ile aynı düzeyde. Ardından konuma bağlı sürtünme ve r(θ) geliyor. AS5600 hatasının payı yok denecek kadar az (123 → 127). Sürtünmesiz tesiste konum sürtünmesini çıkarmak bir şey değiştirmiyor (182), çünkü çarpılacak sürtünme yok. Bu aynı zamanda bir denetim. Orada bozulmayı cogging ile r(θ) birlikte yapıyor: ikisinden biri çıkınca 210. Başarısızlık türü (sürtünmeli): cogging çıkınca 21 yüz izi, 16 kayma; r(θ) çıkınca 54 yüz izi, 34 kayma.

**(c) AS5600 harmonik 2°** (E1 2°, E2 1°; mıknatıs kayması): olay+yok 208/210. Sürtünmeli tesiste ters başlangıç ve d senaryosunda 2 yüz izi var. Sürtünmesizde 210. Mil hatası dişliden sonra 30'a bölündüğü için 2° de etkisiz sayılır. Karşılaştırma: momentum 126, lenze 111.

**(d) Cogging ince taraması** (0,125 / 0,15 / 0,175 / 0,2 F_c): olay+yok her ikisi tesiste 210/210. Olay yöntemi 0,2 F_c sürtünmeli tesiste 203'e iniyor. B1-M'deki 0,25 F_c değeri 186'ydı. Yani **eşik 0,2 ile 0,25 F_c arasında ve kenar keskin.** Devam eşiği 0,1'den 0,2 F_c'ye (motor milinde ≈ 0,27 mN m) çekildi.

**Devam/dur tablosu güncellendi** (yukarıdaki tabloda r, cogging, AS5600 satırları). Donanım için asıl risk sıralaması şimdi şöyle: (1) cogging, ölçülmeli, ≤ 0,2 F_c olmalı; (2) r ±%20'den fazla değişiyorsa r(θ) haritası ölçülüp tabloya konmalı; (3) birleşik etkiler. Tek tek güvenli olan cogging ve r birlikte sürtünmesiz tesisi de bozuyor, bu yüzden tanılama deneyinde cogging ile r(θ) birlikte ölçülmeli.

**Sınırlar.** Harita hedef açıda okunuyor (geçişte yaklaşık). Birleşimde yalnız tek nokta ve tek-çıkarma sınandı, ikili etkileşim taraması yapılmadı. Cogging yine tek harmonik.


## B1-G. Net torku sıfıra yakın eklemler (2026-11-23, tur 67)

> **UYARI: işaret hatası, a1/a2 sonuçları geçersiz, yeniden koşulacak.** Senaryo 1, 2a ve 2b'nin ilk koşumlarında (065880c, abf9117, 84af864) a1 darbesi ve a2 sabit yükü `-s0` yönünde verildi. Kol denkleminde bozucu `+d` olarak giriyor ve durağan dişli torku `mgl sin θ − d`. Bu yüzden `-s0` yükü kolu yüze **bastırıyor**: a2 "yüzü çeviren" yük değil, "yüzü tutan" yük oldu, a1 de koparan değil bastıran darbe oldu. B1-M'de işaret `+s0` idi. Aşağıdaki tablolarda a1 ve a2 sütunları, ayrıca "a2 her yerde geçiyor" yorumları bu hatanın ürünü. Senaryo 1'deki "kalıcı bir tork kolu yüze bastırırsa her yöntem doğru" yorumu yine geçerli, çünkü yanlış işaretli a2 tam olarak bunu sınamış oldu. Temel, c ve d senaryoları bozucusuz, onlar geçerli. Senaryo 3'ün ilk koşumunda (commit edilmedi) dB satırları da aynı nedenle geçersiz. Sinüs dA satırları birkaç periyot sürdüğü için işaretten az etkilenir, yine de yeniden koşulacak. Betik düzeltildi (`+s0`). Yeniden koşum, bellek yetmediği için yarıda kesildi (20 paralel MATLAB ≈ 15,5 GB). Bir dahaki sefere tek zincir, 10 paralel süreç.

**Neden.** B1'in bütün senaryoları dik kolda geçiyordu: yerçekimi, 180° çevresi dışında kolu bir yüze bastırıyor. Genişletme planı (kullanıcı onaylı, sıra 1 → 2a → 2b → 3) net durağan torkun her açıda sıfıra yakın olduğu eklemleri soruyor: yatay eklem, karşı ağırlık, yay dengeleme, dış bozucu.

**Ortak kurulum.** B1-M ile aynı: 5 yöntem, sürtünmeli ve sürtünmesiz tesis, 3 tohum, AS5600 kanonik, P-PI, INA228 tork ölçümü, gözlemci hızı. Senaryolar temel / a1 darbe / a2 sabit yük / c yaklaşma / d yön değişimi. Bunlara altıncı yöntem olarak olay+yok'un **her açıda yoklama** varyantı eklendi (`yokBant = pi`, bant her hedefi kapsar). Varsayılan varyantta bant 180° ± 1°. Betik `simulasyon/7_karsilastirma/b1g_net_tork.m` (`B1G_SEN`, `B1G_PARCA`/`B1G_NPAR`), özet `b1g_ozet.m` (`B1G_ONEK`).
- **Ölçüt (yeni):** |e| ≤ 0,5° ve e_max ≤ 1° (son 1 s), ayrıca kestiricinin son yüzü (`o.yuzSon`) tesisin son 1 s'deki gerçek dişli torkunun işaretine eşit olmalı. Son 1 s'de hiç dişli torku oluşmadıysa (kol boşlukta serbest) yüz tanımsız: H7 sayılmaz, logda ayrıca "temassız" olarak sayılır.
- **`yokTorkEsik`** sabit 0,0042 N m (D düzeneğinin dik kolundaki mgl sin 1°). Yalnız `yokBolge = 'tork'` kipinde kullanılıyor, iki varyant da bu kipte değil. Ama mgl = 0'da varsayılanı 0'a düştüğü için belirsizlik kalmasın diye B1'deki değere sabitlendi.

### Senaryo 1. Yatay eklem (mgl = 0)

Tesiste mgl = 0, kestirici de mglN = 0 biliyor. Kod değişikliği yok. Hedefler 45 / 120 / 180 / 270°, ± yaklaşma (8 hedef). Başlangıç inancı: doğru = ilk hareket yönü (motor kolu o yöne itiyor). Darbe ve sabit yük ilk yüzün tersine. Hücre /120 (5 senaryo × 8 × 3 tohum). Log `b1g1_log.txt`.

| H7 /120 (doğru / ters) | sürtünmeli | sürtünmesiz |
|---|---|---|
| olay | 24 / 24 | 24 / 24 |
| olay+yok | 25 / 24 | 24 / 26 |
| olay+yok her açı | 25 / 24 | 24 / 28 |
| momentum | 24 / 24 | 24 / 24 |
| lenze | 24 / 24 | 24 / 24 |
| edilgen | 0 / 24 | 24 / 24 |

**Bütün yöntemler yalnız a2'de (sabit yük) geçiyor: 24/24. Öbür dört senaryo neredeyse tamamen başarısız.** Başarısızlıkların çoğu "temassız": sürtünmeli tesiste 96–153/240, sürtünmesizde 166–192/240 (edilgen hariç). Temassız koşuların hiçbirinde konum ölçütü tutmuyor (|e| ≤ 0,5° yalnız 0–2 koşuda). e ±3°'ye (≈ ±2r) yayılıyor, son 1 s içinde de hâlâ değişiyor.

**Neden (tek koşu izi, olay+yok, sürtünmeli, 45°, doğru başlangıç).** Motor hedefte duruyor. Kol ise boşluğun içinde serbest bir kütle gibi bir yüzden öbürüne gidip geliyor: e 0,4° ile 3° arasında, periyot yaklaşık 4 s. Son 4 s'de temas oranı %1,4, kestirici yüzü bir kez bile değiştirmiyor. Sürtünmesiz tesiste de durum aynı. Bunun nedeni tesiste kol tarafında yalnız viskoz yatak sürtünmesi olması: bL = 1e-4 N m s/rad, J_L ile zaman sabiti yaklaşık 36 s. Coulomb sürtünmesi yalnız motor tarafında. Kolu bir yüze bastıran tork olmayınca dişli çarpması kolu geri fırlatıyor ve kol neredeyse sönümsüz kalıyor.

**Yorum.** Burada sorun yüz kestirimi değil, gözlenecek bir yüzün olmaması. Kol bir yüze yaslanmıyorsa motor tarafındaki hiçbir bilgi kolun boşluktaki yerini veremez. Bu, gözlenebilirlik itirazının (hakem sorusu 8) sınır durumu. Yöntemler arasındaki fark gürültü düzeyinde. Her açıda yoklama da yardımcı olmuyor: yoklama "temas mı, boşluk mu" sorusunu soruyor, ama kol serbestçe yüzerken her iki cevap da birkaç saniye sonra geçersiz kalıyor. a2'nin geçmesi tam tersini gösteriyor: küçük ama kalıcı bir tork (0,02 N m ≈ 0,5 F_c) kolu bir yüze bastırınca bütün yöntemler (edilgen dahil) her hedefte doğru. Edilgen yöntemin sürtünmesiz tesisteki farklı davranışı (temassız yalnız 5, ama 135 konum başarısızlığı, ortalama |e| 1,06°) yöntemin kendinden geliyor: s^ = sign(u) seçimi kolu sürekli bir yüze itiyor ve titreşen bir temas oluşturuyor.

**Sonuç (senaryo 1).** Yatay eklemde bu kestiriciler tek başına anlamsız. Kola bir yüze bastıran kalıcı bir tork gerekiyor. Bu tork mekanik ön yükle (B2, makas dişli), ya da kontrolle sağlanabilir: motoru kolu sürekli bir yüze dayayacak kadar sabit bir tork farkıyla tutmak. İkincisi yeni bir yöntem, plan dışında, sorulmadan denenmedi. **Model sınırı:** kol tarafındaki Coulomb sürtünmesi (rulman) tesiste yok. Gerçek eklemde kol boşlukta salınmak yerine bir yerde durur. Bu durumda da kol yüzde değil, boşlukta herhangi bir konumda kalır ve hata 2r'ye kadar çıkabilir. Sonuç değişmez, ama başarısızlığın biçimi değişir (salınım yerine sabit kayma). Bunu sınamak için tesise kol tarafı sürtünmesi eklemek gerekir. Bu bir kod değişikliği ve plan dışında.

### Senaryo 2a. Karşı ağırlık (mgl × 0,1 ve × 0,05)

Tesiste mgl, D'nin dik kolunun 0,1 ve 0,05 katı (0,024 / 0,012 N m, yani F_c'nin 0,6 ve 0,3 katı; tork her açıda sürtünme aralığının içinde). Kestiricinin bildiği mglN üç durumda: doğru, × 0,5, × 1,5. Kod değişikliği yok. Hedefler ve senaryolar senaryo 1 ile aynı. Başlangıç inancı B1 kuralıyla: doğru = sign(sin hedef), 180°'de ilk hareket yönü. Darbe ve yük -s0 yönünde. İki koşum yapıldı: 180° tam hedef (`b1g2a_log.txt`), ve B1'in 180° ε kuralıyla, yani hedef 180 − 0,5·Y (`B1G_EPS=1`, `b1g2ae_log.txt`). Hücre /120.

| ε kuralıyla, H7 /120 (doğru / ters) | ×0,1 sürt.li | ×0,1 sürt.siz | ×0,05 sürt.li | ×0,05 sürt.siz |
|---|---|---|---|---|
| olay | 98 / 97 | 98 / 96 | 96 / 90 | 96 / 96 |
| olay+yok (iki varyant aynı) | 98 / 97 | 98 / 96 | 96 / 93 | 96 / 96 |
| momentum | 98 / 96 | 97 / 90 | 96 / 84 | 96 / 79 |
| lenze | 78 / 78 | 96 / 96 | 72 / 60 | 96 / 96 |
| edilgen | 42 / 60 | 96 / 96 | 25 / 70 | 96 / 96 |

(mglN doğru. ×0,5 ve ×1,5 satırları ±3 içinde aynı.)

**Hedefe göre ayrıştırınca** (olay+yok, iki başlangıç, mglN doğru):
- **45 / 120 / 270°: 180/180, her tesiste, her iki mgl'de, ε kuralı olsun olmasın.** Yerçekimi F_c'nin %30'u kadar küçük olsa da kolu bir yüze bastırmaya yetiyor. Sürtünme motor tarafında, kolu tutmuyor. Bu yüz de kestirici tarafından doğru bulunuyor. Temassız koşu yok denecek kadar az (0–3/240).
- **180°: yalnız a2 (sabit yük) geçiyor, 12/60.** ε kuralı yardım etmiyor (9–15/60). mgl × 0,1'de 0,5° kaydırmanın verdiği tork 0,024 · sin 0,5° ≈ 2·10⁻⁴ N m, yani F_c'nin %0,5'i. Kolu bir yüze bastırmak için çok küçük. B1'de (tam mgl) aynı kaydırma 0,0021 N m veriyordu. Başarısızlıklar yanlış yüz (17–46/60) ya da konum hatası, ortalama |e| 1,4–2,1°.
- **Kestiricinin mgl hatası (±%50) sonucu değiştirmiyor.** Ofsetteki mgl·sin θ / K_s terimi bu kadar küçük mgl'de ihmal edilebilir. Yüz kararı da mgl'yi kullanmıyor.
- **Her açıda yoklama varyantı burada olay+yok ile bire bir aynı.** 180° dışında yüz zaten doğru olduğu için yoklama bir şey değiştirmiyor. 180°'de ise senaryo 1'deki gibi kalıcı bir yüz olmadığından yoklamanın cevabı tutmuyor.
- Komut tabanlı yöntemler (lenze, edilgen) sürtünmeli tesiste kötüleşiyor: yerçekimi sürtünme aralığının içinde kalınca u'nun işareti artık yüzü göstermiyor. Olay tabanlı kestirici bundan etkilenmiyor, çünkü sürtünme aralığını hesaba katıyor.

**Sonuç (senaryo 2a).** Karşı ağırlıklı kolda kestirici, kolu bir yüze bastıran net tork olduğu sürece çalışıyor. Bu tork F_c'nin %30'u kadar küçük olabilir (denenen en küçük değer; alt sınır taranmadı), çünkü yalnız kol tarafında tutucu sürtünme yok. Başarısızlık, senaryo 1'deki gibi, net torkun sıfırlandığı noktaya (burada 180°) sıkışıyor. Bu noktanın çevresindeki "ölü bant" mgl küçüldükçe genişliyor. Kabaca |mgl sin(θ − 180°)| ≲ birkaç 10⁻³ N m olan açılarda yüz tutunmuyor. Bu bandın açı cinsinden genişliği ölçülmedi.

### Senaryo 2b. Yay dengeleme (artık tork ε sin 2θ)

**Kod.** `kol_benzetim.m` dosyasına varsayılanı kapalı `p.yayE` eklendi. Kolun hareket denklemine −yayE·sin 2θ ekleniyor. Gerileme 4f4c889'a karşı yapıldı: 9 yapılandırmada θ ve u farkı 0, açıkça verilen `yayE = 0` da bire bir aynı. İşaret denetimi de tutuyor: mgl = 0 ve yayE 0,04 ile durağan dişli torku 45°'de +0,040, 135°'de −0,040. Tesis mgl = 0. Kestirici mglN = 0 biliyor, artığı bilmiyor (ofset tablosunda bu terim yok).

**ε değerleri:** 0,5 / 1 / 2 F_c = 0,02 / 0,04 / 0,08 N m. Gerekçe: artığın tepe değeri sürtünme aralığının altında, eşitinde ve üstünde olsun, böylece yüzü sürtünmeye karşı tutup tutamadığı görülsün. Hedefler aynı (45 / 120 / 180 / 270). sin 2θ için 45° ve 120° tepe ya da tepeye yakın. 180° **kararlı** sıfır: artık kolu geri çeken bir yay gibi. 270° **kararsız** sıfır: artık kolu itiyor. Başlangıç inancı sign(sin 2·hedef), sıfırda ilk hareket yönü. Log `b1g2b_log.txt`.

**Hedefe göre** (olay+yok, iki başlangıç × 5 senaryo × 3 tohum = /30 her hedef-yön):

| | 45° / 120° | 180° (kararlı sıfır) | 270° (kararsız sıfır) |
|---|---|---|---|
| 0,5 F_c sürtünmeli | 30 / 30 | 15 | 6 |
| 0,5 F_c sürtünmesiz | 30 / 30 | 29 | 6 |
| 1 F_c sürtünmeli | 30 / 30 | 24 | 6–7 |
| 1 F_c sürtünmesiz | 30 / 30 | 30 | 6 |
| 2 F_c sürtünmeli | 18–21 / 24 | 24 | 23–24 |
| 2 F_c sürtünmesiz | 24 / 24 | 30 | 6 |

- **Tepe açılarında (45 / 120) 0,5 ve 1 F_c'de tam.** 2a ile aynı sonuç: kolu bir yüze bastıran net tork varsa kestirici çalışıyor.
- **2 F_c'de 45 / 120'deki kayıp yüzden değil, ofset tablosundan.** Ofset artık torkun dişli esnemesini (yayE sin 2θ / K_s) bilmiyor. 2 F_c'de bu 0,08/10 rad = 0,46°. Temel senaryoda ölçülen kayma 45°'de −0,46°, 120°'de +0,40°, yani tam bu değer. Kayma 0,5° sınırının hemen altında kaldığı için bozucu ve yaklaşma senaryoları sınırı aşıyor. Başarısızlık türü de bunu doğruluyor: "konum" (yüz doğru) 41–54, ortalama |e| 0,5–0,9°. r(θ) durumunda olduğu gibi sorun tablonun bilgisinde. Artık ölçülüp tabloya eklenirse giderilebilir (denenmedi).
- **Kararlı sıfır (180°) çoğunlukla geçiyor**, sürtünmesiz tesiste tam ya da tama yakın. Geri çeken artık, kol hedeften kayınca onu motora doğru bastırıyor. Sürtünmeli tesiste ε küçükken (0,5 F_c) yarıya iniyor (15/30, 9 temassız).
- **Kararsız sıfır (270°) neredeyse hep başarısız: 6/30, yani yalnız a2 (sabit yük) geçiyor.** Tek koşu izi (olay+yok, sürtünmesiz, 1 F_c): kol yüzler arasında avlanıyor. e 1, 2, 3, 5 ve 8. saniyelerde sırasıyla +1,0 / −1,4 / +1,8 / +2,5 / −3,3°, δ her seferinde ±r'de. Kestirici son yüzü genellikle doğru buluyor ama kol hedefte durmuyor. Bu, B1'deki θ* "yüz avlanması" ile aynı olay (dik kolda 180°). Tek istisna 2 F_c sürtünmeli (23–24/30): orada sürtünme avlanmayı durduruyor olabilir. Bu doğrulanmadı.
- **Her açıda yoklama** 0,5–2 F_c sürtünmelide "yanlış yüz" sayısını azaltıyor (48 → 16, 12 → 3, 11 → 3). Ama karşılığında aynı koşular "konum" hatasına kayıyor, H7 toplamı değişmiyor (±6).

**Sonuç (senaryo 2b).** Yay dengelemeli kolda belirleyici olan şey sıfır noktasının türü. Kararlı sıfırda (geri çeken artık) kestirici çalışıyor. Kararsız sıfırda kol avlanıyor ve bunu hiçbir yöntem çözmüyor. Tepe açılarında artık büyüdükçe (≥ 2 F_c) ofset tablosuna artığın esneme terimi girmeli.
