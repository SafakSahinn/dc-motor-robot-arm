// Adım 4: kontrol algoritmasının C++ çevirisi (simulasyon/kol_benzetim.m, kontrolcü örneği).
//
// Kapsam: P-PI (Ghaffari kaskadı, motor tarafı konum + motor hızı), ofset (boşluk + dişli
// esnemesi: s_of*r + mgl sin(th_ref)/K_s), tork gözlemcisi (Luenberger, üçlü kutup), yüz
// kestirici (edilgen / olay / yoklama / olay+yoklama, rampalı ofset), doyum, anti-windup,
// sürücü ölü bandı. Sıra kol_benzetim.m ile birebir:
//   ölçüm → gözlemci (ESKİ u ile) → yüz kararı → rampa/ofset → P-PI → doyum → integral →
//   yoklama torku → ölü bant
//
// Saf C++: Arduino'ya bağlı değil (yalnız <stdint.h>, <math.h>); kartta ve gerekirse PC'de
// derlenir. Tüm büyüklükler KOL TARAFINDA SI (rad, rad/s, N m).
//
// Sayısal kurallar:
//  * Hesap float (ESP32 FPU tek hassasiyet). double yalnız baslat()'ta (bir kez).
//  * Motor açısı int32 sayımla tutulur: sayim = motor AS5600'ün toplam sayımı (tur * 4096 +
//    tur içi). Açı = sayim * qM. 180°'de sayim ≈ 61 440: float bunu tam tutar ama açıyı
//    (≈ 3,14 rad) yalnız 2,4e-7 rad adımla; gözlemcinin 1 ms'lik artışları (~1e-6 rad) bu
//    adıma yakın. Bu yüzden açılar hep FARK olarak hesaplanır: hedef = refC sayım + refF
//    kesir, gözlemci phi^ yerine (phi^ - son ölçüm) küçük farkını taşır.
//  * Zaman eşikleri (yokBekle, yokTmin, yokTmax, yokPer) baslat()'ta tamsayı örnek
//    sayısına çevrilir; çeviri MATLAB'ın double karşılaştırmasını aynen yapar, böylece
//    eşik "500. örnekte mi 501.'de mi" sorusu iki tarafta aynı cevaplanır.
#pragma once
#include <stdint.h>

// Kartta adim() IRAM'de koşar: flash önbelleği ıskası ilk turda ve ilk yoklamada adımı
// 4 µs'den 300 µs'ye çıkarıyordu (ktl_esdeger). PC derlemesinde boş.
#if defined(ESP_PLATFORM)
#include <esp_attr.h>
#define KONTROL_HIZLI IRAM_ATTR
#else
#define KONTROL_HIZLI
#endif

