# Framing adayları ve karşılaştırma

Bu not, danışmanın istediği çalışma notunun ilk aşamasına (framing) hazırlıktır. Amaç: aday araştırma vurgularını literatürle sınamak ve en güçlüsünü seçmek. Seçim yapıldıktan sonra framing metni, kısıtlar, blok şema ve malzeme listesi buna göre yazılacak; en sonda site güncellenecek.

## 1. Literatürün özeti

Danışmanın 13 kaynağı ve bizim önceki 37 kaynağımız birlikte okununca dört grup çıkıyor:

| Grup | Ne biliniyor | Kaynaklar |
|---|---|---|
| **Mekanizma (nitel)** | Yerçekimi dişliyi bir yüze bastırır; kol düşeyken dişli boşlukta serbest kalır; tork yön değiştirince karşı yüze geçiş olur. | Ahmad 1985, Karim 2018, Malzahn 2014, Xu 2023, Yu–Tang 2024 (giriş) |
| **Mekanizmanın ölçüm amaçlı kullanımı** | Sabit hızlı dönüşte yerçekimi sıfır geçişindeki darbeden boşluk kestirimi; açıya göre sönümlü titreşim haritası; açıya göre iki motor ofseti. | Giovannitti 2022, Malzahn 2014 (§4.8), Xu 2023 (Şekil 8) |
| **Kazanca bağlı limit cycle analizi (yerçekimsiz)** | Tanımlama fonksiyonu (DF) ile LC frekansı ve genliği; sertlik oranı rejimleri; tam parçalı doğrusal çözüm ve çatallanma. | Ghaffari 2013, C. Wang 2017, Hu 2017, Bai 2024, J. Wang 2024, Esbrook 2014, Kollár 2003 (üst denge) |
| **Bastırma** | Çift motorla aktif ön yük; gözlemci (ESO, DOB, SEDO); durum geri beslemesi; değişken kazanç. | Sun 2023, Xu 2023, Bai 2024, J. Wang 2024, G. Sun 2021, Yu–Tang 2024 |

**Ortadaki boşluk:** yerçekimli tek motorlu bir eklemde, sabit hedefte, *çalışma açısı × kontrol kazancı* düzleminde kendiliğinden süren salınımın sınırı ne haritalanmış ne de öngörülmüş. En yakın üç çalışmanın bu boşluğa göre durumu:
- Sun 2023 kazancı değiştiriyor ama tek açıda.
- Malzahn 2014 açıyı tarıyor ama dış uyarımlı sönümlü titreşimi ölçüyor; kazanç ekseni yok.
- Kollár 2003 kazanç düzleminde sınırı öngörüp deneyle karşılaştırıyor ama tek noktada (üst denge).

Bu boşluk tek başına "Yol 1" için zayıf: üç yakın çalışma onu daraltıyor. Bu yüzden katkı bir yöntem geliştirmesine bağlanmalı (Yol 2).

## 2. Değerlendirme ölçütleri

| # | Ölçüt | Soru |
|---|---|---|
| Ö1 | Fark netliği | En yakın çalışmadan farkı tek cümleyle söylenebiliyor mu? |
| Ö2 | Sayısal başarı ölçütü | "Bizimki X, eskisi Y" diye ölçülebiliyor mu? |
| Ö3 | Donanım uygunluğu | Dengeli listeyle (JGB37-520, AS5600, ESP32) yapılabilir mi? |
| Ö4 | Risk | Sonuç olumsuz çıkarsa elde ne kalır? |
| Ö5 | Yük ve süre | Matematik ve deney yükü dönem içine sığar mı? |
| Ö6 | Danışmanın vurgusu | E-postadaki uyarılarla uyumlu mu? |

## 3. Adaylar

