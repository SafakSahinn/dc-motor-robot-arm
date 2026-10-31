# 4b: Yerçekimli iki girişli DF ve karşılaştırma

Kod: [`yercekimli_df.m`](yercekimli_df.m) (DF), [`yercekimli_df_testleri.m`](yercekimli_df_testleri.m) (7/7), [`yercekimli_karsilastirma.m`](yercekimli_karsilastirma.m). Kayıt: [`yercekimli_log.txt`](yercekimli_log.txt).

## Yöntem

Ghaffari 2013'ün tek döngülü G·H biçimi korunur; dişli ölü bölgesine giren sapma x = B + A sin ωt alınır (iki girişli DF):

1. **DC dengesi:** dişlinin ilettiği ortalama tork yükü taşır, n₀(a, b) = γ, γ = mgℓ sin θ₀ / (K_s r) (framing'deki γ). Her genlik için ön sapma b = B/r buradan çözülür.
2. **Birinci harmonik:** n₁(a, b(a)) · L(jω) = −1. L(s) = K_s (C k_p + P + M)/(M P), yerçekimsizken Ghaffari'nin G·H'siyle aynı.
3. **Temas sönümü:** c_s ẋ yalnız temasta etkili; ortalaması ve sinüs bileşeni sıfır, kosinüs bileşeni c_s ω A h(a, b), h = (1/π)∫_temas cos²ψ dψ. Dişli eşdeğer yay + sönümleyici olur: k_e = K_s n₁, c_e = c_s h.
4. **Tork sınırı:** sat(u) = u − dz_Tmax(u), ön yük u₀ (ortalama motor torku = mgℓ sin θ₀); aynı ölü bölge araçlarıyla doyum kazancı n_s(U). Dişli eğrisindeki kararsız genliklerin hiçbirinde gerçek doyum kazancıyla döngü kararsız kalmıyorsa çevrim söner.
5. Kararlılık her adımda kapalı çevrim kökleriyle denetlenir. Yerçekimi doğrusallaştırıldığında yüke mgℓ cos θ₀ "yayı" eklenir ve sarkaç modu da −180°'yi keser; bu nedenle tek faz geçişine bakmak yetmez.

**Sezgi:** yerçekimi, push-pull kuvvetlendiricideki ön gerilim (AB sınıfı) gibi dişliyi bir yüze bastırır. Etkin kazanç n₁ sıfıra inemez; en küçük değeri n₁,min(γ) olur (γ = 0,1 → 0,16; 0,5 → 0,44; 0,92 → 0,59). Çevrim ancak gereken kazanç bu değerin üstündeyse oluşur. γ > 0 iken model iki kararlılık öngörür: denge küçük sarsıntıya karşı kararlı, büyük sarsıntı çevrimi başlatabilir.

## Sağlamalar (7/7)

Kapalı biçim n₀, n₁, h sayısal integralle aynı (7·10⁻¹⁰, 2·10⁻⁵); temas kopmuyorsa n₁ = 1; b = 0'da Ghaffari'nin denklem 10'u; yerçekimsiz ve sönümsüz durumda frekans ve n_req `ghaffari_df.m` ile 4 basamak aynı; c_s → 0 ve Tmax → ∞ limitlerinde ilgili yollar birebir aynı sınıfları veriyor.

## Karşılaştırma (açı 0–180° × r_gs 0,3–1,3, benzetim 5° × 0,05 adım, her nokta 3 başlangıç sapması)

Kritik r_gs: salınımın (çevrim, kararsız ya da düzensiz) başladığı ve daha büyük kazançlarda süren en küçük kazanç. 0° ve 180°'de γ = 0 ve DF her kazançta çevrim öngördüğü için kritik kazanç tanımsız; hata medyanlarının dışında.

**D (R = 1, γ(90°) = 0,92):**

| açı | 15 | 30 | 45 | 60 | 75 | 90 |
|---|---|---|---|---|---|---|
| Benzetim | 0,75 | 0,85 | ≈ 0,95 | 1,05 | 1,10 | 1,10 |
| Yerçekimli DF (tam) | 0,58 | 0,72 | 0,78 | 0,85 | 1,02 | 1,08 |
| Tork sınırsız DF | 0,58 | 0,72 | 0,78 | 0,81 | 0,83 | 0,83 |
| Sönümsüz DF | 0,53 | 0,66 | 0,71 | 0,75 | 0,76 | 0,77 |
| Ghaffari | her kazançta çevrim | | | | | |

| Ölçüt (framing §6) | Hedef | D | A | Ghaffari (D / A) |
|---|---|---|---|---|
| B1 kritik kazanç hatası, medyan (en çok) | ≤ %20, Ghaffari'den ≥ 2× iyi | **%19 (%42)** | %27 (%58) | %81 / %79 |
| B2 açı sınırı hatası, medyan | ≤ 5° | 15° | 20° | tanımsız |
| B3 çevrim frekansı, benzetim/DF medyan | ≤ %15 | 0,89 | 0,94 | |

Katkıların ayrışması (D, B1 medyanı): sönümsüz %30 → temas sönümüyle %24 → tork sınırıyla %19. A'da tork sınırı etkisiz (mgℓ/Tmax = 0,09), temas sönümü %55 → %27.

## Değerlendirme

- **Önerilen DF hedeflenen iyileşmeyi sağlıyor:** D'de B1 tutuyor (medyan %19, Ghaffari'den 4,3 kat iyi). Ghaffari çerçevesi açıya hiç duyarlı değil; yerçekimli DF bastırma bölgesinin şeklini ve 90° etrafındaki simetrisini doğru veriyor.
- **Hata sistematik ve temkinli yönde:** DF çevrimi benzetimden daha düşük kazançta öngörüyor (en büyük fark 15–45°'de, %20–25). Bu bölgede γ küçük, temas sık kopuyor; DF'nin tek harmonik varsayımı en zayıf burada.
- **B2 tutmuyor (15°), ama bağımsız bir hata değil** ([`aci_hatasi.py`](aci_hatasi.py), [`aci_hatasi_log.txt`](aci_hatasi_log.txt)). Kritik kazanç eğrisi açıya göre yatık: 30–55°'de eğim 0,004–0,006 r_gs/°. Bu eğimde kazançtaki %15–20'lik fark 20–50° açı kaymasına dönüşüyor; eğimin büyük olduğu 10–20° ve 65–80°'de ise aynı fark 4–13°. DF'nin kritik kazancı tek bir sabitle (benzetim/DF medyanı 1,22) ölçeklenince açı hatası medyan 5°'ye (ızgara adımı), en çok 10°'ye iniyor. Yani DF sınırın **biçimini** doğru veriyor, açı hatasının tamamı B1'deki sistematik kazanç farkından geliyor. Sabit aynı veriye uydurulduğu için öngörü değil; yalnız hatanın kaynağını ayırıyor. Sonuç: 5° hedefi bu eğimde kazançta ≈ %3–5 doğruluk demek; DF'den beklenmesi gerçekçi değil (framing §6 B2'nin riski olarak "sınırın keskinliği" zaten yazılıydı). Deneyde B2'yi düzeneğin tanılanmış K_s ve c_s'siyle yeniden değerlendirmek gerekir.
- **Tork sınırı çevrimi gerçekten söndürüyor:** tork sınırsız benzetimin kalıcı çevriminden başlatılıp tork sınırı açılınca çevrim r_gs 0,90–1,00'da sönüyor (çekim bölgesi etkisi değil). DF bunu ön yüklü doyum kazancıyla 75–105°'de yakalıyor; 45–60°'de yakalamıyor. Benzetimdeki anti-windup DF'de yok.
- **A için önceki yorum düzeltilmeli:** [`kopru_7b_sonuclar.md`](kopru_7b_sonuclar.md) ve [`secenekler_sonuclar.md`](secenekler_sonuclar.md)'de A'daki DF bozulması (frekans 2–5× yüksek) R = 0,17'ye bağlanmıştı. Temas sönümü eklenince A'nın frekans oranı 0,51'den 0,94'e çıktı: bozulmanın büyük kısmı eksik temas sönümünden. Hafif kolda c_s görece büyük (temas modu sönüm oranı R'ye bağlı).
- **Belirsizlik:** K_s (10) ve c_s (0,02) tahmin; c_s'nin etkisi büyük olduğu için düzenekte tanılanmalı.
- r_gs ≥ 1,0'da DF tam temasta kararsızlık öngörür; tork sınırıyla bu "S" (doyumla sınırlanan salınım) olarak işaretlenir, benzetimde düzensiz ya da çarpmalı salınım görülür. Bu bölgenin ayrıntısı DF'nin kapsamı dışında.

## Ek: γ_sınır ≈ 3ρ³ yasası (2026-10-18 boyutsuz haritası)

Kod: [`yasa_df.m`](yasa_df.m). Kayıt: [`yasa_df_log.txt`](yasa_df_log.txt). DF'ye PID desteği eklendi (kontrolcü iki polinomla: hız geri beslemesi [K_d 0] ve konum [K_p K_i]; P–PI'de [K_V K_I] ve k_p[K_V K_I]). Boyutsuz haritanın 24 düzeneği (uç kütlesi 0/20/50/100 g × 2r 1,5/3/5° × K_s 10/30; R 0,09–1,38; ideal model, PID) aynı açı ve kazanç ızgarasında DF ile hesaplandı; γ_sınır, 0°'dan başlayan kesintisiz salınım bandının bittiği γ.

| ρ | 0,13 | 0,18 | 0,23 | 0,28 | 0,33 |
|---|---|---|---|---|---|
| Benzetim, medyan (düzenekler arası max/min) | 0,006 (2,2×) | 0,017 (1,9×) | 0,035 (2,9×) | 0,066 (2,1×) | 0,14 (3,7×) |
| Yerçekimli DF | 0,030 (2,0×) | 0,070 (1,2×) | 0,129 (1,5×) | 0,248 (1,3×) | 0,387 (1,4×) |
| DF / benzetim (düzenek bazında medyan) | 5,6 | 4,3 | 3,8 | 3,9 | 2,6 |

Üs yasası uyumu (ρ 0,08–0,33): benzetim γ_sınır ≈ 3,3 ρ^3,0; DF γ_sınır ≈ 5,5 ρ^2,5. Tork sınırının DF'de etkisi yok (bu düzeneklerde salınım genliği doyuma ulaşmadan sınır belirleniyor).

- DF yasanın **biçimini** veriyor: bir üs yasası ve düzeneklerin tek bir eğri üzerinde toplanması (dağılım 1,2–2×). Üs 2,5'e karşı 3,0.
- DF sınırı **2,6–7,7 kat yüksek** öngörüyor (salınımın daha büyük ön yükte de sürdüğünü söylüyor); sapma düşük kazançta en büyük. Bu bölge Ghaffari'nin çarpma rejimi (r_gs ≲ 0,4), tek harmonik varsayımının en zayıf olduğu yer. Hata yönü D haritasındaki (kritik kazancın düşük öngörülmesi) ile aynı.
- Yasanın analitik karşılığı için DF tek başına yeterli değil; çarpma rejiminde kesin parçalı çözüm (Kollár 2003, Esbrook 2014 yaklaşımı) ya da çarpmalı DF gerekir. ρ ≳ 0,3 (deney hedef bölgesi 0,25–0,40) tarafında fark 2,6× ve azalıyor.