namespace kontrol {

enum KesMod : uint8_t { KES_KAPALI = 0, KES_EDILGEN = 1, KES_OLAY = 2, KES_YOKLAMA = 3, KES_OLAY_YOKLAMA = 4 };
enum HizKaynak : uint8_t {
  HIZ_GIRDI = 0,     // Girdi.v kullanılır (ikizdeki p.fv = Inf: gerçek motor hızı; PIL eşdeğerliği için)
  HIZ_GOZLEMCI = 1,  // gözlemcinin w^'si (donanımda seçilen yöntem, mimari.md)
};

// Ayarlar = aynı zamanda T_KTL_BASLAT paketinin yükü (180 B, little-endian, packed).
// MATLAB karşılığı: simulasyon/6_esp32/ktl_ayar_paketle.m (alan sırası birebir).
struct __attribute__((packed)) Ayar {
  // --- double: yalnız başlatmada (hedef, eşik çevirisi) ---
  double thRef;      // hedef açı [rad] (0 = dik aşağı), ofset dahil değil
  double Ts;         // kontrol periyodu [s]
  double qM;         // motor sayımının kol tarafındaki açısı [rad] = 2 pi / (4096 N)
  double yokTmin;    // [s] yoklamada temas kararının en erken anı (MATLAB varsayılanı 3/gozW)
  double yokTmax;    // [s] yoklamanın en uzun süresi
  double yokBekle;   // [s] yoklama başlamadan önce motorun durgun kalma süresi
  double yokPer;     // [s] periyodik yoklama aralığı (Inf: yok)
  double yokBant;    // [rad] yoklama yalnız |thRef - pi| <= yokBant ise etkin
  // --- tamsayı ---
  int32_t ilkSayim;  // başlangıç motor sayımı (floor(phi0/qM)); tur sayacı buradan kurulur
  int32_t Nper;      // olay kararının sürmesi gereken örnek sayısı
  int32_t yuzN;      // edilgen: durgunluk örnek sayısı
  int32_t yokMaks;   // en çok yoklama sayısı
  uint8_t kesMod;    // KesMod
  uint8_t hizKaynak; // HizKaynak
  uint8_t torkOlcum; // 1: gözlemci Girdi.torkOlc'u görür (INA228), 0: son komut u'yu
  uint8_t Isifirla;  // 1: konum hatası işaret değiştirince integral sıfırlanır
  // --- float ---
  float kp, KV, KI;          // P-PI: wcmd = kp e, u = KV (wcmd - v) + KI z
  float Tmax, olu, Iolu;     // doyum [N m], sürücü ölü bandı [N m], integral ölü bandı [rad]
  float rN, mglN, KsN;       // ofsetin bildiği boşluk yarı genişliği, mgl, K_s
  float yuzRampa, yuz0;      // ofset yüz rampası [s] (0: basamak); başlangıç yüzü (0: sign(sin thRef))
  float gozW, JMN, bMN, FcN, FsN;   // gözlemci kutbu [rad/s], bildiği J_M, b_M, F_c, F_s
  float tauEsik, vEsik, vDur;       // olay eşiği [N m], hareket eşiği, durgunluk eşiği [rad/s]
  float yokA, yokD, yokEsik, yokOrta, vDurF;  // yoklama itişi [N m], serbest yol [rad], temas eşiği [N m],
                                              // geri dönüş fren noktası, durgunluk süzgeci [Hz] (Inf: yok)
};
static_assert(sizeof(Ayar) == 180, "Ayar paket boyu");

// Bir kontrol örneğinin girdisi (T_KTL_ADIM'da 10 B).
struct __attribute__((packed)) Girdi {
  uint16_t ham;      // motor AS5600 ham açısı 0..4095 (tur içi)
  float v;           // motor hızı [rad/s, kol tarafı] (yalnız HIZ_GIRDI'de)
  float torkOlc;     // ölçülen tork k_t i [N m, kol tarafı] (yalnız torkOlcum'da)
};
static_assert(sizeof(Girdi) == 10, "Girdi boyu");

// Bir kontrol örneğinin çıktısı (T_KTL_ADIM'da 20 B; cyc kartta doldurulur).
struct __attribute__((packed)) Cikti {
  float u;           // motor tork komutu [N m] (doyum + ölü bant sonrası)
  float wh, dh;      // gözlemci: motor hızı [rad/s], dişli + sürtünme torku [N m]
  float sOf;         // ofsetteki (rampalı) yüz, -1..+1
  int8_t sh;         // kestiricinin yüzü s^ (+1 / -1)
  uint8_t ykF;       // yoklama evresi (0 yok, 1 it, 2 fren, 3 geri, 4 fren)
  uint16_t cyc;      // adim() süresi [CPU çevrimi, 240 MHz] (65535'te doyar)
};
static_assert(sizeof(Cikti) == 20, "Cikti boyu");

// baslat()'ın türettiği tamsayılar (tanı için T_KTL_BASLAT cevabında döner, 24 B).
struct __attribute__((packed)) Turetilen {
  int32_t refC;      // hedefin sayım kısmı
  float refF;        // hedefin kesir kısmı [rad]
  int32_t nBek, nTmin, nTmax;   // yokBekle, yokTmin, yokTmax örnek sayısı olarak
  uint8_t yokEtkin, sh0, rez0, rez1;
};
static_assert(sizeof(Turetilen) == 24, "Turetilen boyu");

class Kontrolcu {
 public:
  void baslat(const Ayar& a);
  Cikti adim(const Girdi& g);
  const Turetilen& turetilen() const { return t_; }
  int32_t sayim() const { return sayim_; }
  int32_t yokSay() const { return ykSay_; }
  int32_t yokTemas() const { return ykTemas_; }
  int32_t yuzDegis() const { return yuzDeg_; }

 private:
  Ayar a_;
  Turetilen t_;
  // türetilen sabitler (float)
  float qM_, Ts_, l1_, l2_, l3_, aDur_, adm_, ofsG_, tJMN_;   // tJMN_ = 1/JMN (FPU bölme yapmaz)
  bool suzgec_, yokEtkin_;
  int32_t nOlay_, nPer_;   // tt - ykSon > yokTmin, tt - ykSon >= yokPer (örnek sayısı)
  // ölçüm
  int32_t sayim_, sayimOnc_;
  uint16_t hamOnc_;
  // gözlemci: dRel_ = phi^ - (önceki ölçüm)
  float dRel_, wh_, dh_, whF_;
  int32_t durSay_, perSay_, perIs_;
  // yüz
  float sh_, sOf_;
  int32_t yuzDeg_;
  // yoklama
  int32_t ykF_, ykT_, ykC0_, ykSay_, ykTemas_;
  float ykDir_, ykDm_, ykYon_;
  bool ykSonVar_;    // false: ykSon = -Inf
  int32_t ykSon_;    // son yoklama bitişinin örnek indisi
  // kontrolcü
  float z_, uOnc_, eOnc_;
  int32_t k_;        // örnek indisi (tt = k * Ts)
};

}  // namespace kontrol