### A. Kaymalı DF ile açı–kazanç LC sınırının öngörüsü (genel)
- **Temel yöntem:** DF ile LC analizi (C. Wang 2017, Bai 2024, J. Wang 2024).
- **Eksiklik:** hepsi simetrik boşluk ve sıfır ortalama tork varsayıyor. Yerçekimi boşluk girişine açıya bağlı bir kayma ekliyor.
- **Geliştirme:** kaymalı (iki girişli) DF ile sınırın θ₀ ve kazancın fonksiyonu olarak öngörülmesi.
- **Ölçüt:** öngörülen sınırın simülasyon ve deneyden sapması; aynı veride simetrik DF ile karşılaştırma.
- **Zayıflık:** kaymalı DF ders kitabı aracı (Gelb–Vander Velde 1968). Katkı "uygulama + doğrulama" gibi görünebilir. Temel alınan makale belirsiz kalıyor.

### B. Ghaffari 2013'ün ön yük analizini yerçekiminin tek yönlü, açıya bağlı ön yüküne genişletmek ⭐
- **Temel yöntem:** Ghaffari 2013. Tek döngüye indirgeme + DF + sertlik oranı r_gs ile rejim sınıflaması (kararsız / rezonans LC / çarpma). İki endüstriyel tezgâhta doğrulanmış. Danışman bunu "boyutsuzlaştırma ve analitik referans model için temel kaynak" diye işaretlemiş.
- **Eksiklik:** Ghaffari'de ön yük **simetrik** ve **sabit** (yaylı anti-boşluk mekanizması, ±τ_p). Yerçekimi ise **tek yönlü** (dişliyi yalnız bir yüze bastırır) ve **açıyla değişir** (mgℓ sinθ₀). Ghaffari'nin kendi gözlemi ("tork ön yükü aşmadıkça boşluk görünmez") yerçekimi için açıya bağlı bir eşik koşuluna dönüşüyor, ama bu formülleştirilmemiş.
- **Geliştirme:** Ghaffari'nin n(θ_d) ifadesini tek yönlü kayma ile yeniden türetmek → rejim sınırlarını (r_gs eşikleri) γ = mgℓ sinθ₀/(K_s·r)'nin fonksiyonu yapmak. Bizim simülasyonda bulduğumuz γ_sınır ≈ 3·r_s³ yasasının analitik karşılığını aramak.
- **Ölçüt:** (i) sınır öngörüsü: öngörülen ve ölçülen sınır arasındaki fark (açı ve kazanç cinsinden); (ii) LC frekansı ve genliği; (iii) Ghaffari'nin yerçekimsiz formülü ve simetrik DF ile aynı veride karşılaştırma.
- **Doğal yeniden üretim adımı:** danışmanın 4. aşamada istediği "önce yakın bir literatür sonucunu yeniden üret" adımı için Ghaffari'nin döner tabla sonuçları (frekans tahmini, %2–24 hata) ilk hedef; Sun 2023 (K_p=20 / 50) ikinci hedef.
- **Risk ve oran eşlemesi:** Ghaffari'ye göre r_gs ≤ 0,4'te **çarpma rejimi** başlıyor ve DF bozuluyor. Eşleme (bkz. 5. bölüm) bizim hedef bölgemizin (r_s ≈ 0,25–0,40 → r_gs ≈ 0,5–0,8) Ghaffari'nin **rezonans LC rejiminde**, yani DF'nin geçerli olduğu bölgede kaldığını gösteriyor. Daha düşük kazançlarda çarpma rejimi için C gerekir.

