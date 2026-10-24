# Son tarama (24 Ekim 2026)

Amaç: framing kararından önce önerilen yönün (B: Ghaffari 2013'ün ön yük analizini yerçekiminin tek yönlü, açıya bağlı ön yüküne genişletmek; L: açı taramasıyla salınım kaynağını ayırma; H: yerçekimi dengelemesinin etkisi; O: açıya göre geri besleme harmanlama) son kez sınanması.

## Yöntem

1. **İleriye atıf taraması (OpenAlex):** en yakın 8 çalışmayı atıf yapan bütün kayıtların başlıkları tarandı, ilgili görünenlerin özeti okundu.

   | Kaynak | Atıf |
   |---|---|
   | Ghaffari 2013 | 17 |
   | Malzahn 2014 | 9 |
   | Kollár 2003 | 5 |
   | Giovannitti 2022 | 15 |
   | Ruderman 2019 | 16 |
   | Karim 2018 | 2 |
   | Xu 2023 | 9 |
   | Márton 2009 | 2 |
   | **Toplam** | **75** |

   Sun 2023'ün atıfları 22 Ekim'de WoS'ta, J. Wang 2024'ünkiler 18 Ekim'de tarandığı için tekrarlanmadı.
2. **Hedefli anahtar kelime sorguları (OpenAlex, başlık + özet), 17 sorgu:** backlash ile birlikte gravity / gravitational / self-excited / operating point / load torque + describing function / biased DF / dual-input DF / gravity compensation / counterbalance / configuration-dependent / posture / hunting / dual-loop + gain scheduling / load- ve motor-side encoder / friction + distinguish / natural preload / gravity preload.
3. **Web araması:** biri genişletilmiş 4 arama (2025–2026 çalışmaları, arXiv, döner tabla grubu).
4. Erişilebilen tam metin: Yang ve ark. 2015 (Springer, kurum erişimi). Yang ve ark. 2017 (SAGE) kurum aboneliğinde yok.

## Sonuçlar

**Anahtar kelime sorguları:** 17 sorgunun 13'ü sıfır kayıt döndürdü. Kalan 4 sorgu 6 kayıt döndürdü; bunlardan yalnız biri (1973 tarihli tanımlama fonksiyonu makalesi) konuyla ilgili, diğerleri alakasız. "Yerçekimi + boşluk + limit cycle" ve "dengeleme + boşluk + salınım" kesişimleri boş.

**Yeni anılacak kaynaklar (doğrudan rakip yok):**

| Kaynak | Ne yapıyor | Bizden farkı | Nerede kullanılır |
|---|---|---|---|
| Yang, Lu, Liu, Zhang, Zhao 2015, *Front. Mech. Eng.* 10:43–47 (10.1007/s11465-015-0327-0) | Takım tezgâhı döner tablasında boşluk kaynaklı durağan titreşim; genlik konum kazancı, yük ve boşlukla artıyor, frekans yükle azalıyor. Ghaffari'ye atıf. | **Tam metin okundu:** "yük" yalnız eylemsizlik (J_t = dişli + tabla + yük), tabla yatay; yerçekimi torku yok. | Kazanç–genlik ilişkisi için karşılaştırma |
| Yang, Lu, Zhang, Zhao 2017, *Proc. IMechE C* 231(22):4163–4171 (10.1177/0954406216662086) | Aynı grup. Kazanç düzleminde bir "kararlılık bölgesi" tanımlıyor; kritik bölgede titreşim yalnız tek hareket yönünde. Yük ve boşluğun bölgeye etkisi. | Yalnız özet okundu. Aynı yatay döner tabla olması muhtemel; yön etkisi yerçekiminden değil hareket yönünden. Açı ekseni yok. | Kazanç düzleminde sınır fikrinin öncülü (Kollár ile birlikte). Tam metin kampüste kontrol edilmeli. |
| Döner tabla, fren ve boşluk, *J. Vib. Control* ~2015 ("How to prevent undesired oscillation in NC rotary table") | Ağır torna-frezelerde boşluğun etkisini azaltmak için sürtünme freni; sürtünme + boşluk etkileşimi DF ile; LC'yi önleyen basit ayar kuralları. | Yerçekimi yok. Fren bir "sürtünme ön yükü" gibi çalışıyor. | L (sürtünme–boşluk ayrımı) ve I (pasif ön yük) için öncül |
| Energies 2024, 17(14):3582 (10.3390/en17143582), "A gap nonlinearity compensation strategy for non-direct-drive servo systems" | Tam-kapalı çevrimde DF ile LC frekansı (kontrol sertliğine bağlı, boşluktan bağımsız); durum geri beslemesi. | Yerçekimi yok, tek nokta. C. Wang 2017 ailesi. | Literatür tablosunda bir satır |
| 1973 *Int. J. Control*, "Dual-input describing function of 'backlash type' double-valued non-linearities" | Boşluk tipi doğrusal olmayanlıklar için iki girişli (kaymalı) tanımlama fonksiyonu. | Matematiksel araç, uygulama yok. | **Önemli:** kaymalı DF aracı 1973'ten beri var. Katkımız aracın kendisi değil, yerçekimli kolda açıya bağlı ön yüke uygulanması, Ghaffari çerçevesine bağlanması ve deneyle doğrulanması. Makalede atıf yapılmalı. |
| Ruderman, Yamada, Fujimoto 2019, *J. Dyn. Syst. Meas. Control* (arXiv 1802.06246'nın dergi sürümü) | Röleyle bilerek LC uyandırıp boşluk tanılama. | Yerçekimi yok. | F'ye rakip (önceki turda not edildi) |
| ABD patenti 11602838, "Process and system for monitoring backlash in a gear of a joint of an industrial robot" | Bazı duruşlarda dişlilerin yerçekimiyle tek yüzde temas ettiğini, boşluğun yalnız öbür tarafta kaldığını belirtiyor. | Nitel; analiz yok. | Mekanizma grubuna bir nitel kaynak daha |

**Sonuç:** son taramada yeni bir doğrudan rakip çıkmadı. Önerilen yönün literatürdeki boşluğu (açı × kazanç düzleminde LC sınırının öngörüsü, yerçekiminin tek yönlü ve açıya bağlı ön yükü ile) ayakta. Taramanın getirdiği iki düzeltme:

1. **Kaymalı DF'nin kendisi yeni değil** (1973). Framing metninde katkı "yeni araç" diye değil, "Ghaffari 2013 çerçevesinin yerçekimli eklem için genişletilmesi ve doğrulanması" diye yazılmalı.
2. **Kazanç düzleminde LC sınırı fikrinin iki öncülü var:** Kollár 2003 (sarkaç, üst denge) ve Yang 2017 (döner tabla). Farkımız: üçüncü eksen olarak çalışma açısı ve yerçekiminin tek yönlü ön yükü.
