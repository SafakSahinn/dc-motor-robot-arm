# Simulink dijital ikizi

Amaç: `kol_benzetim.m` ile aynı modeli Simulink'te kurmak. Bu model deney tasarımında, sistem tanılama planının sınanmasında ve ileride ESP32 firmware'ine taşınacak deney protokolünde kullanılacak. Açı × kazanç taramaları vektörize betikte kalır; Simulink tek koşu ve deney tasarımı içindir.

## Kararlar

- **Yalnız Simulink, Simscape yok.** Dişli teması (ölü bölge + K_s yayı + c_s sönümü, çekme yok) Simulink'in hazır Backlash bloğuyla kurulamaz, çünkü o blok sertliği olmayan kinematik bir boşluktur. Bu yüzden tesis bir MATLAB Function bloğunda, betikteki `f(x)` ile aynı denklemlerle yazılır. Simscape'in hazır bileşenleri betikteki modelle birebir eşleşmez.
- **Çözücü:** sabit adımlı `ode4` (RK4), adım 1e-4 s. Betikle aynı yöntem ve adım olduğu için sonuçlar sayısal yuvarlama düzeyinde örtüşmeli.
- **Kontrolcü** ayrık bloklarla, örnekleme süresi `Ts`, sıfırıncı derece tutucu: P–PI kaskat, tork sınırı, anti-windup, sürücü ölü bandı. Sensör katmanı (nicemleme, gecikme, hız filtresi) ayrı bir alt sistemdir.
- **Model betikle kurulur** (`kol_model_kur.m`). `.slx` ikili bir dosya; kaynak betiktir, `.slx` ondan üretilir.
- **Doğrulama ölçütü:** her referans hücrede aynı rejim sınıfı, genlik ve frekans farkı %1'in altında, θ(t) eğrisi üst üste.

## Referans hücreler (`referans_uret.m` → `referans.mat`)

D düzeneği, P–PI, ideal sensör, sürekli kontrol (Ts = dt), T = 8 s.

| # | Açı | r_gs | Başlangıç | Ek koşul | Betik sonucu |
|---|---|---|---|---|---|
| 1 | 90° | 1,20 | 1° | | düzensiz salınım (sınıf 5), A 2,06°, 8,0 Hz |
| 2 | 60° | 0,50 | 1° | | denge (sınıf 0) |
| 3 | 30° | 0,80 | 0,2° | 6,31 Hz sarsıntı, 0,10 N m, t < 1 s | sönüyor (sınıf 1) |
| 4 | 90° | 0,95 | 0,2° | tork sınırsız | denge (sınıf 1) |
| 5 | 90° | 0,95 | 5° | tork sınırsız | kalıcı çevrim (sınıf 3), A 8,14°, 7,1 Hz |

4 ve 5 aynı hücrenin iki kararlılığını gösterir. Hücre 1 düzensiz olduğu için başlangıç koşuluna duyarlıdır. Bu hücrede eğri ancak ilk saniyelerde üst üste beklenir; sonrasında yalnız istatistikler (genlik, frekans) karşılaştırılır.

## Adımlar

1. Referans veri. **Bitti.**
2. Tesis + P–PI, ideal sensör: `kol_model_kur.m` (bloklar `blok_tesis.m`, `blok_sensor.m`, `blok_kontrolcu.m`; parametreler `sim_param.m`), doğrulama `dogrula_2.m` → `dogrula_2_log.txt`. **Bitti:** 5 hücrenin 5'inde θ(t) betikle bit düzeyinde aynı. Tek fark sarsıntılı hücrede (en çok 1,7e-10°) ve sarsıntının t = 1 s'de kesildiği anın kayan nokta zamanlamasından geliyor. Düzensiz hücre 1 bile 8 s boyunca ayrışmıyor.
3. Sensör katmanı, gerçekçi düzey (`sensor_7c` ayarı: 1 kHz, AS5600 12 bit + 1 örnek gecikme, 11 darbe/tur enkoder, 50 Hz hız filtresi, Stribeck sürtünmesi, %3 ölü bant): `dogrula_3.m` → `dogrula_3_log.txt`. **Bitti:** 5 hücrede sınıf, genlik ve frekans aynı; θ(t) farkı en çok 1e-12°.
4. Deney kaynakları: sarsıntı, frekans taraması, serbest salınım. Sistem tanılama planı (K_s, c_s, J_M) bu modelde sınanır.
5. Simscape (isteğe bağlı): DC motorun elektrik tarafı (R, L, zıt EMK, DRV8874 PWM köprüsü, akım sınırı) ve Simscape'in kendi boşluk bloğuyla bağımsız bir çapraz kontrol.
