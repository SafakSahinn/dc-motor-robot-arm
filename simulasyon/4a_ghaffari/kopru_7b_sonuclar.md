# 4a Adım 7b: Bu çalışmanın düzeneği Ghaffari çerçevesine düşüyor mu?

Kod: [`kopru_7b.m`](kopru_7b.m), [`kopru_7b_R.m`](kopru_7b_R.m). Kayıtlar: [`kopru_7b_log.txt`](kopru_7b_log.txt), [`kopru_7b_R_log.txt`](kopru_7b_R_log.txt).

Düzenek (dengeli liste, yerçekimi kapalı, ideal sensör, tork sınırı yok): JGB37-520 1:30 (rotor eylemsizliği **tahmini** 4·10⁻⁶ kg·m² → kol tarafında J_M = 3,6·10⁻³), 20 g / 150 mm çubuk + 20 g uç (J_L = 6·10⁻⁴), K_s = 10 N·m/rad (tahmin), 2r = 1,5 / 3 / 5°. Her nokta üç başlangıç sapmasıyla koşuldu ve [`rejim_sinifla.m`](rejim_sinifla.m) ile sınıflandı.

## Bulgu 1: eylemsizlik oranı R = J_L/J_M = 0,17; Ghaffari'nin düzeneklerinde 0,8–2,1

Bu çalışmanın kolu, motorun kol tarafına yansıyan eylemsizliğinin altıda biri kadar. Sonuçları:

- **DF frekansı 2–5 kat yüksek.** r_gs = 0,3 / 0,5 / 0,7 / 0,9'da benzetim 1,3 / 3,6 / 6,5 / 9,4 Hz, DF 5,8 / 9,9 / 14,0 / 18,0 Hz. Faz kesişimi tek; DF çözümü doğru, varsayımı bozuluyor.
- **Neden:** dişliler zamanın yalnızca %7–47'sinde temas ediyor (r_gs 0,3–0,9). Hafif kol temas anında itiliyor, boşlukta serbest dolaşıyor; iletilen tork kısa darbelerden oluşuyor. DF'nin "doğrusal kısım üst harmonikleri süzer" varsayımı tutmuyor. Rejim Ghaffari'nin "çarpma" rejimine benziyor, ama r_gs = 0,4 eşiğinin çok üstünde de sürüyor.
- **r_gs ≥ 1'de kararsızlık yok:** r_gs = 1,6'ya kadar kararlı kalıcı çevrim (yalnız 2r = 5°, r_gs = 1,6'da kararsız).
- **r_gs tek başına belirleyici değil:** aynı r_gs'de hız döngüsü bant genişliği ω_a'dan 5 ω_a'ya çıkınca frekans 3–4 kat düşüyor (r_gs = 0,5: 3,6 → 0,9 Hz). Ghaffari'nin "yalnız kp·kv çarpımı önemli" sonucu bu düzenekte geçerli değil.
- **Frekans boşluktan bağımsız, genlik boşlukla orantılı** (2r = 1,5 / 3 / 5° için aynı frekans).

## Bulgu 2: R büyüyünce Ghaffari davranışı geri geliyor

| Düzenek | R | f_a | sim/DF frekansı (r_gs 0,5 / 0,7 / 0,9) | Temas oranı | Kararsızlık |
|---|---|---|---|---|---|
| Dengeli liste, N = 30 | 0,17 | 20,5 Hz | 0,37 / 0,46 / 0,52 | 0,18–0,47 | yok (≤ 1,5) |
| + dengelenmiş ek eylemsizlik, J_L = 2 J_M | 2,0 | 5,9 Hz | 0,76 / 0,89 / 0,94 | 0,38–0,86 | r_gs ≥ 1,1 |
| Dişli oranı N = 10 | 1,5 | 20,5 Hz | 0,63 / 0,76 / 0,83 | 0,33–0,76 | r_gs ≥ 1,3 |

## Bulgu 3: ρ ↔ r_gs eşlemesi

PID (K_p = Jω_c², K_d = 1,4 Jω_c) ile P–PI arasında K_V ≈ K_d, kp ≈ K_p/K_d alınırsa r_gs = ρ·(J_M+J_L)/√(J_M J_L). Katsayı yalnız eylemsizlik oranına bağlı:

| Uç kütlesi | 0 g | 20 g | 50 g |
|---|---|---|---|
| r_gs / ρ (JGB37 tahmini) | 5,1 | 2,9 | 2,3 |

Sitedeki "≈ 2ρ" eski simülasyon parametrelerinden (JGA25, 50 g). Ancak bulgu 1'e göre bu düzenekte rejimi r_gs tek başına belirlemiyor; PID'nin K_d'si hız döngüsü bant genişliğini de belirlediğinden eşleme yalnız kaba bir yön gösterir. PID taramasında: ρ = 0,05–0,50 boyunca kalıcı çevrim, ρ ≥ 0,55–0,60'ta kararsız (r_gs ≈ 1,6–1,7).

## Bu çalışma için anlamı

1. **Framing'deki varsayım bu parametrelerle tutmuyor.** "Deney bölgesi (ρ ≈ 0,25–0,40) Ghaffari'nin DF'nin geçerli olduğu rezonans rejiminde" denmişti; dengeli listenin düzeneğinde bölge düşük temaslı, çarpmaya benzeyen bir rejimde ve yerçekimsiz DF bile frekansı 2 kat yüksek veriyor.
2. **Karar gerektiren seçenekler** (4b'nin yöntemini ve mekanik tasarımı etkiliyor):
   - **A. Düzeneği koru (R ≈ 0,2):** 4b'nin temeli DF olamaz; kesin parçalı çözüm (Kollár, Esbrook) ya da çarpma haritaları gerekir. Ghaffari karşılaştırması yine yapılabilir, ama "genişletme" çerçevesi zayıflar.
   - **B. Dengelenmiş ek eylemsizlik (R ≥ 1):** kol miline simetrik bir disk ya da iki uçlu karşı ağırlıklı çubuk; yerçekimi torkunu değiştirmez (γ aynı kalır), Ghaffari'nin rezonans rejimine taşır, DF'yi geçerli kılar. Ucuz ve ayarlanabilir: R deneysel bir değişken olur (mevcut "3 kurulum" planına uyar). Bedeli: daha düşük f_a (R = 2'de 5,9 Hz) ve daha büyük yük eylemsizliği (R = 2 için ≈ 7·10⁻³ kg·m², örn. 10 cm'de iki × 0,36 kg).
   - **C. Daha düşük dişli oranı (N = 10):** aynı kolla R = 1,5, f_a aynı; ama çıkış torku ≈ 3 kat düşer, motor enkoderinin kol tarafı çözünürlüğü 3 kat kabalaşır, farklı bir dişli kutusunun boşluğu ve stok durumu ayrıca kontrol edilmeli.
3. **Belirsizlik:** R = J_L/J_M, rotor eylemsizliği tahminine (4·10⁻⁶) ters orantılı. Gerçek değer 2·10⁻⁶ ise R = 0,33. Karar öncesinde motorun veri sayfasında rotor eylemsizliği aranmalı; yoksa ilk ölçüm (5c, serbest yavaşlama) bunu verir.
