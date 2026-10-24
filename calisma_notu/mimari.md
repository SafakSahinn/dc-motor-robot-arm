# Donanım ve yazılım planı (taslak)

Çalışma notunun 2. aşaması. Framing'den türetilmiştir (`framing.md`). Her bileşenin hangi araştırma ihtiyacından doğduğu "Neden" sütunlarında yazılıdır. Parça seçimlerinin ayrıntısı `../donanim/tasarim_kararlari.md` belgesinde; model, adet ve fiyatlar 3. aşamada (malzeme listeleri).

## 1. Framing'in donanımdan istedikleri

| Araştırma ihtiyacı | Donanım ve yazılım karşılığı |
|---|---|
| Sınırı θ₀ × kazanç düzleminde ölçmek (B1, B2) | Mutlak kol açısı sensörü; yazılımla değiştirilen kazanç; otomatik tarama betiği |
| Salınımın boşluktan geldiğini göstermek (θ_d) | İki sensör: motor enkoderi ve kol açısı; θ_d = θ_M/N − θ_L |
| Üç farklı kurulum (B4) | Değiştirilebilir uç kütlesi; ayarlanabilir boşluklu kaplin (1,5 / 3 / 5°) |
| Ghaffari ile birebir karşılaştırma (B1) | Yazılımda seçilebilir iki kontrolcü: PID ve Ghaffari'nin P–PI yapısı |
| Kaynak ayrıştırma (L, B5) | Ayarlanabilir sürtünme pabucu; yazılımda yapay nicemleme (bit atma) |
| Dengeleme (H, B7) | Kolun milin öbür tarafına uzantısı ve karşı ağırlık |
| Tekrarlanabilirlik ve belirsizlik (B6) | Motor akımı ve sıcaklık kaydı; döngü zamanlaması kaydı; aynı motor sıcaklığında başlatma |
| Model parametreleri | Sistem tanılama deneyleri: R, k_t, J_M, b, F_C, K_s, 2r, ölü bant |

## 2. Sistem mimarisi (donanım ve sinyaller)

```mermaid
flowchart LR
  subgraph GUC[Besleme]
    PSU[12 V 3 A adaptör]
  end
  subgraph KONTROL[Kontrol birimi]
    ESP[ESP32-DevKitC<br/>1 kHz kontrol döngüsü<br/>PCNT enkoder sayacı · LEDC PWM]
  end
  subgraph SURUCU[Sürücü]
    DRV[DRV8874<br/>H köprüsü · akım sınırı ≈ 2 A<br/>CS çıkışı]
  end
  subgraph MEKANIK[Mekanik yapı]
    MOT[DC motor + 1:30 dişli<br/>kendi boşluğu]
    KAP[Ayarlanabilir boşluklu kaplin<br/>1,5 / 3 / 5°]
    MIL[Kol mili Ø8 + 2 rulman]
    KOL[Kol 15 cm<br/>uç kütlesi 0/20/50 g<br/>karşı ağırlık]
    SUR[Sürtünme pabucu<br/>ayarlı]
  end
  subgraph OLCUM[Ölçüm]
    ENK[Motor enkoderi<br/>kol tarafında 0,27°]
    AS[AS5600 kol açısı<br/>0,088°]
    INA[INA228 motor akımı]
    TMP[TMP117 × 2<br/>ortam + motor gövdesi]
  end
  PC[Bilgisayar<br/>tarama betiği · kayıt · analiz]

  PSU -->|12 V| DRV
  PC -->|USB 5 V besleme| ESP
  ESP -->|PWM 20 kHz · yön · nSLEEP| DRV
  DRV -->|motor gerilimi| MOT
  MOT --> KAP --> MIL --> KOL
  SUR -.->|sürtünme torku| MIL
  MOT --- ENK
  MIL --- AS
  DRV --- INA
  MOT --- TMP
  ENK -->|A/B kuadratür| ESP
  AS -->|I²C 0x36| ESP
  INA -->|I²C 0x40| ESP
  TMP -->|I²C 0x48/0x49| ESP
  ESP <-->|USB seri 921600| PC
```

