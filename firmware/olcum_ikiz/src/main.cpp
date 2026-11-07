// Adım 6 ön ölçümü: kart içi ikizin (kol_benzetim.m'deki f() + RK4) süresi ve
// float hassasiyeti. Üç sürüm:
//   DBL_MUT : double, mutlak durum {phi, dphi, th, dth}           (referans)
//   FLT_MUT : float,  mutlak durum                                  (saf çeviri)
//   FLT_FRK : float,  hedefe göre fark {phi-thr, dphi, th-thr, dth}; sin(th) açılımla
// Her kontrol örneği (1 ms) = 10 RK4 alt adımı = 40 f() değerlendirmesi.
// Test döngüsü: motor tarafı PD + yerçekimi ileri beslemesi (kaotik olmasın diye kol
// hedefi 170°: yerçekimi kolu bir yüze yaslar), 1–4 s arası kola sinüs bozucu.
// Bozucu her f() içinde sin ile hesaplanır (gerçek ikizdeki en kötü durum).
// Sonuç metin olarak 921600 baud'da basılır (oku.py).
#include <Arduino.h>
#include <math.h>
#include <xtensa/core-macros.h>

static constexpr int N_MS = 8000;      // 8 s
static constexpr int ALT = 10;         // ms başına RK4 alt adımı
static constexpr double DT = 1e-4;

// Düzenek D (secenek_duzenek('D')), kol tarafı.
struct ParD {
  double JM = 3.6e-3, JL, bM = 2e-3, bL = 1e-4, Ks = 10, cs = 0.02,
         r = 1.5 * M_PI / 180, Fc, Fs, vs = 0.05, veps = 2e-3, mgl;
  double thr = 170 * M_PI / 180, Kp = 2.0, Kd = 0.17, Tmax = 0.49;
  double dA = 0.03, df = 2.0, dT0 = 1.0, dT = 4.0;
  ParD(bool sur) {
    double mRod = 0.020, L = 0.15, mTip = (JM - mRod * L * L / 3) / (L * L);
    JL = mRod * L * L / 3 + mTip * L * L;
    mgl = 9.81 * (mRod * L / 2 + mTip * L);
    Fc = sur ? 0.04 : 0;  Fs = sur ? 0.06 : 0;
  }
};

template <typename T>
struct Par {
  T iJM, iJL, bM, bL, Ks, cs, r, Fc, dF, ivs, iveps, mgl, s0, c0, w, dA, dT0, dT;
  explicit Par(const ParD& d)
      : iJM(1 / d.JM), iJL(1 / d.JL), bM(d.bM), bL(d.bL), Ks(d.Ks), cs(d.cs), r(d.r),
        Fc(d.Fc), dF(d.Fs - d.Fc), ivs(1 / d.vs), iveps(1 / d.veps), mgl(d.mgl),
        s0(sin(d.thr)), c0(cos(d.thr)), w(2 * M_PI * d.df), dA(d.dA), dT0(d.dT0), dT(d.dT) {}
};

// FRK = true: x[0], x[2] hedefe göre fark; sin(th) = s0 cos(e) + c0 sin(e).
template <typename T, bool FRK>
static inline void IRAM_ATTR f(const Par<T>& p, const T* x, T ua, T t, T* dx) {
  T d = x[0] - x[2], dd = x[1] - x[3], ts = 0;
  if (d > p.r)       { ts = p.Ks * (d - p.r) + p.cs * dd; if (ts < 0) ts = 0; }
  else if (d < -p.r) { ts = p.Ks * (d + p.r) + p.cs * dd; if (ts > 0) ts = 0; }
  T tf = 0;
  if (p.Fc > 0) {
    T a = x[1] * p.ivs;
    tf = (p.Fc + p.dF * std::exp(-a * a)) * std::tanh(x[1] * p.iveps);
  }
  T sth = FRK ? p.s0 * std::cos(x[2]) + p.c0 * std::sin(x[2]) : std::sin(x[2]);
  T bz = (t >= p.dT0 && t < p.dT) ? p.dA * std::sin(p.w * (t - p.dT0)) : T(0);
  dx[0] = x[1];
  dx[1] = (ua - p.bM * x[1] - tf - ts) * p.iJM;
  dx[2] = x[3];
  dx[3] = (ts - p.bL * x[3] - p.mgl * sth + bz) * p.iJL;
}

template <typename T, bool FRK>
static void IRAM_ATTR rk4ms(const Par<T>& p, T* x, T ua, T t0) {
  const T h = T(DT), h2 = T(DT / 2), h6 = T(DT / 6);
  T k1[4], k2[4], k3[4], k4[4], y[4];
  for (int s = 0; s < ALT; ++s) {
    T t = t0 + T(s * DT);
    f<T, FRK>(p, x, ua, t, k1);
    for (int j = 0; j < 4; ++j) y[j] = x[j] + h2 * k1[j];
    f<T, FRK>(p, y, ua, t + h2, k2);
    for (int j = 0; j < 4; ++j) y[j] = x[j] + h2 * k2[j];
    f<T, FRK>(p, y, ua, t + h2, k3);
    for (int j = 0; j < 4; ++j) y[j] = x[j] + h * k3[j];
    f<T, FRK>(p, y, ua, t + h, k4);
    for (int j = 0; j < 4; ++j) x[j] += h6 * (k1[j] + 2 * k2[j] + 2 * k3[j] + k4[j]);
  }
}

// Referans yörüngesi (double), hedefe göre fark olarak float'ta saklanır: 64 kB.
static float* refTh = nullptr;
static float* refDl = nullptr;
static uint32_t* sure = nullptr;   // ms başına çevrim

struct Sonuc { double ort, p99, enUzun, ilk, dThMax, dDlMax, dThSon, dDlSon; };

