# Kaynak erişim durumu (18 Ekim 2026, kampüs dışı)

Okul girişi (OİS) bir kez yapılınca oturum diğer sitelere taşınıyor; hiçbiri tekrar şifre sormadı.

| Kaynak | Durum | Nasıl girilir |
|---|---|---|
| Springer | ✅ Çalışıyor | Makale sayfası → "log in via an institution" → İstinye University |
| IEEE Xplore | ✅ Çalışıyor | Üstteki "Institutional Sign In" → "Access Through İstinye Üniversitesi" |
| Taylor & Francis | ✅ Giriş çalışıyor | Login → Shibboleth → İstinye Üniversitesi. 1973 International Journal of Control sayısı abonelik dışı ("Get Access"); yeni sayılar muhtemelen açık |
| ScienceDirect | ❌ Hata | Sign in → kurum → İstinye: "We are unable to give you access", hata ID-702 (missing attributes) |
| Scopus | ❌ Kısmi | "Sign in via your organization" → İstinye: kurum tanınıyor ama yalnızca "Scopus Preview" açılıyor |
| Web of Science | ⚠️ Dolaylı çalışıyor (22 Ekim) | Institutional Sign In → YETKİM → İstinye yine "Shibboleth error 90011" veriyor; ama bu girişten sonra WoS yeni sekmede açılınca oturum "Istinye Universitesi" yetkisiyle geliyor ve Core Collection tam aranabiliyor. Tarama: `wos/wos_tarama_2026-10-22.md` |

## Neden?
Elsevier (ScienceDirect, Scopus) ve Clarivate (WoS) okul girişini kabul ediyor ama aboneliği hesaba bağlamıyor. Okulun kimlik sistemi bu sitelere gereken bilgiyi göndermiyor. Bu okul tarafındaki bir ayar sorunu.

## Yapılacak
- [ ] Kampüsten (ya da okul VPN'iyle) ScienceDirect, Scopus ve WoS'u dene; bu siteler genelde okul IP'siyle doğrudan açılır.
- [ ] Kampüsteyken indirilecek: Nordin, Gutman 2002, Automatica, "Controlling mechanical systems with backlash—a survey", doi 10.1016/s0005-1098(02)00047-x
- [ ] Gerekirse kütüphaneye bildir: "Kampüs dışından OİS ile girişte ScienceDirect 'ID-702 missing attributes', Scopus yalnızca 'Preview', Web of Science YETKİM üzerinden 'Shibboleth error 90011' veriyor."

## İndirilenler (18 Ekim)
- `ieee_disi/pdf/2024_Wang_Nonlinear_Dynamics_backlash_NESO_manipulator.pdf` (Springer)
- `ieee/pdf/2013_Ghaffari_TMECH_clearance_preloading_oscillation.pdf`
- `ieee/pdf/2017_Wang_TIE_limit_cycle_backlash_transmission.pdf`
- `ieee/pdf/2023_TIE_limited_amplitude_DOB_backlash.pdf`