**Bileşenler ve gerekçeleri**

| Blok | Seçim (dengeli liste) | Görev | Neden |
|---|---|---|---|
| Motor | JGB37-520 12 V 1:30 enkoderli | Tahrik; dişli kutusu boşluğun bir kaynağı | Simülasyon bu sınıfla yapıldı; ω_c ≈ 35 rad/s ile hedef ρ bölgesine ulaşıyor |
| Sürücü | DRV8874 | PWM'i motor gerilimine çevirir; donanım akım sınırı | Durma akımı (2,3 A) TB6612'nin sınırının üstünde; akım sınırı salınım deneylerinde motoru korur |
| Besleme | Mean Well 12 V 3 A | Motor gücü | Dalgalanması düşük; ucuz adaptörün dalgalanması doğrudan torka biner |
| Kontrol birimi | ESP32-DevKitC | Kontrol döngüsü, sensör okuma, veri akışı | Donanım enkoder sayacı, 20 kHz PWM, tek duyarlıklı FPU; 1 kHz için yeterli |
| Motor tarafı ölçüm | Motor enkoderi (kuadratür) | θ_M; türev terimi için hız | Kol hızından türev almak döngüyü kararsızlaştırıyor (simülasyon) |
| Kol tarafı ölçüm | AS5600 + diametral mıknatıs | θ_L (mutlak); konum geri beslemesi; θ_d | Mutlak açı: her deneyde θ₀ yeniden bulunur |
| Akım | INA228 | Tork kestirimi (k_t·i); ısınma ve doyum izleme | Salınım deneylerinde akım RMS'i sınırlayıcı |
| Sıcaklık | TMP117 × 2 | Sargı direnci ve sürtünme sıcaklığa bağlı | Tekrarlanabilirlik (B6) |
| Mekanik | Ayarlanabilir kaplin, Ø8 çelik mil, 2 × 608 rulman, gövde, kol, ağırlıklar, sürtünme pabucu | Boşluk, yerçekimi ve sürtünme düğmeleri | Framing'in üç bağımsız düğmesi: 2r, mgℓ, F_C |

**Toplam boşluk** = motorun kendi dişli boşluğu + kaplin boşluğu. Motor boşluğu sistem tanılamada ölçülür; kaplinin üstüne eklenir.

## 3. Mekanik yapı

```
  yan görünüş (kol düşey düzlemde döner)

   [motor + 1:30 dişli]──(kaplin: dil + yuva, 1,5/3/5°)──[mil Ø8]══(rulman)═══(rulman)══[mıknatıs] ⟶ AS5600
                                                             │
                                                     [sürtünme diski + keçe pabuç, vidayla ayarlı]
                                                             │
                                          karşı ağırlık ◄────┼────► kol 15 cm ──► uç kütlesi (0/20/50 g)
```

- **Kaplin:** motor milinden (6 mm D) kol miline (Ø8). Dil ve yuva arasındaki açısal boşluk, değiştirilebilir 3B baskı parçalarla 1,5 / 3 / 5°.
- **Kol mili:** iki 608 rulmanla gövdeye yataklanır. Kol yükünü motor milinden ayırır, böylece motorun kendi yatakları eğilme yükü taşımaz.
- **AS5600:** milin ucunda, mıknatısla eksenel hizada. Kalibrasyon: birkaç açıda motor enkoderine göre (boşluk bir yöne bastırılı tutularak).
- **Kol:** alüminyum lama; uçta vidalı ağırlık yuvası, milin öbür tarafında karşı ağırlık yuvası (H).
- **Sürtünme pabucu:** mile bağlı bir disk ve ona vidayla bastırılan keçe pabuç. Sürtünmeyi açıdan bağımsız olarak ekler (L senaryosu).
- **Güvenlik:** 0° altı ve 180° üstüne geçişi önleyen mekanik durdurucu; yazılımda açı sınırı.

