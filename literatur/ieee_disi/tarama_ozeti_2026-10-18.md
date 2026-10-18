# IEEE dışı literatür taraması (18 Ekim 2026)

## Erişim durumu
- Kütüphane listesinde: Springer Nature Journals, SpringerLink, ScienceDirect (Freedom Collection), Taylor & Francis, Scopus, Web of Science.
- Scopus/WoS kampüs dışından kurumsal oturum istiyor (Elsevier giriş ekranı). Bu yüzden tarama OpenAlex (tüm yayınevlerini indeksleyen açık veri tabanı), Semantic Scholar, Crossref ve arXiv ile yapıldı. PDF gereken makaleler kurumsal girişle ayrıca açılacak.

## Yöntem
1. Başlık+özet içinde zorunlu terim birleşimleri (OpenAlex `title_and_abstract.search`). Ham çıktılar: `ham_openalex_1.txt`, `ham_openalex_2.txt`.
2. İleriye doğru atıf taraması: en yakın makalelere atıf yapan her çalışma tarandı. Ham çıktılar: `ham_atif_yapanlar_1.txt`, `ham_atif_yapanlar_2.txt`.
   - Wang ve ark. 2024 (Nonlinear Dynamics): 11 atıf, hiçbiri yerçekimi/açı ile ilgili değil.
   - Kollár ve ark. 2002 (CDC): 1 atıf (ilgisiz).
   - Sun ve ark. 2025 (TAES): 4 atıf (füze/uçuş, ilgisiz).
   - Limited Amplitude-DOB 2023 (TIE): 17 atıf, hepsi gimbal/çift motor/ESO; yerçekimi yok.
   - Nordin–Gutman 2002 anketi (Automatica): 497 atıfın tamamı başlıkla süzüldü.
3. arXiv: boşluk+yerçekimi, boşluk+limit cycle, boşluk+sarkaç.

## Sayılar
| Sorgu (başlık+özet) | Sonuç |
|---|---|
| backlash AND gravity AND (robot/manipulator/arm/joint/pendulum) | 32 (hiçbiri açıya bağlı yerçekimi + salınım değil) |
| backlash AND "limit cycle" AND (robot/…/motor) | 60 |
| backlash AND "describing function" AND (robot/…/arm) | 35 |
| backlash AND observer AND "limit cycle" | 13 |
| (backlash OR dead zone) AND gravity AND "describing function" | **0** |
| backlash AND "gravity compensation" AND (oscillation/limit cycle) | **0** |
| backlash AND (torque reversal / zero crossing) AND gravity | **0** |
| backlash AND gravity AND (preload/load reversal/torque reversal) | 1 (NASA optik platform, ilgisiz) |

## Sonuç
Aday boşluk ayakta: yerçekimi momentinin eklem açısına bağlı ön yükü (mgℓ sinθ₀) ile boşluk kaynaklı limit cycle arasındaki ilişkiyi inceleyen, tanımlama fonksiyonuyla açıya göre harita çıkaran veya gözlemci kazancını açıya göre ayarlayan çalışma bulunamadı.

**Dürüstlük notu (makalede böyle yazılmalı):** "Sabit bir yük momenti dişliyi bir tarafa bastırır, boşluk geçişini önler" fikri yeni değil. Çift motorlu anti-boşluk (drive–anti-drive) ve mekanik ön yük bu ilkeye dayanır. Yenilik bu ilkede değil; yerçekiminin açıyla değişen, 0° ve 180° civarında sıfırlanan doğal bir ön yük olması, bunun limit cycle bölgelerini nasıl kaydırdığı ve gözlemci tasarımına etkisi.

## Atıf verilecek yeni kaynaklar (önem sırası)
1. **Nordin, Gutman 2002**, Automatica, "Controlling mechanical systems with backlash—a survey", 10.1016/s0005-1098(02)00047-x. Alanın temel anketi; giriş bölümü buna dayanır. ScienceDirect'ten alınmalı.
2. **Ghaffari, Mohammadiasl 2013**, IEEE/ASME TMECH, "Calculating the frequency of oscillation for servo axes distressed by clearance or preloading", 10.1109/TMECH.2012.2195670. Takım tezgâhı, iki kütle, tanımlama fonksiyonu; boşluk VE ön yük, deneyli. Ön yük mekanik ve sabit, yerçekimi yok. Bizim en yakın yöntemsel örneğimiz.
3. **Wang ve ark. 2017**, IEEE TIE, "Analysis and suppression of limit cycle oscillation for transmission system with backlash nonlinearity", 10.1109/TIE.2017.2711564. İki kütle, tam kapalı çevrim, tanımlama fonksiyonu; yatay, yerçekimi yok.
4. **Limited Amplitude-Disturbance Observer Control for Backlash-Containing Electromechanical System**, IEEE TIE 2023, 10.1109/TIE.2023.3290240. DOB + boşluk + limit cycle; gözlemci tarafında en yakın güncel rakip.
5. **Márton, Lantos** IFAC 2009 ve 2010 ("Backlash and friction reciprocal effect on limit cycle existence"; "Limit cycle existence condition in control systems with backlash and friction"). ECC 2009 makalesinin devamı.
6. **Limit cycle analysis for drive systems with backlash nonlinearity using an eigenvalue method**, IEEE/ASME AIM 2019, 10.1109/AIM.2019.8868674. Harmonik denge + deney (iki kütle).
7. **Dynamic backlash PD analizi**: Nordin ve ark., J. Vibration and Control 2003, 10.1177/107754603030744.
8. **Rüzgâr türbini dişli kutusunda yerçekimi etkisi**: Guo, Keller, Parker 2014, Eur. J. Mech. A/Solids, 10.1016/j.euromechsol.2014.02.013 (78 atıf). Yerçekiminin dişli temasını kaybettirmesi dişli dinamiğinde inceleniyor ama kontrol/limit cycle açısından değil. "Benzer mekanizma başka alanda var" diye analoji olarak gösterilir.
9. **Ters sarkaç + boşluk**: Furuta sarkacı H∞ (Asian J. Control 2010, 10.1002/asjc.202); drive–anti-drive PID (Applied Sciences 2024, 10.3390/app142210265). Sabit açı (üst denge), açıya bağlı inceleme yok.
10. **Endüstriyel robotta boşluk tanılama**: sanal boşluk sensörü (J. Intell. Manuf. 2022, 10.1007/s10845-022-01934-z); deneysel boşluk çalışması (Robotica 2010, 10.1017/s0263574710000056). Tanılama, kontrol değil.

## Alınması gereken PDF'ler (kurumsal girişle)
- Wang ve ark. 2024, Nonlinear Dynamics (Springer) — hâlâ en yakın rakip, yerçekimi olmadığını tam metinden doğrulamak şart.
- Nordin–Gutman 2002 (ScienceDirect).
- Ghaffari 2013 TMECH ve Wang 2017 TIE (IEEE, mevcut erişimle).
- Limited Amplitude-DOB 2023 TIE (IEEE).
