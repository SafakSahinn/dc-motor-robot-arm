# Web of Science taraması (22 Ekim 2026)

**Erişim:** Kurum girişi (YETKİM → İstinye) yine "Shibboleth error 90011" verdi. Ancak WoS ayrı bir sekmede açılınca oturum "Istinye Universitesi" yetkisiyle geldi ve Core Collection'da tam arama yapılabildi. Taranan dizin: Web of Science Core Collection, tüm sürümler, tüm yıllar.

## Sorgular (Advanced Search, TS = başlık + özet + anahtar kelime)

| # | Sorgu | Sonuç |
|---|---|---|
| 1 | `TS=(backlash AND gravit* AND ("limit cycle*" OR oscillat*))` | 2 |
| 2 | `TS=(backlash AND gravit* AND "describing function*")` | **0** |
| 3 | `TS=(backlash AND (gravit* OR "gravity load*" OR "gravitational torque*") AND (manipulator* OR robot* OR "single link" OR "single-link" OR joint*))` | 21 |
| 4 | `TS=(backlash AND (preload* OR pre-load*) AND ("limit cycle*" OR oscillat* OR hunting))` | 8 |
| 5 | `TS=(backlash AND ("disturbance observer*" OR "extended state observer*") AND gravit*)` | 1 |
| 6 | `TS=(backlash AND ("biased describing function*" OR "dual input describing function*" OR "two-sinusoid*" OR "bias describing"))` | **0** |
| 7 | `TS=(backlash AND "limit cycle*" AND (angle* OR "operating point*" OR "working point*" OR posture* OR configuration*))` | 4 |
| 8 | `TS=(backlash AND pendulum AND ("limit cycle*" OR oscillat*))` | 10 |
| 9 | `#1 OR #3 OR #4 OR #5 OR #7 OR #8` | 44 (tek tek incelendi) |
| 10 | `TS=(backlash AND (gravit* OR "unbalanced load*" OR "eccentric load*" OR "gravity torque*" OR "load torque*") AND ("limit cycle*" OR "self-excited" OR "self-sustained"))` | 1 |
| 11 | `TS=((backlash OR "gear clearance" OR "gear play") AND gear* AND gravit* AND (servo* OR "position control*" OR observer*))` | 1 |
| 13 | `(#10 OR #11) NOT #9` | 1 (yeni) |

## 44 + 1 kaydın değerlendirmesi

Hiçbiri yerçekiminin açıya bağlı ön yükünü boşluk limit cycle'ı ile ilişkilendirmiyor. Kayıtların çoğu konu dışında: dişli dinamiği (MSSP), takım tezgâhı, teleskop, haptik, kurt yönetimi ("pendulum swings") gibi. #1 ve #5'teki 3 kaydın "gravity" eşleşmesi ilgisiz (uzay istasyonu manipülatörü, doğrusal motor tezgâhı, düz dişli modeli).

Yakından bakılan, özeti okunanlar:
- **Azar, Serrano 2016**, Int. J. System Dynamics Applications: boşluklu sistemde PI döngü şekillendirme ve DF ile limit cycle; örnek araba-sarkaç. Yerçekimi ön yükü ve açı yok.
- **Semenov ve ark. 2015**, Structural Nonlinear Dynamics and Diagnosis: asılma noktasında boşluklu ters sarkaç (dik denge, yani sıfır ön yük). Açı taraması yok.
- **Ghaffari, Mohammadiasl 2013**, TMECH: zaten okunmuştu.
- **Digital balancing of systems with backlash 2002**: zaten indirilmiş ve okunmuştu.
- **Hu, Yang, Xu ve ark. 2017**, ITEC Asia-Pacific: iki kütleli sistemde boşluk limit cycle'ı, çift Luenberger gözlemcisi, tam kapalı çevrim. Wang 2017 TIE ile aynı grup; yerçekimi yok.
- **Gravity compensation for leachate grid cleaning robots 2026**: hidrolik manipülatörde yerçekimi kaynaklı elastik deformasyon için statik ileri besleme; boşluk limit cycle'ı yok.
- **Torsional spring-loaded antibacklash gear 2013**: ön yüklü anti-boşluk dişlisinin dinamik iletim hatası; mekanik ön yük var, yerçekimi yok.
- **Compensation of backlash for geared drive systems and thrust wires 2015**: girişte büyük robotlarda yerçekiminin dişli ihtiyacını artırdığı söyleniyor ama boşluk-yerçekimi etkileşimi incelenmiyor.

## İleriye atıf taraması (WoS "Times Cited")