## 4. Yazılım mimarisi

```mermaid
flowchart TB
  subgraph FW[ESP32 firmware · 1 kHz]
    OKU[Sensör okuma<br/>PCNT · AS5600 · INA228] --> KES[Kestirim<br/>θ_M, θ_L, ω_M, θ_d]
    KES --> KTR{Kontrolcü<br/>PID / P–PI}
    KTR --> SIN[Sınırlar<br/>akım · açı · sıcaklık]
    SIN --> PWM[PWM + yön]
    NIC[Yapay nicemleme<br/>L senaryosu] -.-> KES
    KES --> KAY[Kayıt paketi<br/>ikili, zaman damgalı]
    KOM[Komut ayrıştırıcı<br/>θ₀, kazanç, süre, mod] --> KTR
  end
  subgraph PCS[Bilgisayar]
    TAR[Tarama betiği<br/>θ₀ × kazanç × tekrar] -->|komut| KOM
    KAY -->|USB seri| DOS[Ham kayıt dosyaları<br/>+ meta veri]
    DOS --> SIN2[Sınıflama<br/>sönümlü · LC tek/çift kenarlı · kararsız]
    SIN2 --> HAR[Deneysel harita<br/>θ₀ × kazanç; γ × ρ]
  end
  subgraph MOD[Modeller · MATLAB]
    TAN[Sistem tanılama<br/>R, k_t, J_M, b, F_C, K_s, 2r, ölü bant] --> BEN[Sayısal benzetim<br/>iki kütle + boşluk + yerçekimi + sürtünme]
    TAN --> DF1[Ghaffari / simetrik DF<br/>referans]
    TAN --> DF2[İki girişli DF<br/>önerilen öngörü]
  end
  DOS --> TAN
  BEN --> KAR[Karşılaştırma<br/>B1–B7]
  DF1 --> KAR
  DF2 --> KAR
  HAR --> KAR
```

### 4.1 Firmware (ESP32)

