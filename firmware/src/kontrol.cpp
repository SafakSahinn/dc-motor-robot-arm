// Adım 4: kontrol algoritması (kontrol.h'deki açıklamaya bak).
// Her bloğun başındaki yorum kol_benzetim.m'deki karşılığını gösterir; değişken adları
// MATLAB'dakilerle aynı tutuldu (sonuna _ eklenmiş üye değişkenler).
#include "kontrol.h"
#include <math.h>
#include <string.h>

namespace kontrol {

namespace {

constexpr int32_t ASLA = 0x7FFFFFFF;   // "bu eşiğe hiç ulaşılmaz" (Inf eşik)

inline float isaret(float x) { return (float)((x > 0.0f) - (x < 0.0f)); }
inline float sinirla(float x, float a) { return x > a ? a : (x < -a ? -a : x); }

// MATLAB: n*Ts >= esik (n tamsayı değerli double). En küçük n.
int32_t carpimEsigi(double Ts, double esik, bool kati) {
  if (!(esik < INFINITY)) return ASLA;
  if (esik <= 0.0) return kati ? 1 : 0;
  int32_t n = (int32_t)floor(esik / Ts);
  if (n > 2) n -= 2; else n = 0;
  for (;; ++n) {
    double t = (double)n * Ts;
    if (kati ? (t > esik) : (t >= esik)) return n;
  }
}

// MATLAB: ykT = ykT + Ts (her örnekte birikerek), ykT >= esik. En küçük birikim sayısı.
int32_t toplamEsigi(double Ts, double esik) {
  if (!(esik < INFINITY)) return ASLA;
  double t = 0.0;
  int32_t n = 0;
  while (!(t >= esik)) { t = t + Ts; ++n; }
  return n;
}

}  // namespace

void Kontrolcu::baslat(const Ayar& a) {
  a_ = a;
  memset(&t_, 0, sizeof(t_));

  // --- sabitler (kol_benzetim.m 113–142) ---
  qM_ = (float)a.qM;
  Ts_ = (float)a.Ts;
  const double wo = a.gozW;
  l1_ = (float)(3.0 * wo);
  l2_ = (float)(3.0 * wo * wo);
  l3_ = (float)((double)a.JMN * wo * wo * wo);
  tJMN_ = (float)(1.0 / (double)a.JMN);
  suzgec_ = isfinite(a.vDurF);
  aDur_ = suzgec_ ? (float)(1.0 - exp(-2.0 * M_PI * (double)a.vDurF * a.Ts)) : 1.0f;
  adm_ = a.yuzRampa > 0.0f ? (float)(2.0 * a.Ts / (double)a.yuzRampa) : 0.0f;
  ofsG_ = (float)((double)a.mglN * sin(a.thRef) / (double)a.KsN);
  yokEtkin_ = a.kesMod >= KES_YOKLAMA && fabs(a.thRef - M_PI) <= a.yokBant + 1e-12;

  // Hedef = refC sayım + refF kesir (float büyük açıda ince farkı kaybetmesin)
  const double rc = floor(a.thRef / a.qM);
  t_.refC = (int32_t)rc;
  t_.refF = (float)(a.thRef - rc * a.qM);

  // Zaman eşikleri tamsayı örnek sayısı olarak (MATLAB'ın double karşılaştırması)
  t_.nBek = carpimEsigi(a.Ts, a.yokBekle, false);   // durSay*Ts >= yokBek
  t_.nTmin = toplamEsigi(a.Ts, a.yokTmin);          // ykT >= yokTmin (birikimli)
  t_.nTmax = toplamEsigi(a.Ts, a.yokTmax);
  nOlay_ = carpimEsigi(a.Ts, a.yokTmin, true);      // tt - ykSon > yokTmin
  nPer_ = carpimEsigi(a.Ts, a.yokPer, false);       // tt - ykSon >= yokPer
  t_.yokEtkin = yokEtkin_;

  // --- durum (kol_benzetim.m 116–117, 136–142, 149, 158) ---
  sayim_ = sayimOnc_ = a.ilkSayim;
  hamOnc_ = (uint16_t)(((a.ilkSayim % 4096) + 4096) % 4096);
  dRel_ = 0.0f;                     // phi^ = olc(phi0): ilk ölçümle aynı
  wh_ = dh_ = whF_ = 0.0f;
  durSay_ = perSay_ = perIs_ = 0;
  float s0 = a.yuz0 != 0.0f ? isaret(a.yuz0) : (float)((sin(a.thRef) > 0.0) - (sin(a.thRef) < 0.0));
  if (s0 == 0.0f) s0 = 1.0f;
  sh_ = sOf_ = s0;
  t_.sh0 = (uint8_t)(int8_t)s0;
  yuzDeg_ = 0;
  ykF_ = ykT_ = ykC0_ = ykSay_ = ykTemas_ = 0;
  ykDir_ = ykDm_ = ykYon_ = 0.0f;
  ykSonVar_ = false;  ykSon_ = 0;
  z_ = uOnc_ = eOnc_ = 0.0f;
  k_ = 0;
}

KONTROL_HIZLI Cikti Kontrolcu::adim(const Girdi& g) {
  const Ayar& a = a_;
  const int mod = a.kesMod;

  // --- ölçüm: tur içi ham açıyı toplam sayıma aç (mimari.md: Δ [-2048, 2048) aralığına sarılır)
  int32_t d = (int32_t)g.ham - (int32_t)hamOnc_;
  if (d >= 2048) d -= 4096; else if (d < -2048) d += 4096;
  hamOnc_ = g.ham;
  sayim_ += d;

  bool yk = false;
  float ofs;
  if (mod != KES_KAPALI) {
    const float shOnc = sh_;

    // --- tork gözlemcisi, ESKİ u ile (207–219) ---
    // MATLAB: eo = y - ph; ph += Ts (wh + l1 eo). Burada dRel = ph - y_önceki.
    const float eo = (float)(sayim_ - sayimOnc_) * qM_ - dRel_;
    const float uo = a.torkOlcum ? g.torkOlc : uOnc_;
    dRel_ = Ts_ * (wh_ + l1_ * eo) - eo;       // yeni ph - bu ölçüm
    wh_ = wh_ + Ts_ * ((uo - a.bMN * wh_ - dh_) * tJMN_ + l2_ * eo);
    dh_ = dh_ - Ts_ * l3_ * eo;
    sayimOnc_ = sayim_;
    whF_ = suzgec_ ? whF_ + aDur_ * (wh_ - whF_) : wh_;   // (220)
    durSay_ = fabsf(whF_) < a.vDur ? durSay_ + 1 : 0;     // (221)

    // --- edilgen (222–224): durgunken sign(u)
    if (mod == KES_EDILGEN && durSay_ >= a.yuzN && uOnc_ != 0.0f) sh_ = isaret(uOnc_);

    // --- olay (225–234): sürtünme aralığını aşan dişli torku
    if (mod == KES_OLAY || mod == KES_OLAY_YOKLAMA) {
      const float sg = fabsf(wh_) > a.vEsik ? isaret(wh_) : 0.0f;
      const float a1 = dh_ - sg * a.FsN, a2 = dh_ - sg * a.FcN;
      const float dur0 = sg == 0.0f ? a.FsN : 0.0f;
      const float lo = (a1 < a2 ? a1 : a2) - dur0, hi = (a1 > a2 ? a1 : a2) + dur0;
      const int32_t ad = (int32_t)(lo > a.tauEsik) - (int32_t)(hi < -a.tauEsik);
      perSay_ = (ad != 0 && ad == perIs_) ? perSay_ + 1 : 0;
      perIs_ = ad;
      bool d2 = ad != 0 && perSay_ >= a.Nper;
      if (mod == KES_OLAY_YOKLAMA)   // yoklama torku olay sayılmaz
        d2 = d2 && ykF_ == 0 && (!ykSonVar_ || (k_ - ykSon_) >= nOlay_);
      if (d2) sh_ = (float)ad;
    }

    // --- etken yoklama (235–253): evreler 1 it, 2 fren, 3 geri, 4 fren
    if (mod >= KES_YOKLAMA) {
      const bool ykBas = ykF_ > 0;
      if (ykBas) ++ykT_;
      const float yol = ykDir_ * ((float)(sayim_ - ykC0_) * qM_);
      const float tsY = ykDir_ * dh_ - a.FcN;          // itiş yönünde dişli torku tahmini
      const bool bT = ykF_ == 1 && tsY > a.yokEsik && ykT_ >= t_.nTmin && ykDir_ * wh_ > a.vEsik;
      const bool bS = ykF_ == 1 && !bT && yol >= a.yokD;
      if (bS) ykF_ = 2;                                 // serbest yol: boşluk, frenle
      if (ykF_ == 2 && ykDir_ * wh_ <= 0.0f) { ykF_ = 3; ykDm_ = yol; }
      if (ykF_ == 3 && yol <= ykDm_ * a.yokOrta) ykF_ = 4;
      const bool bB = (ykF_ == 4 && (ykDir_ * wh_ >= 0.0f || yol <= 0.0f)) || bT ||
                      (ykBas && ykT_ >= t_.nTmax);
      if (bB) { ykF_ = 0; ykSonVar_ = true; ykSon_ = k_; }
      if (bT) { ++ykTemas_; sh_ = ykDir_; }
      const bool perTamam = !ykSonVar_ || (nPer_ != ASLA && (k_ - ykSon_) >= nPer_);
      if (yokEtkin_ && ykF_ == 0 && durSay_ >= t_.nBek && perTamam && ykSay_ < a.yokMaks) {
        ykF_ = 1; ykT_ = 0; ykC0_ = sayim_; ykDir_ = -sh_; ++ykSay_;
      }
      yk = ykF_ > 0;
      ykYon_ = ykDir_ * ((ykF_ == 2 || ykF_ == 3) ? -1.0f : 1.0f);
    }

    // --- yüz değişimi, rampa, ofset (254–261)
    if (sh_ != shOnc) {
      ++yuzDeg_;
      if (mod >= KES_YOKLAMA && ykF_ == 0) ykSonVar_ = false;   // oturunca yeniden yokla
    }
    if (a.yuzRampa > 0.0f) sOf_ = sOf_ + sinirla(sh_ - sOf_, adm_);
    else sOf_ = sh_;
    ofs = sOf_ * a.rN + ofsG_;
  } else {
    ofs = sOf_ * a.rN + ofsG_;     // kestirici kapalı: başlangıç yüzüyle sabit ofset
  }

  // --- P-PI (263–271): konum hatası motor tarafından, hız motor tarafından
  const float e = (float)(t_.refC - sayim_) * qM_ + t_.refF + ofs;
  const float v = a.hizKaynak == HIZ_GIRDI ? g.v : wh_;
  const float ev = a.kp * e - v;
  const float u0 = a.KV * ev + a.KI * z_;
  const float iz = ev;

  // --- doyum, anti-windup, integral (272–276)
  float u = sinirla(u0, a.Tmax);
  const bool doy = (u0 > a.Tmax && iz > 0.0f) || (u0 < -a.Tmax && iz < 0.0f);
  if (a.Isifirla && e * eOnc_ < 0.0f) z_ = 0.0f;
  eOnc_ = e;
  const float zOnc = z_;
  if (!doy && fabsf(e) >= a.Iolu) z_ = z_ + iz * Ts_;

  // --- yoklama sırasında kontrolcü donar (277–279)
  if (yk) { u = sinirla(a.yokA * ykYon_, a.Tmax); z_ = zOnc; }

  // --- sürücü ölü bandı (280)
  if (fabsf(u) < a.olu) u = 0.0f;
  uOnc_ = u;
  ++k_;

  Cikti c;
  c.u = u; c.wh = wh_; c.dh = dh_; c.sOf = sOf_;
  c.sh = (int8_t)sh_; c.ykF = (uint8_t)ykF_; c.cyc = 0;
  return c;
}

}  // namespace kontrol