static int kucukten(const void* a, const void* b) {
  uint32_t x = *(const uint32_t*)a, y = *(const uint32_t*)b;
  return x < y ? -1 : x > y;
}

template <typename T, bool FRK>
static Sonuc kos(const ParD& pd, bool referans) {
  Par<T> p(pd);
  T x[4];
  double th0 = pd.thr - 5 * M_PI / 180;
  if (FRK) { x[0] = T(th0 - pd.thr); x[2] = x[0]; }
  else     { x[0] = T(th0); x[2] = x[0]; }
  x[1] = 0; x[3] = 0;
  const T ff = T(pd.mgl * sin(pd.thr)), Kp = T(pd.Kp), Kd = T(pd.Kd), Tm = T(pd.Tmax);
  const T thr = T(pd.thr);
  Sonuc s{};
  for (int k = 0; k < N_MS; ++k) {
    T e = FRK ? -x[0] : thr - x[0];               // motor tarafı konum hatası
    T u = ff + Kp * e - Kd * x[1];
    if (u > Tm) u = Tm; else if (u < -Tm) u = -Tm;
    uint32_t c0 = XTHAL_GET_CCOUNT();
    rk4ms<T, FRK>(p, x, u, T(k * 1e-3));
    sure[k] = XTHAL_GET_CCOUNT() - c0;
    // fark olarak double'da: mutlak sürümde th - thr (float'ın kendi hatası dahil)
    double eth = FRK ? double(x[2]) : double(x[2]) - pd.thr;
    double dl = double(x[0]) - double(x[2]);
    if (referans) { refTh[k] = float(eth); refDl[k] = float(dl); }
    else {
      double a = fabs(eth - refTh[k]), b = fabs(dl - refDl[k]);
      if (a > s.dThMax) s.dThMax = a;
      if (b > s.dDlMax) s.dDlMax = b;
      if (k == N_MS - 1) { s.dThSon = a; s.dDlSon = b; }
    }
  }
  s.ilk = sure[0] / 240.0;
  double top = 0;
  for (int k = 0; k < N_MS; ++k) top += sure[k];
  s.ort = top / N_MS / 240.0;
  qsort(sure, N_MS, sizeof(uint32_t), kucukten);
  s.p99 = sure[(int)(0.99 * N_MS)] / 240.0;
  s.enUzun = sure[N_MS - 1] / 240.0;
  return s;
}

// Tek tek matematik fonksiyonları (1000 çağrı, çağrı başına µs).
static volatile float vf = 0.37f;
static volatile double vd = 0.37;
#define TEK(ad, ifade)                                         \
  {                                                            \
    uint32_t c = XTHAL_GET_CCOUNT();                           \
    for (int i = 0; i < 1000; ++i) { ifade; }                  \
    uint32_t g = XTHAL_GET_CCOUNT() - c;                       \
    Serial.printf("  %-8s %7.3f us\n", ad, g / 240.0 / 1000.0); \
  }

static void yaz(const char* ad, const Sonuc& s, bool fark) {
  Serial.printf("  %-8s adim ort %7.1f  p99 %7.1f  en uzun %7.1f  ilk %7.1f us", ad, s.ort,
                s.p99, s.enUzun, s.ilk);
  if (fark)
    Serial.printf("  | max|dTh| %.3e  max|dDl| %.3e  son|dTh| %.3e  son|dDl| %.3e rad", s.dThMax,
                  s.dDlMax, s.dThSon, s.dDlSon);
  Serial.printf("\n");
}

void setup() {
  Serial.begin(921600);
  delay(1500);
  Serial.printf("\n=== ikiz olcum basla (cekirdek %d, %u MHz) ===\n", xPortGetCoreID(),
                getCpuFrequencyMhz());
  Serial.printf("bos heap %u B, en buyuk blok %u B\n", ESP.getFreeHeap(), ESP.getMaxAllocHeap());
  refTh = (float*)malloc(N_MS * 4);
  refDl = (float*)malloc(N_MS * 4);
  sure = (uint32_t*)malloc(N_MS * 4);
  if (!refTh || !refDl || !sure) { Serial.println("malloc HATA"); return; }

  Serial.println("tek fonksiyon (cagri basina):");
  TEK("expf", vf = expf(vf) * 0.5f);
  TEK("tanhf", vf = tanhf(vf) + 0.1f);
  TEK("sinf", vf = sinf(vf) + 0.1f);
  TEK("cosf", vf = cosf(vf));
  TEK("fmul+add", vf = vf * 0.999f + 0.001f);
  TEK("fdiv", vf = 1.0f / (vf + 1.5f));
  TEK("exp", vd = exp(vd) * 0.5);
  TEK("tanh", vd = tanh(vd) + 0.1);
  TEK("sin", vd = sin(vd) + 0.1);
  TEK("dmul+add", vd = vd * 0.999 + 0.001);
  TEK("ddiv", vd = 1.0 / (vd + 1.5));

  for (int sur = 1; sur >= 0; --sur) {
    ParD pd(sur);
    Serial.printf("%s (Fc %.2f, Fs %.2f), thr 170 deg, 8000 ms, ms basina 10 RK4 alt adimi:\n",
                  sur ? "surtunmeli" : "surtunmesiz", pd.Fc, pd.Fs);
    Sonuc r = kos<double, false>(pd, true);
    yaz("DBL_MUT", r, false);
    Sonuc a = kos<float, false>(pd, false);
    yaz("FLT_MUT", a, true);
    Sonuc b = kos<float, true>(pd, false);
    yaz("FLT_FRK", b, true);
    Sonuc c = kos<double, true>(pd, false);
    yaz("DBL_FRK", c, true);
  }
  Serial.println("=== ikiz olcum bitti ===");
}

void loop() { delay(1000); }
