# Birleşik rapor: 1. adım, kronoloji ve hata envanteri

Raporun ham malzemesi. Kaynaklar: git geçmişi (153 commit, 13 Ekim – 18 Kasım 2026), `calisma_notu/framing.md`, `rapor/adim4_simulasyon_ve_dogrulama.pdf`, çalışma günlüğü. "Kaynak" sütunu raporda ayrıntının nereden alınacağını gösterir.

Rapor kararları (20 Kasım 2026): Türkçe, PDF, hocaya verilecek normal bir rapor anlatımı, belirli bir forma uyma zorunluluğu yok, yapılan her şey anlatılacak. Biçim: adım 4 raporundaki HTML → PDF düzeni (`rapor/rapor.html`, `betikler/pdf_yap.py`).

## 1. Kronoloji

| Tarih | Evre | Ne yapıldı | Kaynak |
|---|---|---|---|
| 11–13 Eki | KT1 (ders projesi) | DC motorlu tek eklemli kol: 3 durumlu model (θ, ω, i), CTMS parametreleri, denge noktaları, 90°'de doğrusallaştırma (A, B, C, D), özdeğerler 0 / −9,52 / −2, ode45 açık çevrim, animasyon, GitHub | `matlab/`, kt1.tex |
| 17–18 Eki | Araştırma başlangıcı | Konu: dişli boşluğu + yerçekimi + limit cycle. IEEE ve IEEE dışı tarama (OpenAlex, ileriye atıf), Wang 2024 okundu, aday boşluk: yerçekiminin açıya bağlı ön yükü. Motor kontrolü, alışveriş listesi, tasarım kararları | `literatur/`, `site/` |
| 18 Eki | 1. düzeltme turu | "90°'de kusurlar en etkili" iddiası geri çekildi; Sun 2023 TIE ile "90°'de salınım olmaz" hipotezi koşullu hale geldi → iki eksenli harita (θ₀, K_p) | günlük |
| 22 Eki | Tarama + malzeme | Web of Science: boşluk + yerçekimi + DF = 0 kayıt. Bilinen üreticilerden parça listesi, üç seviye liste, dengeli liste seçildi | `literatur/`, `calisma_notu/malzeme.md` |
| 24 Eki | İlk çerçeve | Danışman listesinden 5 kaynak, framing adayları (A–O), son tarama (75 ileriye atıf, 17 sorgu, doğrudan rakip yok), çalışma notu: soru, hipotezler, katkı, ölçütler, donanım/yazılım planı. 2. düzeltme turu (TMP117, AS5600 SF, θ_d tanımı, ω_c) | `calisma_notu/framing*.md` |
| 30 Eki | Adım 4a–4b | Ghaffari 2013 yeniden üretimi (Şekil 7/8, döner tabla), rejim sınıflandırıcı, düzenek seçenekleri (A/B1/B2/C/D → D), yerçekimli iki girişli DF (kritik kazanç hatası %30 → %24 → %19) | adım 4 raporu §3–8 |
| 31 Eki | Kök neden + dijital ikiz | DF/benzetim uyuşmazlığının kök neden sınaması (3 parça); Simulink modeli (betikle bit düzeyinde aynı), Simscape mekanik + elektrik | §9, §12–13 |
| 1–2 Kas | Sanal tanılama | K_m, R_a, J_M, b_M, F_c, K_s, r, c_s, mgℓ, F_s, J_L ikizde tanılandı; 2 model hatası düzeltildi; deney protokolü D0–D6 | §10–11 |
| 3 Kas | Adım 4 raporu | 49 sayfalık PDF, Multibody 3B model, Mechanics Explorer animasyonu | `rapor/` |
| 5 Kas | **Dönüm noktası** | Danışman değerlendirmesi: analizden tasarıma. Hedefli kontrol/kestirim taraması. Açıya göre kazanç planlaması denendi (180°'yi düzeltmedi). Konum döngüsü motor tarafına alındı → boşluk salınımı yok, yerine kalıcı hata. Ofset tablosu → 10–175° düzeldi, 180° tek açık nokta. Literatür kontrolü (Neubauer 2015). Güncel çerçeve kabul edildi | framing.md §0 |
| 6 Kas | Yüz kestirici | Sürtünmeli ikizde ofset, üst sınır testi, hedef kaydırma (180 ∓ 0,5°), yüz kestirici (tork gözlemcisi + yoklama + rampa), H7/B12/B13, AS5600 motor milinde, duyarlılık (iş 4), INA228'den tork (5a). ESP32 adım 1–4: protokol, 1 kHz görev, C++ algoritma (3,5 µs/adım, 84/84 eşdeğer) | framing.md iş sırası 1–5a |
| 7 Kas | ESP32 adım 5–6 | PIL (84/84 aynı), kart üstü gerçek zamanlı ikiz (float, %19 bütçe, 42/42) | `simulasyon/6_esp32/` |
| 8 Kas | 5b, 5c, D7 | Kayan sürtünme ve birleşik hatalar, motor elektrik modeliyle gerilim sürüşü, D7 donanım protokolü | framing.md 5b–5c |
| 10–18 Kas | Sunum | Ana sayfa, tek komutlu demo (20/42 vs 42/42), README, sunum PDF'leri, `sunum_esp32` | README |

## 2. Neden döndük (rapor 5. bölümün özü)

1. **Danışman değerlendirmesi (5 Kas):** sınırı öngörmenin değeri onu kullanmakta. Ağırlık analizden tasarıma kaydı; DF + ikiz atılmadı, ayar tablosu üreten araç oldu.
2. **Kazanç planlaması denendi:** 10–170°'de işe yarıyor, 180°'yi düzeltmiyor.
3. **İlke çelişkisi fark edildi:** ikiz konum hatasını kol açısından hesaplıyordu, oysa iddia "kontrolcü kolu görmez" idi. Sitedeki "3,5× daha hızlı" ve "10–170° salınımsız" sonuçları kol tarafı geri beslemeyle elde edilmişti.
4. **Motor tarafı döngünün sonucu:** boşluk döngünün dışına çıkınca salınım kayboldu (114 hücrede 10 → 0), yerine öngörülebilir kalıcı hata geldi (≈ r + mgℓ sin θ / K_s).
5. **Ofset tablosu bu hatayı giderdi (10–175°, ≤ 0,27°); 180° tek açık nokta kaldı:** ön yük sıfır, kolun yüzü belirsiz, yanlış yüz varsayılınca hata 2r ≈ 3°.
6. **Literatür kontrolü:** ofset tablosu bilinen (Neubauer 2015), sıfır ön yükte yüz kestirimi açık → güncel ana katkı. Çevrim içi r/K_s tanılaması kapsam dışı (EEM alanı dışında kalıyor).
7. **İlk çerçeveden kalanlar:** model, ikiz, sanal tanılama, deney protokolü, donanım. Arşive gidenler: kazanç planlaması, salınım başlangıcı tespiti, H5, B8–B10.

## 3. Hata ve düzeltme envanteri


### A. Yorum ve iddia hataları

| # | Tarih | Hata | Nasıl fark edildi | Etkisi | Düzeltme |
|---|---|---|---|---|---|
| A1 | 18 Eki | "90°'de kusurlar en etkili" | Boşlukta 90°'de dişli bastırılı, kusur en az etkili; yeniden düşünülünce | Sitenin A kartı yanlış yönlendiriyordu | Geri çekildi, site düzeltildi |
| A2 | 18 Eki | "90°'de limit cycle olmaz" (koşulsuz) | Sun 2023 TIE: 90°'de K_p = 50'de 5°/9 Hz salınım | Hipotez tek eksenliydi | Yerçekimi torku / dinamik tork oranı → iki eksenli harita |
| A3 | 30 Eki | Ghaffari Şekil 7/8'deki r_gs tutarsızlığını "okuma hatası" saymak | Şekil başlıklarında değerler açıkça yazıyordu | Yanlış atıf | Makale içi tutarsızlık olarak not edildi; benzetimle başlık değerlerinin şekilleri üretmediği gösterildi |
| A4 | 30 Eki | Ghaffari'nin bildirmediği motor tork sınırı | Sürtünmeli benzetim-deney hatası %18–20'de takıldı | Yeniden üretim tutmuyordu | T_max ≈ 360 N m eklenince %3,9; kalibrasyon adımına tork sınırı eklendi |
| A5 | 31 Eki | Kök neden parça 3: tork sınırı hücreleri "65–115°" | Yeniden kontrol | Yanlış aralık | 30–150°, r_gs 0,80–1,05 |
| A6 | 5 Kas | "3,5× daha hızlı / 0 kol sensörü" | Sensör kararı yazılırken ikizin kol açısından geri besleme yaptığı görüldü | Ana iddia, o sonuçlar için geçersizdi | Konum döngüsü motor tarafına alındı; çerçeve değişiminin nedenlerinden biri |
| A7 | 6 Kas | 180°'ye tam ulaşılabileceği varsayımı | Üst sınır testi: yüz kusursuz bilinse bile kol yerçekimi sıfırını geçip boşluğa düşüyor (0,1–2,7°) | H7 tanımı ulaşılamaz hedefe göreydi | Hedef kaydırma (180 ∓ 0,5°, yaklaşma yönüne göre), H7 yeniden yazıldı |

### B. Model ve benzetim hataları

| # | Tarih | Hata | Nasıl fark edildi | Etkisi | Düzeltme |
|---|---|---|---|---|---|
| B1 | 18–30 Eki | PID türevi kol hızından alınınca boşluk olmasa bile ω_c ≥ 20 rad/s'de kararsızlık (dişli rezonansı ≈ 18,7 Hz) | İlk benzetimler | Kontrolcü yapısı | Tasarım kuralı: sönüm motor hızından, konum kol sensöründen (sonra konum da motor tarafına geçti, B8) |
| B3 | 1 Kas | Sanal firmware kaydı 5 ms'ye seyreltilmişti | Tanılama sonuçları beklenenden kötü; "1 ms kayıt" iddiası yanlış çıktı | K_m, J_M sonuçları | dec = 1, sonuçlar 1 kHz ile yenilendi (K_m kol takılıyken de %0,3) |
| B4 | 1 Kas | Simscape başlangıç kayması: Hard Stop sınırları ağın göreli açısına göreydi; δ0 ≠ 0 başlangıçta temas kayıyordu | tani_JM_kol ilk koşusu −%42…−66 hata | O koşu geçersiz (log silindi), eski sonuçlar etkilenmedi | Sınırlar S.r − (x0(1) − x0(3)) |
| B5 | 1 Kas | K_m tanılamasında L_a terimi atılınca +%3–9 sapma | Tanılama sonucu | K_m | 3. terim "zaman kayması" parametresi olarak tutuldu |
| B6 | 1 Kas | Mod 3'te V 10 kHz değişiyor, 1 kHz anlık kayıt yanlış | Tanılama | Gerilim ölçümü | Firmware V'nin Ts ortalamasını kaydedecek |
| B7 | 3 Kas | Multibody'de açık ode4 enerji ekliyordu | 3B − 1B çapraz doğrulama | 3B sonuçlar | Çözücü değişti (adım 4 raporu Ek B.2) |
| B8 | 5 Kas | Konum hatası kol açısından hesaplanıyordu (`thm = olc(x(3,:), p.qL)`) | "Kontrolcü kolu görmez" ilkesiyle karşılaştırınca | A6 ile aynı | `p.Pkaynak = 'motor'` |

### C. Denenip işe yaramayan yöntemler (değiştirildi)

| # | Denenen | Neden olmadı | Yerine |
|---|---|---|---|
| C1 | K_s'yi rezonanstan ölçmek | Gerçekçi sensörle rezonans görünmüyor | Yarı statik tarama (%0,5) |
| C2 | J_M'yi kol takılıyken ölçmek | %13 hata | Kol sökülü açık çevrim testi (%0,5); kol takılı yöntem yedek |
| C3 | c_s'yi motor kontrolcüyle tutulurken vuruşla ölçmek | Sağlam değil | Motor mili kilitli vuruş testi |
| C4 | Ghaffari DF'sini kendi düzeneğimize uygulamak | R = J_L/J_M = 0,17'de geçersiz (frekans 2–5 kat) | Yerçekimli iki girişli DF (kendi katkımız) |
| C5 | Yerçekimli DF ile kesin sınır | Kritik kazanç hatası %19'da kaldı | Kök neden 3 parçada sınandı; DF araç olarak kaldı |
| C6 | Hız için periyot kestirimi | Salınım sınırını bozuyor | Gözlemci (ŵ) |
| C7 | Açıya göre kazanç planlaması | 180°'yi düzeltmiyor | Motor tarafı döngü + ofset |
| C8 | 180°'de edilgen akım işaretiyle yüz bulmak | Tutma torku ≈ F_c/10, akım işareti kör | Olay yakalama + aktif yoklama (20/42 → 42/42) |
| C9 | MATLAB `serialport` | Her cevap ≈ 15,6 ms gecikiyor (Windows zamanlayıcısı) | .NET SerialPort (≈ 1 ms) |
| C10 | Kartta double ikiz | 2,1 ms/ms, bütçe aşımı | Float, hedefe göre fark durumu (210 µs/ms) |

### D. Tasarım belgesi hataları (24 Ekim kontrol turu ve sonrası)

| # | Hata | Düzeltme |
|---|---|---|
| D1 | TMP117 en fazla 400 kHz; aynı I²C hattındaydı | Ayrı I²C-1 hattı |
| D2 | AS5600 varsayılan filtre (SF = 00) 2,2 ms gecikme | SF = 11 (0,286 ms), gecikme benzetime eklendi |
| D3 | θ_d tanımı belgeler arasında tutarsız | θ_d = θ_M − θ_L (kol tarafına indirgenmiş) |
| D4 | ω_c ve oranlar JGA25 parametreleriyle hesaplanmıştı | JGB37 için yeniden hesaplandı |
| D5 | Hız kestirimi "kenar zamanlaması" yazıyordu | Gözlemci |
| D6 | Mermaid blok şemaları GitHub'da okunmuyordu | Elle SVG |

## 4. Ders (EEM5507) bağlantıları: rapor 3. bölüm için

| Ders konusu | Projede karşılığı | Durum |
|---|---|---|
| Durum uzayı modeli | KT1 3 durumlu model; iki kütle + boşluk modeli | KT1'de var; iki kütle için yazılacak |
| Doğrusallaştırma (Jacobian, denge) | θ₀ = 0, 90, 180°'de A matrisi | KT1'de 90° var; 0/180° ve iki kütle yeni hesap |
| Kararlılık (özdeğer) | Özdeğerlerin açıya göre değişimi; 180°'nin özel olması | Yeni hesap |
| Transfer fonksiyonu, frekans yanıtı | Motor → kol, rezonans | Yeni hesap |
| Kontrol edilebilirlik / gözlenebilirlik | Temasta kol motor ölçümünden gözlenebilir, boşlukta değil → yüz belirsizliği | Yeni hesap (raporun ana köprüsü) |
| Ayrıklaştırma | Ts = 1 ms, c2d (ZOH), ESP32 1 kHz | Yeni hesap |
| Gözlemci | Tork gözlemcisi (Luenberger biçimi), ŵ | Kodda var, doğrusal sistem diliyle yazılacak |
| Doğrusal olmayan uzanım | Boşluk, sürtünme, tanımlama fonksiyonu, limit cycle | Adım 4 raporunda var |

## 5. Sonraki adım

2. adım: raporun iskeleti (`rapor/son_rapor/rapor.html`, adım 4 raporunun stili, boş bölümler + şekil listesi).
