# Düzenek seçenekleri: A / B1 / B2 / C / D karşılaştırması

Kod: [`secenekler.m`](secenekler.m). Kayıt: [`secenekler_log.txt`](secenekler_log.txt). Arka plan: [`kopru_7b_sonuclar.md`](kopru_7b_sonuclar.md) (dengeli listenin düzeneğinde R = J_L/J_M = 0,17 ve Ghaffari DF'si geçersiz).

Ortak ayarlar: P–PI (hız döngüsü bant genişliği ω_a, PI sıfırı 0,05 ω_a), 2r = 3°, K_s = 10 N·m/rad ve rotor eylemsizliği 4·10⁻⁶ kg·m² (ikisi de tahmin), ideal sensör (sensör etkileri 7c'de). Yerçekimli haritalar gerçek tork sınırıyla; her nokta üç başlangıç sapmasıyla (0,2°, 1°, 5°) koşuldu ve `rejim_sinifla` ile sınıflandı.

| | Düzenek | R | f_a | mgl | Tmax | mgl/Tmax |
|---|---|---|---|---|---|---|
| **A** | Dengeli liste: JGB37 1:30, 20 g çubuk + 20 g uç | 0,17 | 20,5 Hz | 0,044 N·m | 0,49 | 0,09 |
| **B1** | A + dengelenmiş ek eylemsizlik (J_L = J_M) | 1,0 | 8,4 Hz | 0,044 | 0,49 | 0,09 |
| **B2** | A + dengelenmiş ek eylemsizlik (J_L = 2 J_M) | 2,0 | 5,9 Hz | 0,044 | 0,49 | 0,09 |
| **C** | JGB37 1:10, aynı kol | 1,5 | 20,5 Hz | 0,044 | 0,16* | 0,27 |
| **D** | A + ağır uç kütlesi (≈ 153 g, J_L = J_M) | 1,0 | 8,4 Hz | 0,240 | 0,49 | 0,49 |

\* 0,49/3 varsayımı; JGB37 1:10'un veri sayfasıyla doğrulanmalı.

## 1. Ghaffari çerçevesi (yerçekimsiz): DF frekansına oran, kararsızlık

| | sim/DF, r_gs = 0,5 / 0,7 / 0,9 | Kararsızlık |
|---|---|---|
| A | 0,37 / 0,46 / 0,52 | yok (≤ 1,3) |
| B1, D | 0,72 / 0,85 / 0,90 | r_gs ≥ 1,1 |
| B2 | 0,76 / 0,89 / 0,94 | r_gs ≥ 1,1 |
| C | 0,63 / 0,76 / 0,83 | r_gs ≥ 1,3 |

## 2. Yerçekimli açı × r_gs haritaları

`.` denge, `s` sönümlü, `C` kalıcı çevrim, `X` kararsız, `?` düzensiz; `*` başlangıç koşuluna bağlı. Açı: 0 sarkık, 90 yatay, 180 dik.

```
            A (R 0,17)                        B1 (R 1, dengeli ek)              D (R 1, ağır uç)
 açı:   0  10  20  30  45  60  90 135 180  |  0  10  20  30  45  60  90 135 180 |  0  10  20  30  45  60  90 135 180
 0,3:  s*   .   .   .   .   .   .   .   .  | C*   .   .   .   .   .   .   .   C | s*   .   .   .   .   .   .   .   ?
 0,5:  C*   .   .   .   .   .   .   .   C  |  C  C*  s*   .   .   .   .   .   C | C*   .   .   .   .   .   .   .   C
 0,7:  C*  ?*   .   .   .   .   .   .   C  |  C   C   C   C  C*  C*  C*  C*   C | C*  C*  s*   .   .   .   .   .   C
 0,9:  C*   C  C*  ?*  s*   .   .  s*   C  |  C   C   C   C   C   C   C   C   C | C*   C   C  ?*   s   s  s*   s   C
 1,1:  C*   C   C   C  C*  C*  C*   C   C  |  C   C   C   C   C   C   C   C   C | C*   C   C   C   ?   C   C  ?*   C
 1,3:  C*   C   C   C   C   C   C   C   C  |  C   C   C   C   C   C   C   C   C | C*   C   C   ?   s  ?*   ?  X*   C

            B2 (R 2, dengeli ek)              C (N = 10)
 0,3:  ?*   .   .   .   .   .   .   .   s  | C*   .   .   .   .   .   .   .   C
 0,5:  ?*  ?*  s*  s*   .   .   .   .   C  | C*  ?*  s*   .   .   .   .   .   C
 0,7:  ?*   C   C   C  C*  C*  C*  C*   C  | C*   C   C  ?*   .   .   .   .   C
 0,9:   C   C   C   C   C   C   C   C   C  |  C   C   C  ?*  ?*   ?   s  ?*   C
 1,1:   C   C   C   C   C   C   C   C   C  |  C   C   C   C   ?   ?  ?*   ?   C
 1,3:   C   C   C   C   C   C   C   C   C  |  C   C   C   C   C   ?   ?   ?   C
```

| | Çevrim frekansı | Genlik | Doyumda geçen süre (ort. / en çok) |
|---|---|---|---|
| A | 3,4–13,7 Hz | 1,7–4,0° | %7 / %49 |
| B1 | 0,6–7,0 Hz | 0,2–5,3° | %24 / %69 |
| B2 | 1,0–5,2 Hz | 1,7–4,9° | %21 / %60 |
| C | 2,1–13,9 Hz | 1,7–3,4° | %22 / %85 |
| D | 2,7–8,1 Hz | 1,5–5,3° | %16 / %84 |

## Değerlendirme

- **Hipotez (yerçekimi salınımı açıya bağlı bastırır) beş düzenekte de görülüyor:** 0° ve 180°'de (sin θ₀ = 0) salınım var, ara açılarda kazanç arttıkça daralan bir bastırma bölgesi var. Ne kadar geniş bir kazanç aralığında görüldüğü düzeneğe bağlı.
- **A:** bastırma bölgesi r_gs 0,5–0,9 boyunca geniş ve düzenli; tork payı rahat (doyum ort. %7). Ama Ghaffari DF'si geçersiz (frekans 2–3 kat yüksek): 4b'nin temeli DF olamaz.
  - **Güncelleme (4b, [`yercekimli_sonuclar.md`](yercekimli_sonuclar.md)):** bu bozulmanın büyük kısmı R'den değil, DF'de olmayan temas sönümünden geliyor. Temas sönümü (c_s = 0,02) DF'ye eklenince A'nın frekans oranı (benzetim/DF) 0,51'den 0,94'e, kritik kazanç hatası %55'ten %27'ye iniyor. Hafif kolda temas modunun sönüm oranı büyük (ζ_c = 0,14; D'de 0,075). "4b'nin temeli DF olamaz" yargısı A için de geçerli değil; D önerisinin tork payı ve R'yi tarama gerekçeleri ise duruyor.
- **B1, B2:** DF geçerli, ama bastırma yalnız r_gs ≤ 0,5'te; r_gs ≥ 0,7'de her açıda salınım var. Dengelenmiş eylemsizlik salınımın dinamik torkunu büyütüyor, mgl ise aynı kalıyor; yerçekimi göreli olarak zayıflıyor. Hipotezi sınamak için en zayıf seçenekler.
- **C:** DF A'dan iyi, B'den kötü; tork sınırı dar (mgl/Tmax 0,27), yüksek kazançta ara açılarda düzensiz salınım ve %85'e varan doyum. Ayrıca farklı dişli kutusu (boşluk, stok, enkoder çözünürlüğü 3 kat kaba).
- **D:** yerçekimsiz davranışı B1 ile aynı (DF geçerli, Ghaffari'nin kararsızlık eşiği tutuyor), yerçekimli haritası A'ya benziyor (bastırma r_gs 0,5–1,1 boyunca). Bedeli tork payı: 90°'de yerçekimi motor torkunun yarısını alıyor; r_gs ≥ 1,1'de doyum ve düzensiz salınım artıyor. Uç kütlesi değiştirilebildiği için R ve γ birlikte ayarlanabilir; ara değerler (örn. 80–100 g, R ≈ 0,5–0,7) tork payını genişletir.
- **Öneri:** D (ağır uç kütlesi), 0–150 g arası değiştirilebilir uç kütlesiyle. Böylece A ve D aynı düzenekte iki uç olur ve deney R'yi bir değişken olarak tarar; 4b'nin DF'si D tarafında doğrulanır, A tarafında DF'nin bozulduğu yer de bir sonuç olarak raporlanır. Malzeme listesindeki "ağırlıklar (M8 somun/rondela)" kalemi buna göre büyütülmeli; DRV8874 akım sınırı ve motor ısınması (90°'de sürekli ≈ 0,24 N·m) TMP117 ile izlenmeli.

## Sınırlar

- Rotor eylemsizliği ve K_s tahmin; R ve f_a bunlara bağlı (bkz. kopru_7b_sonuclar.md).
- İdeal sensör ve sürekli kontrol; AS5600 gecikmesi, nicemleme ve 1 kHz örnekleme 7c'de eklenecek.
- Tek boşluk (2r = 3°) ve tek PI ayarı; hız döngüsü bant genişliği rejimi değiştiriyor (kopru_7b_sonuclar.md, bulgu 1).
