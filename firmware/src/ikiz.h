// Adım 6: kart içi gerçek zamanlı ikiz (simulasyon/kol_benzetim.m'deki tesis + ölçüm modelleri).
//
// Kapsam: iki kütle + dişli boşluğu (r, K_s, c_s) + yumuşatılmış Stribeck + yerçekimi + kola
// sinüs bozucu (f), sabit adımlı RK4 (dt = 1e-4, kontrol örneği başına `alt` alt adım), akım
// döngüsü (ua birinci derece izler, her alt adımda), motor AS5600 modeli (gecikme halkası alt adım
// çözünürlüğünde, gürültü, floor nicemleme), INA228 modeli (uygulanan torkun pencere ortalaması,
// tPen / tGec, gürültü). Sıra kol_benzetim.m ile birebir:
//   her alt adım: phi'yi gecikme halkasına it → (kontrol örneğiyse) ölç → [kontrolcü] → ua
//   güncelle → tBuf'a it → RK4
//
// Kullanım (1 kHz görevde, bir kontrol örneği):
//   Girdi g = ikiz.olc();  Cikti c = ktl.adim(g);  ikiz.ilerle(c.u);
// olc() alt adım 0'ın ölçüm kısmı, ilerle() alt adım 0'ın kalanı + 1..alt-1.
//
// Sayısal kurallar (firmware/olcum_ikiz ölçümü, esp32.md Adım 6):
//  * float. double yalnız baslat()'ta. ESP32'de double yazılımla: 2,1 ms/ms, bütçe dışı.
//  * Açılar HEDEFE GÖRE FARK: x = {phi - thRef, dphi, th - thRef, dth}. Mutlak açı (≈ 3,14 rad)
//    float'ta 2,4e-7 rad adımla tutulur, RK4 artışları ~1e-7 rad: mutlak durum 8 s'de 2e-3 rad
//    sapıyordu, fark durumu 9e-7 rad. sin(th) = s0 cos(eth) + c0 sin(eth), s0/c0 double'dan.
//  * Bölme yok: 1/JM, 1/JL, 1/vs, 1/veps, 1/qM baslat()'ta.
//  * Bozucunun açık/kapalı sınırları (tt >= dT0, tt < dT) baslat()'ta MATLAB'ın double
//    karşılaştırmasıyla alt adım indisine çevrilir (RK4'ün üç zaman noktası için ayrı ayrı).
//  * Gürültü kartın kendi RNG'si (xorshift32 + Box–Muller): MATLAB'ın randn dizisiyle AYNI DEĞİL,
//    yalnız istatistiksel olarak eşdeğer. Birebir karşılaştırma gürültüsüz (nM = 0, tGur = 0).
#pragma once
#include <stdint.h>
#include "kontrol.h"

namespace ikiz {

constexpr int HALKA_MAKS = 64;   // gecikme / INA228 halkalarının en büyük boyu (alt adım)

// Ayarlar = T_IKIZ_BASLAT yükünün (uint32 örnek sayısından sonraki) kısmı, 180 B, packed.
// MATLAB karşılığı: simulasyon/6_esp32/ikiz_ayar_paketle.m (alan sırası birebir).
struct __attribute__((packed)) Ayar {
  // --- double: yalnız başlatmada ---
  double thRef;      // hedef [rad] (kontrolcünün thRef'iyle aynı)
  double dt;         // RK4 adımı [s]
  double qM;         // motor sayımının kol tarafı açısı [rad]
  double phi0, dphi0, th0, dth0;   // başlangıç durumu (mutlak, kol_benzetim x(:,1))
  double dT0, dT;    // bozucu penceresi [s] (dT: Inf olabilir)
  double akimW;      // akım döngüsü bandı [rad/s] (Inf: tork = komut)
  // --- tamsayı ---
  int32_t alt;       // kontrol örneği başına alt adım (round(Ts/dt))
  int32_t gMs;       // motor ölçüm gecikmesi [alt adım] (round(gM/dt))
  int32_t tG, tP;    // INA228: gecikme ve pencere [alt adım]
  uint32_t tohumM, tohumT;   // enkoder ve tork gürültüsü RNG tohumları (0 olmaz)
  uint8_t tOlc;      // 1: INA228 modeli (kontrolcü torkOlcum = 1 olmalı)
  uint8_t rez[3];
  // --- float ---
  float JM, JL, bM, bL, Ks, cs, r;   // kol tarafı
  float Fc, Fs, vs, veps;            // Stribeck (Fc = 0: sürtünme yok)
  float mgl;
  float dA, df;                      // bozucu genliği [N m], frekansı [Hz]
  float nM;                          // enkoder gürültüsü RMS [rad, kol tarafı]
  float tGur, tOfs, tKaz;            // INA228 gürültü RMS, ofset [N m], kazanç
};
static_assert(sizeof(Ayar) == 180, "ikiz::Ayar boyu");

// T_IKIZ_OKU'nun bir örneği (13 B): 1 ms sonundaki durum + o örneğin kontrol çıktısı.
struct __attribute__((packed)) Kayit {
  float eTh;         // th - thRef [rad]
  float dl;          // phi - th [rad]
  float u;           // kontrolcünün tork komutu [N m]
  uint8_t shYk;      // bit 0: s^ > 0, bit 1..3: ykF
};
static_assert(sizeof(Kayit) == 13, "ikiz::Kayit boyu");

class Ikiz {
 public:
  // false: ayar geçersiz (halka boyu, alt adım sayısı vb.)
  bool baslat(const Ayar& a);
  kontrol::Girdi olc();          // kontrol örneğinin ölçümü (alt adım 0, RK4'ten önce)
  void ilerle(float u);          // u'yu tut, `alt` RK4 alt adımı ilerle
  float eTh() const { return x_[2]; }
  float dl() const { return x_[0] - x_[2]; }
  int32_t sayim() const { return sayim_; }

 private:
  struct Par {
    float iJM, iJL, bM, bL, Ks, cs, r, Fc, dF, ivs, iveps, mgl, s0, c0;
    float dA, w;
  };
  void f(const float* x, float ua, float bz, float* dx) const;
  float bozucu(int32_t i, int c) const;    // c: 0 tt, 1 tt + dt/2, 2 tt + dt
  float gauss(uint32_t& s, bool& varY, float& yedek);

  Par p_;
  float h_, h2_, h6_;
  float x_[4];
  float ua_, u_, aAk_;
  bool akimVar_;
  int32_t alt_, i_;              // i_: alt adım indisi (MATLAB i)
  // bozucu: [c] = RK4 zaman noktası; açık iken bas_[c] <= i < son_[c]
  int32_t bas_[3], son_[3];
  // tt - dT0 = (i - bzI0_) dt + c dt/2 + bzArt_ (float'ta büyük tt'den küçük farkı çıkarmamak için)
  float bzArt_;
  int32_t bzI0_;
  bool bzVar_;
  // motor ölçümü
  int32_t refC_;
  float refF_, iqM_, nM_;
  int32_t sayim_;
  float phHalka_[HALKA_MAKS];
  int32_t phN_, phI_;
  uint32_t rngM_, rngT_;
  bool yM_, yT_;
  float yedekM_, yedekT_;
  // INA228
  bool tOlc_;
  float tHalka_[HALKA_MAKS];
  int32_t tN_, tI_, tP_;
  float tGur_, tOfs_, tKaz_;
};

}  // namespace ikiz