### C. Tam parçalı doğrusal çözüm ya da çatallanma analiziyle sınır
- **Temel yöntem:** Kollár 2003 (P–D düzleminde kesin çözüm, Hopf ve homoklinik eğriler, deney) ve Esbrook–Tan–Khalil 2014 (anahtarlamalı sistem, Newton–Raphson ile kesin LC).
- **Eksiklik:** tek çalışma noktası (Kollár'da üst denge, Esbrook'ta yerçekimsiz; Önerme 2: sabit referans LC'yi yalnız kaydırır).
- **Geliştirme:** çalışma açısını parametre olarak ekleyip sınırı kesin çözümle haritalamak; tek kenarlı ve çift kenarlı salınımı ayırmak.
- **Ölçüt:** DF'nin bozulduğu çarpma rejiminde bile sınırı doğru vermesi.
- **Zayıflık:** matematik yükü yüksek, kapalı form vermiyor (sayısal). Tek başına katkı olmaktan çok B'nin doğrulama aracı olarak güçlü.

### D. Öngörülü (açıya göre programlanmış) kazanç ya da gözlemci bant genişliği
- **Temel yöntem:** G. Sun 2021 (kazanç gözlemci hatasına ve temas kipine göre değişiyor, *tepkisel*), Bai 2024 (sabit bant genişliği), Yu–Tang 2024 (sabit doyum eşiği).
- **Geliştirme:** kazancı ya da bant genişliğini θ₀'dan önceden hesaplanan sınıra göre ayarlamak (*öngörülü*).
- **Ölçüt:** aynı "salınımsız" koşul altında açı boyunca elde edilen yerleşme süresi ya da bant genişliği; sabit kazanç ve G. Sun kuralıyla karşılaştırma.
- **Zayıflık:** danışmanın "gözlemciyle salınım bastırma daha önce çalışıldı" ve "yöntemleri birleştirmek tek başına katkı değil" uyarılarına en çok takılan aday. Önce B'nin sınır modeli gerekiyor. Bağımsız bir framing olarak değil, B'nin uygulama katmanı olarak anlamlı.

### E. Hareket halinde yerçekimi sıfır geçişi için tek motorlu tork ya da yörünge şekillendirme
- **Temel yöntem:** Xu 2023 (çift motorla ön yük), otomotiv aktarma organlarında "boşluk geçişi" (gap traversal) kontrolü.
- **Geliştirme:** kol dikten geçerken tek motorla yumuşak geçiş.
- **Zayıflık:** konu sabit hedefteki LC'den farklı; simülasyonumuz buna hazır değil; otomotiv literatürü geniş, ayrıca taranmalı. Şimdiki çalışmadan kopuk.

### F. Sınırdan boşluk ya da aşınma kestirimi
- **Temel yöntem:** Giovannitti 2022 (sabit hızlı dönüşte yerçekimi sıfır geçişindeki darbeden boşluk kestirimi, ek sensörsüz).
- **Geliştirme:** duran kolda birkaç açıda kazanç taranır, LC'nin başladığı sınır B'nin modeline ters çevrilerek boşluk genişliği kestirilir.
- **Ölçüt:** kestirilen boşluğun gerçek boşluktan sapması. **Bizim ayarlanabilir kaplin (1,5 / 3 / 5°) gerçek değeri veriyor**; Giovannitti'nin üretim robotlarında olmayan bir şey. Aynı düzenekte Giovannitti'nin sabit hız testi de uygulanıp iki yöntem karşılaştırılabilir.
- **Zayıflık:** B'nin modeli tutmazsa F de çöker. LC'yi bilerek uyarmak endüstriyel açıdan tartışmalı (kısa ve kontrollü test olarak savunulabilir).

### G. Rejim haritası (sönümlü / zorlanmış / LC / kararsız)
- Danışmanın simülasyon aşamasında zaten istediği sınıflama. Malzahn (sönümlü) ve Lu 2015 (zorlanmış) literatür örnekleri. Tek başına katkı değil, B'nin sonuç bölümü.

## 4. Karşılaştırma

Puan: ●●● güçlü · ●● orta · ● zayıf

| Aday | Ö1 Fark | Ö2 Ölçüt | Ö3 Donanım | Ö4 Risk | Ö5 Yük | Ö6 Danışman | Rol |
|---|---|---|---|---|---|---|---|
| A. Kaymalı DF (genel) | ●● | ●●● | ●●● | ●● | ●● | ●● | B'ye dahil |
| **B. Ghaffari + yerçekimi** | ●●● | ●●● | ●●● | ●● | ●● | ●●● | **Ana katkı** |
| C. Kesin çözüm / çatallanma | ●● | ●●● | ●●● | ●●● | ● | ●● | B'nin doğrulama aracı |
| D. Öngörülü kazanç | ●● | ●●● | ●●● | ● | ●● | ● | Uzantı (ileride) |
| E. Hareket halinde geçiş | ●● | ●● | ●● | ●● | ● | ● | Kapsam dışı |
| F. Sınırdan boşluk kestirimi | ●●● | ●●● | ●●● | ● | ●● | ●● | Uzantı (deney yeterse) |
| G. Rejim haritası | ● | ●● | ●●● | ●●● | ●●● | ●●● | B'nin sonuç bölümü |

## 5. Öneri

**Ana katkı B (Yol 2):** Ghaffari 2013'ün simetrik mekanik ön yük için kurduğu DF ve sertlik oranı analizini, yerçekiminin tek yönlü ve açıya bağlı ön yüküne genişletmek. Böylece açı–kazanç düzleminde LC sınırını öngörmek ve tek motorlu ucuz bir düzenekte doğrulamak.

- C, DF'nin bozulduğu çarpma rejiminde referans olarak kullanılır. Simülasyonda zaten "kesin" sonucu veren sayısal benzetim var; C onun analitik ya da yarı analitik karşılığı.
- G, sonuçların sunuluş biçimi olur.
- F ya da D, ana katkı tuttuktan sonra eklenebilecek uygulama katmanıdır. F'nin ayarlanabilir kaplin sayesinde gerçek bir ölçütü var; D danışmanın uyarısına daha çok takılıyor.

### Oran eşlemesi: bizim r_s ↔ Ghaffari r_gs ↔ C. Wang 2017 r_s

İki oran aynı sembolle anılsa da aynı tanım değil (danışmanın uyarısı doğru):

| | Tanım | Kontrolcü |
|---|---|---|
| Ghaffari 2013, C. Wang 2017 | r_gs = √(k_p k_v / K_s) | P konum (k_p, 1/s) + PI hız (k_v, N·m·s/rad) |
| Bizim simülasyon | r_s = ω_c / ω_rez, ω_rez = √(K_s / J_eff), J_eff = J_M J_L / (J_M + J_L) | PID: K_p = J ω_c², K_d = 1,4 J ω_c, K_i = K_p ω_c / 4 (J = J_M + J_L) |

Kademeli P–PI'nin oransal kısmı eşdeğer PD'ye çevrilince torkun konum katsayısı k_v·k_p olur. Bu bizim K_p = J ω_c²'ye denk. Buradan:

**r_gs = ω_c √(J / K_s) = r_s · √(J / J_eff) = r_s · (J_M + J_L) / √(J_M J_L)**

Simülasyon parametrelerinde (J_M = 1,73·10⁻³, J_L = 1,28·10⁻³ kg·m², kol tarafı) çarpan ≈ 2,0, yani **r_gs ≈ 2 r_s**. Karşılıkları:

| Bizim r_s | Ghaffari r_gs | Ghaffari rejimi | Bizim simülasyonda görülen |
|---|---|---|---|
| ≤ 0,18 | ≤ 0,36 | Çarpma (DF bozuk) | Sürtünme baskın, düzenekler arası dağılım büyük |
| 0,23–0,38 (deney hedefi) | 0,46–0,76 | Rezonans LC (DF geçerli) | γ_sınır ≈ 3 r_s³ yasası tutuyor |
| ≥ 0,5 | ≥ 1 | Kararsız | Doğrusal kararlılık sınırı |

İki bağımsız sınıflama birbiriyle tutarlı. **Sonuç:** deney hedef bölgemiz DF'nin geçerli olduğu rejimde kalıyor, B'nin DF kısmı bu bölgede uygulanabilir. Uyarılar:
1. Çarpan J_M/J_L oranına bağlı. JGB37-520'nin rotor eylemsizliği ve 20 g uç kütlesiyle yeniden hesaplanmalı. J_M ≫ J_L olursa çarpan büyür.
2. Kontrolcü yapıları birebir aynı değil (bizde K_d K_p'ye bağlı ve integral var). Karşılaştırma için simülasyonda bir de Ghaffari'nin P–PI yapısı koşulmalı.
3. C. Wang 2017'nin r_s'si Ghaffari'nin r_gs'siyle aynı tanım; bizim r_s'den farklı. Makalede sembol çakışmasını önlemek için bizimki yeniden adlandırılmalı (ör. ρ).

## Kaynaklar

Ayrıntılı notlar: `literatur/okuma_notlari.md` ("Danışmanın listesinden eklenen kaynaklar" bölümü ve önceki bölümler).