| Görev | Ayrıntı |
|---|---|
| Döngü | 1 kHz, donanım zamanlayıcısıyla. Kontrol bir çekirdeğe sabitlenir, Wi-Fi kapalı. Döngü süresi ve gecikmesi her pakete yazılır. |
| Okuma | Enkoder: PCNT (gürültü filtresi açık). AS5600: I²C 1 MHz, her döngüde. INA228: her döngüde ya da 500 Hz (zamanlama izin verdiği kadar). TMP117: 10 Hz. |
| Kestirim | θ_M (kol tarafına indirgenmiş), θ_L, ω_M (ayrık türev + 1. derece filtre), θ_d = θ_M − θ_L |
| Kontrolcü A: PID | u = K_p e + K_i ∫e − K_d ω_M; e = θ₀ − θ_L. Kazançlar ω_c'den: K_p = J ω_c², K_d = 1,4 J ω_c, K_i = K_p ω_c / 4 (simülasyonla aynı). |
| Kontrolcü B: P–PI | Ghaffari 2013 yapısı: dış konum döngüsü (k_p), iç hız döngüsü (k_v, T_i), hız motor enkoderinden. Ghaffari'nin r_gs tanımıyla birebir karşılaştırma için. |
| Seçenekler | Yerçekimi ileri beslemesi açık/kapalı; geri besleme kol ya da motor açısından (O uzantısı için hazır); yapay nicemleme (L) |
| Güvenlik | Yazılım akım sınırı (DRV8874'ün donanım sınırının altında), açı sınırı, motor gövdesi sıcaklık eşiği, iletişim kesilince motoru durdurma |
| Komutlar | θ₀, kontrolcü ve kazançlar, deney süresi, adım genliği, kayıt hızı, mod |
| Kayıt paketi | Zaman damgası, θ_M sayımı, θ_L ham, akım, PWM görev oranı, döngü süresi; sıcaklıklar 10 Hz. ≈ 20 bayt × 1 kHz ≈ 20 kB/s (921600 baud ≈ 92 kB/s'nin altında). |

### 4.2 Deney ve veri toplama (bilgisayar)

- **Tarama betiği:** her (kurulum, θ₀, kazanç, tekrar) için:
  1. Kolu θ₀ − 5°'ye götürür.
  2. Adım komutunu verir.
  3. 10 s kayıt alır.
  4. Motoru bekletir; sıcaklık başlangıç değerine dönünce bir sonraki deneye geçer.

  Bir deney ≈ 15–30 s olduğundan 1080 deney yaklaşık 5–9 saatlik otomatik çalışma eder; birkaç oturuma bölünür.
- **Meta veri:** her dosyada kurulum (uç kütlesi, kaplin boşluğu, sürtünme pabucu, karşı ağırlık), kontrolcü, kazançlar, θ₀, sıcaklıklar, firmware sürümü.
- **Sınıflama (otomatik, son 5 s):** salınım yok ya da sönümlü / tek kenarlı LC / iki kenarlı LC / kararsız ya da doyum. Ölçütler: θ_L genliği, θ_d'nin boşluk kenarlarına değip değmediği, baskın frekans, akım doyumu. Simülasyondaki sınıflarla aynı tanımlar.
- **Sınır çıkarma:** her θ₀'da sınıfın değiştiği kazanç aralığı → kritik kazanç ve belirsizlik aralığı.

### 4.3 Modeller

| Model | Amaç | Durum |
|---|---|---|
| Sistem tanılama modelleri: motor elektrik (R, k_t), mekanik (J_M, b, F_C), dişli teması (K_s), boşluk (2r), sürücü ölü bandı | Benzetim ve DF parametreleri | Deney tarifleri literatürde (Yamada 2016, Malik 2009) |
| Sayısal benzetim: iki kütle + boşluk + yerçekimi + Stribeck sürtünmesi + nicemleme + ayrık zaman | "Kesin" referans; rejim ayrımı | Var (`simulasyon/`); tanılanan parametrelerle güncellenecek |
| Ghaffari / simetrik DF | Yerçekimsiz referans öngörü (B1'deki karşılaştırma) | 4a'da yeniden üretilecek |
| İki girişli DF | Önerilen öngörü | 4b'de türetilecek |
| Kesin parçalı doğrusal çözüm (Kollár / Esbrook yöntemi) | DF'nin bozulduğu rejimde referans | Gerekirse |

### 4.4 Kontrol yöntemleri

- **Ana deneyler:** sabit kazançlı PID ve P–PI. Amaç kontrolcüyü iyileştirmek değil, sınırı ölçüp öngörmek.
- **Referans karşılaştırma:** aynı veri üzerinde yerçekimsiz Ghaffari öngörüsü ve önerilen öngörü.
- **Uzantı (ana katkı tuttuktan sonra):** açıya göre geri besleme harmanlama (O). Firmware'deki "geri besleme kaynağı" seçeneği buna hazır.

## 5. Kalibrasyon ve alt sistem testleri (5c aşamasının özeti)

1. Enkoder yönü ve sayım/tur doğrulaması (kol tarafında 1320).
2. AS5600 sıfırı ve doğrusallığı: dişli bir yöne bastırılı tutularak motor enkoderine göre birkaç açıda.
3. INA228 kalibrasyonu: bilinen dirençle; DRV8874 CS çıkışıyla çapraz kontrol.
4. Boşluk ölçümü: θ_d'nin iki kenarı arasındaki fark, birkaç açıda (Yamada 2016 tarifi).
5. Ölü bant ve sürtünme: yavaş rampa ve tek yönlü sabit hız deneyleri.
6. J_M, b: adım ve serbest yavaşlama yanıtı (kol sökülü ve takılı).
7. K_s: kol bastırılı tutulup küçük tork adımlarıyla.
8. Döngü zamanlaması: 1 kHz'te titreşim (jitter) ve I²C süresi ölçümü.
