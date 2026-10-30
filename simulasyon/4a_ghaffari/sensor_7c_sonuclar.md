# 4a Adım 7c: Sensör ve uygulama etkileri, bütün düzeneklerde

Kod: [`sensor_7c.m`](sensor_7c.m), [`secenek_duzenek.m`](secenek_duzenek.m); `kol_benzetim.m`'ye kol açısı ölçüm gecikmesi (`p.gL`, kontrol örneği) eklendi. Kayıt: [`sensor_7c_log.txt`](sensor_7c_log.txt). Düzenekler ve ideal sonuçlar: [`secenekler_sonuclar.md`](secenekler_sonuclar.md).

## Düzeyler

| Düzey | Kontrol | Kol açısı | Motor hızı | Sürtünme, ölü bant |
|---|---|---|---|---|
| ideal | sürekli | ideal | gerçek | yok |
| sensör | 1 kHz | AS5600 12 bit + 1 örnek gecikme | enkoder (11 darbe × 4 kenar × N) ardışık farkı + 50 Hz alçak geçiren | yok |
| gerçekçi | 1 kHz | aynı | aynı | Coulomb 0,04 / yapışma 0,06 N·m (motor tarafı, kol tarafına indirgenmiş), sürücü ölü bandı %3 Tmax |
| kenar | 1 kHz | aynı | enkoder kenar zamanlaması (gerçek hızın 1 kHz örneği olarak yaklaşık) | yok |
| kenar + gerçekçi | 1 kHz | aynı | kenar zamanlaması | gerçekçi ile aynı |

Sınıflandırma ölçülen (nicemlenmiş) kol açısı üzerinden; her nokta üç başlangıç sapmasıyla.

## Sonuçlar

| Düzenek | ideal: çevrim noktası, doyum | sensör | gerçekçi | kenar | kenar + gerçekçi |
|---|---|---|---|---|---|
| A (R 0,17) | 26/54, %7 | 25/54, %24 | 20/54, %20 | 26/54, %7 | 23/54, %6 |
| B1 (R 1, dengeli ek) | 41/54, %24 | 40/54, %29 | 33/54, %26 | — | — |
| B2 (R 2, dengeli ek) | 39/54, %21 | 38/54, %25 | 34/54, %24 | — | — |
| C (N = 10) | 25/54, %22 | 17/54, %64 | 17/54, %71 | — | — |
| D (R 1, ağır uç) | 20/54, %16 | 18/54, %25 | 20/54, %17 | 19/54, %17 | 19/54, %14 |

(Haritaların tamamı kayıtta.)

1. **Hipotezin örüntüsü A ve D'de sensörlerle ve sürtünmeyle de korunuyor:** 0° ve 180°'de kalıcı çevrim; r_gs 0,7–1,1'de ara açılarda bastırma, sınır açısı kazançla büyüyor.
2. **C eleniyor:** sensörlerle haritada düzensiz ve kararsız noktalar yayılıyor, doyum %64–71. Nedeni: 1:10'da motor enkoderinin kol tarafı çözünürlüğü 3 kat kaba (sayım başına 0,82°), tork payı da dar.
3. **B1, B2:** sensör etkisi orta; ama ideal durumdaki zayıflık (r_gs ≥ 0,7'de her açıda çevrim) sürüyor.
4. **Asıl bozulma hız kestiriminden.** Ardışık farkta bir enkoder sayımı (1:30'da kol tarafında 0,27°) 1 kHz'te 4,7 rad/s'lik hız basamağı demek; hız döngüsü kazancıyla çarpılınca tork sınırına yakın bir gürültü. Düşük kazançta düzensiz / kararsız noktalar ve doyumun %7'den %24'e çıkması bundan. Kenar zamanlamasıyla doyum A'da %7'ye, D'de %17'ye dönüyor ve haritalar ideal duruma yaklaşıyor.
5. **Kalan sensör izi:** düşük kazançta ara açılarda dağınık "sönümlü" noktalar; AS5600'ün 0,088°'lik basamağının sınıflandırma eşiğine (0,05°) yakın olmasından. Deneyde eşik çözünürlüğe göre seçilmeli.

## Sonuç ve öneriler

- **Düzenek:** D (ağır uç kütlesi, R ≈ 1), uç kütlesi 0–150 g arasında değiştirilebilir (A ile D aynı düzeneğin iki ucu). C elendi; B hipotezi sınamak için zayıf.
- **Firmware:** motor hızı ESP32'nin MCPWM yakalama birimiyle enkoder kenar zamanlamasından ölçülmeli (mimari.md'deki ikinci yöntem); ardışık fark yalnız yedek.
- **Sınırlar:** rotor eylemsizliği ve K_s tahmin; kenar zamanlaması ideal örnek olarak yaklaşıklandı (gerçekte düşük hızda periyot ölçümünün de sınırı var); Stribeck sürtünmesinin değerleri tahmin.
