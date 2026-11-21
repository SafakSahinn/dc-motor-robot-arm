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