- **Sun ve ark. 2023 TIE** (en yakın çalışma, `10.1109/TIE.2022.3156154`): WoS'ta **56 atıf**, hepsinin başlığı tarandı. Çoğu çift motor senkronizasyonu, PMSM ve kayan kipli kontrol üzerine. Özeti okunan 5 aday:
  - Backlash Elimination Control for Robotic Joints with Dual-Motor Drive (2024): akıma göre değişen yapay ön yük torku; yerçekimi yok.
  - A Robotic Manipulator Using Dual-Motor Joints: D-Arm, 7 serbestlik dereceli (2023/24): çift motorlu eklemle anti-boşluk; yerçekiminin doğal ön yükü incelenmiyor.
  - Backstepping Control Collaborative Shaft Torque Observer for Limit Cycle Oscillation Suppression (2024): DF ile limit cycle analizi ve mil torku gözlemcisi; yerçekimi ve açı yok.
  - Naval gun follow-up system, adaptive backlash compensation (2026): top yükseliş ekseni (yerçekimi fiziksel olarak var) ama özette limit cycle ve açı bağımlılığı yok; RBF ile ters ölü bölge.
  - Backlash size identification for servomechanisms (2024): yalnızca aktüatör tarafından boşluk genişliği tanılama; yerçekimi yok.
- **Wang ve ark. 2024 Nonlinear Dynamics**: WoS'ta 10 atıf. 18 Ekim'de OpenAlex'te 11 atıf taranmıştı ve ilgili sonuç çıkmamıştı.

## İndirilen tam metinler (`wos/pdf/`, gitignore)

| Dosya | Kaynak | Tam metinde yerçekimi |
|---|---|---|
| `2024_10365568_Backstepping_shaft_torque_observer_limit_cycle_TPEL.pdf` | IEEE TPEL, 10.1109/TPEL.2023.3344485 | Yok (DF ile LC analizi, tam kapalı çevrim) |
| `2024_10298640_D-Arm_dual_motor_joints_anti_backlash_RAL.pdf` | IEEE RA-L, 10.1109/LRA.2023.3327867 | Yalnız bilinmeyen bozucu \(T_d\) içinde toplanmış; "seri robot yerçekimine duyarlı" cümlesi var, analiz yok |
| `2017_8080972_Hu_Yang_Xu_two_mass_backlash_limit_cycle_dual_Luenberger_ITEC.pdf` | IEEE ITEC Asia-Pacific 2017 | Yok |
| `2024_Actuators_backlash_elimination_dual_motor_robotic_joints_MDPI.pdf` | Actuators (MDPI, açık erişim), 10.3390/act13080291 | Yok |
| `2026_naval_gun_follow-up_adaptive_backlash_compensation_ShipsOffshore.pdf` | Ships and Offshore Structures (T&F), 10.1080/17445302.2026.2716857 | \(g\) yalnızca dalga denkleminde geçiyor; topun dengesizlik torku modellenmemiş |

İndirilemeyenler:
- Semenov ve ark. 2015: Springer kitap bölümü, okulun Springer aboneliği yalnızca dergileri kapsıyor.
- Backlash size identification 2024: Elsevier Precision Engineering, ScienceDirect'te kampüs dışından yalnızca "Purchase PDF" seçeneği var.
- Azar ve Serrano 2016: IGI Global, okulun aboneliğinde yok.

Erişim notu: IEEE ve T&F oturumları düşmüştü. İkisinde de "Institutional Sign In → İstinye" adımı şifre sormadan geçti, çünkü OİS oturumu açıktı. T&F'de PDF'yi `fetch` ile almak 403 verdi; "Download PDF" bağlantısı yeni sekmede açılınca indirme oradan yapıldı.

## Sonuç

WoS taraması 18 Ekim OpenAlex taramasının sonucunu doğruluyor: **boşluk + yerçekimi + describing function = 0 kayıt**, kaymalı/çift girişli DF + boşluk = 0 kayıt. Açıya bağlı yerçekimi ön yükünün boşluk limit cycle'ını nasıl şekillendirdiğini inceleyen bir çalışma bulunmadı; aradığımız boşluk hâlâ açık.

İzlenmeye değer iki ek kaynak:
- Azar & Serrano 2016 (PI + DF + araba-sarkaç): DF uygulaması için örnek.
- Naval gun 2026: yerçekimli bir eksende boşluk telafisi; ilgili çalışmalar bölümünde "yerçekimi var ama etkisi analiz edilmiyor" örneği olarak anılabilir.
