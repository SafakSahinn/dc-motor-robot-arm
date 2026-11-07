// Adım 6: kart içi ikiz (ikiz.h'deki açıklamaya bak). Blok yorumları kol_benzetim.m'deki
// karşılığı gösterir.
#include "ikiz.h"
#include <math.h>
#include <string.h>

namespace ikiz {

namespace {

constexpr int32_t ASLA = 0x7FFFFFFF;

// MATLAB: tt_c(i) = i*dt + ek (ek = 0, 0.5*dt, dt), tt_c(i) >= esik olan en küçük i >= 0.
int32_t zamanEsigi(double dt, double ek, double esik) {
  if (!(esik < INFINITY)) return ASLA;
  double n0 = floor((esik - ek) / dt) - 2.0;
  int32_t i = n0 > 0.0 ? (int32_t)n0 : 0;
  for (;; ++i) {
    const double tt = (double)i * dt;
    const double t = ek == 0.0 ? tt : tt + ek;
    if (t >= esik) return i;
  }
}

inline uint32_t xorshift(uint32_t& s) {
  s ^= s << 13; s ^= s >> 17; s ^= s << 5;
  return s;
}

}  // namespace

bool Ikiz::baslat(const Ayar& a) {
  if (!(a.dt > 0.0) || !(a.qM > 0.0) || a.alt < 1 || a.alt > 1000) return false;
  if (a.gMs < 0 || a.gMs + 1 > HALKA_MAKS) return false;
  if (a.tOlc && (a.tP < 1 || a.tG < 0 || a.tG + a.tP > HALKA_MAKS)) return false;

  // --- tesis sabitleri (f, kol_benzetim.m 370–386)
  p_.iJM = (float)(1.0 / (double)a.JM);
  p_.iJL = (float)(1.0 / (double)a.JL);
  p_.bM = a.bM; p_.bL = a.bL; p_.Ks = a.Ks; p_.cs = a.cs; p_.r = a.r;
  p_.Fc = a.Fc; p_.dF = a.Fs - a.Fc;
  p_.ivs = (float)(1.0 / (double)a.vs);
  p_.iveps = (float)(1.0 / (double)a.veps);
  p_.mgl = a.mgl;
  p_.s0 = (float)sin(a.thRef);
  p_.c0 = (float)cos(a.thRef);
  p_.dA = a.dA;
  p_.w = (float)(2.0 * M_PI * (double)a.df);
  h_ = (float)a.dt; h2_ = (float)(0.5 * a.dt); h6_ = (float)(a.dt / 6.0);

  // --- bozucu penceresi (106): üç RK4 zaman noktası için ayrı indis sınırları
  bzVar_ = a.dA != 0.0f;
  const double ek[3] = {0.0, 0.5 * a.dt, a.dt};
  for (int c = 0; c < 3; ++c) {
    bas_[c] = zamanEsigi(a.dt, ek[c], a.dT0);
    son_[c] = zamanEsigi(a.dt, ek[c], a.dT);
  }
  bzI0_ = (int32_t)llround(a.dT0 / a.dt);
  bzArt_ = (float)((double)bzI0_ * a.dt - a.dT0);

  // --- başlangıç (159–163): fark durumu
  x_[0] = (float)(a.phi0 - a.thRef);
  x_[1] = (float)a.dphi0;
  x_[2] = (float)(a.th0 - a.thRef);
  x_[3] = (float)a.dth0;
  u_ = ua_ = 0.0f;
  const double aAk = 1.0 - exp(-a.akimW * a.dt);   // (173) akımW = Inf -> 1
  akimVar_ = aAk != 1.0;
  aAk_ = (float)aAk;
  alt_ = a.alt;
  i_ = 0;

  // --- motor ölçümü (165–171): gecikme halkası x(1)'le dolu
  const double rc = floor(a.thRef / a.qM);
  refC_ = (int32_t)rc;
  refF_ = (float)(a.thRef - rc * a.qM);
  iqM_ = (float)(1.0 / a.qM);
  nM_ = a.nM;
  phN_ = a.gMs + 1;
  phI_ = 0;
  for (int32_t j = 0; j < phN_; ++j) phHalka_[j] = x_[0];
  sayim_ = refC_ + (int32_t)floorf((refF_ + x_[0]) * iqM_);
  rngM_ = a.tohumM ? a.tohumM : 1u;
  rngT_ = a.tohumT ? a.tohumT : 1u;
  yM_ = yT_ = false;
  yedekM_ = yedekT_ = 0.0f;

  // --- INA228 (174–180): tBuf = repmat(u = 0, tG + tP, 1)
  tOlc_ = a.tOlc != 0;
  tP_ = a.tP > 0 ? a.tP : 1;
  tN_ = tOlc_ ? a.tG + a.tP : 1;
  tI_ = 0;
  for (int32_t j = 0; j < HALKA_MAKS; ++j) tHalka_[j] = 0.0f;
  tGur_ = a.tGur; tOfs_ = a.tOfs; tKaz_ = a.tKaz;
  return true;
}

float Ikiz::gauss(uint32_t& s, bool& varY, float& yedek) {
  // Box–Muller: iki düzgün sayıdan iki bağımsız N(0,1); ikincisi sonraki çağrıya saklanır.
  if (varY) { varY = false; return yedek; }
  const float u1 = (float)((xorshift(s) >> 8) + 1u) * (1.0f / 16777216.0f);   // (0, 1]
  const float u2 = (float)(xorshift(s) >> 8) * (1.0f / 16777216.0f);          // [0, 1)
  const float r = sqrtf(-2.0f * logf(u1));
  const float a = 6.2831853f * u2;
  yedek = r * sinf(a); varY = true;
  return r * cosf(a);
}

KONTROL_HIZLI float Ikiz::bozucu(int32_t i, int c) const {
  if (!bzVar_ || i < bas_[c] || i >= son_[c]) return 0.0f;
  const float t = (float)(i - bzI0_) * h_ + (float)c * h2_ + bzArt_;
  return p_.dA * sinf(p_.w * t);
}

// f(x, tt) (370–386), x fark durumu.
KONTROL_HIZLI void Ikiz::f(const float* x, float ua, float bz, float* dx) const {
  const float d = x[0] - x[2], dd = x[1] - x[3];
  float ts = 0.0f;
  if (d > p_.r)       { ts = p_.Ks * (d - p_.r) + p_.cs * dd; if (ts < 0.0f) ts = 0.0f; }
  else if (d < -p_.r) { ts = p_.Ks * (d + p_.r) + p_.cs * dd; if (ts > 0.0f) ts = 0.0f; }
  float tf = 0.0f;
  if (p_.Fc > 0.0f) {
    const float a = x[1] * p_.ivs;
    tf = (p_.Fc + p_.dF * expf(-a * a)) * tanhf(x[1] * p_.iveps);
  }
  const float sth = p_.s0 * cosf(x[2]) + p_.c0 * sinf(x[2]);
  dx[0] = x[1];
  dx[1] = (ua - p_.bM * x[1] - tf - ts) * p_.iJM;
  dx[2] = x[3];
  dx[3] = (ts - p_.bL * x[3] - p_.mgl * sth + bz) * p_.iJL;
}

// Kontrol örneğinin ölçümü (212–245): phBuf'a it, AS5600 (gecikme, gürültü, floor), INA228.
KONTROL_HIZLI kontrol::Girdi Ikiz::olc() {
  float ph;
  if (phN_ > 1) {
    phHalka_[phI_] = x_[0];
    phI_ = phI_ + 1 == phN_ ? 0 : phI_ + 1;
    ph = phHalka_[phI_];                       // en eski: gMs alt adım önceki phi
  } else {
    ph = x_[0];
  }
  if (nM_ > 0.0f) ph += nM_ * gauss(rngM_, yM_, yedekM_);
  sayim_ = refC_ + (int32_t)floorf((refF_ + ph) * iqM_);

  kontrol::Girdi g;
  g.ham = (uint16_t)(((sayim_ % 4096) + 4096) % 4096);
  g.v = x_[1];                                 // gerçek motor hızı (yalnız HIZ_GIRDI'de)
  g.torkOlc = 0.0f;
  if (tOlc_) {                                 // bt = tBuf(end-tG-tP+1 : end-tG): en eski tP satır
    float top = 0.0f;
    int32_t j = tI_;
    for (int32_t k = 0; k < tP_; ++k) {
      top += tHalka_[j];
      j = j + 1 == tN_ ? 0 : j + 1;
    }
    g.torkOlc = tKaz_ * (top / (float)tP_) + tOfs_;
    if (tGur_ > 0.0f) g.torkOlc += tGur_ * gauss(rngT_, yT_, yedekT_);
  }
  return g;
}

// Kontrol örneğinin kalanı + sonraki alt adımlar (212, 321–326).
KONTROL_HIZLI void Ikiz::ilerle(float u) {
  u_ = u;
  float k1[4], k2[4], k3[4], k4[4], y[4];
  for (int32_t s = 0; s < alt_; ++s) {
    if (s > 0 && phN_ > 1) {
      phHalka_[phI_] = x_[0];
      phI_ = phI_ + 1 == phN_ ? 0 : phI_ + 1;
    }
    ua_ = akimVar_ ? ua_ + aAk_ * (u_ - ua_) : u_;   // akım döngüsü
    if (tOlc_) {                                     // son satır: bu adımda uygulanan tork
      tHalka_[tI_] = ua_;
      tI_ = tI_ + 1 == tN_ ? 0 : tI_ + 1;
    }
    const int32_t i = i_;
    const float b0 = bozucu(i, 0), b1 = bozucu(i, 1), b2 = bozucu(i, 2);
    f(x_, ua_, b0, k1);
    for (int j = 0; j < 4; ++j) y[j] = x_[j] + h2_ * k1[j];
    f(y, ua_, b1, k2);
    for (int j = 0; j < 4; ++j) y[j] = x_[j] + h2_ * k2[j];
    f(y, ua_, b1, k3);
    for (int j = 0; j < 4; ++j) y[j] = x_[j] + h_ * k3[j];
    f(y, ua_, b2, k4);
    for (int j = 0; j < 4; ++j) x_[j] += h6_ * (k1[j] + 2.0f * k2[j] + 2.0f * k3[j] + k4[j]);
    i_ = i + 1;
  }
}

}  // namespace ikiz
