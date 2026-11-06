// Seri ikili paket protokolü (ESP32 <-> MATLAB).
//
// Paket yapısı (tüm çok baytlı alanlar little-endian):
//   [0xA5][0x5A][tip:1][sira:2][uzunluk:1][yuk:uzunluk][crc:2]
//   crc = CRC16-CCITT-FALSE (poli 0x1021, başlangıç 0xFFFF), tip..yük üzerinden.
//   Başlık + tip + sıra + uzunluk = 6 bayt, crc = 2 bayt → ek yük 8 bayt.
//
// Yazılım benzetmesi: TCP'nin çok küçük bir kardeşi. Başlık baytları "paket
// burada başlıyor" işareti (çerçeveleme), sıra numarası kayıp/çift paketi,
// CRC ise bozulmuş baytı yakalar. Bağlantı/yeniden gönderim yok: PIL adım
// kilitli olduğu için MATLAB cevabı bekler, gelmezse zaman aşımı sayar.
#pragma once
#include <stdint.h>
#include <stddef.h>

namespace prot {

constexpr uint8_t BAS0 = 0xA5;
constexpr uint8_t BAS1 = 0x5A;
constexpr uint8_t YUK_MAKS = 240;
constexpr size_t EK_YUK = 8;

// Paket tipleri. Kartın cevabı = istek tipi | 0x80.
enum Tip : uint8_t {
  T_YANKI      = 0x01,  // yükü olduğu gibi geri gönder
  T_ISTAT      = 0x02,  // sayaçları gönder (yük: Istat yapısı)
  T_ISTAT_SIFIR= 0x03,  // sayaçları sıfırla
  T_BAUD       = 0x04,  // yük: uint32 baud; önce eski hızda onay, sonra geçiş
  // 1 kHz döngü kaydı (adım 3)
  T_DONGU_BASLAT = 0x10,  // yük: uint32 ornekSayisi, uint32 yukIter → cevap: Durum
  T_DONGU_DURUM  = 0x11,  // cevap: Durum
  T_KAYIT_OKU    = 0x12,  // yük: uint32 bas, uint32 adet → art arda Kayit paketleri
  // Kontrol algoritması (adım 4–5, kontrol.h)
  T_KTL_BASLAT   = 0x20,  // yük: kontrol::Ayar (180 B) → cevap: kontrol::Turetilen (24 B)
  T_KTL_ADIM     = 0x21,  // yük: n × kontrol::Girdi (10 B, n <= 12) → cevap: n × kontrol::Cikti (20 B)
  T_HATA       = 0x7F,  // kart → PC: bilinmeyen tip vb.
};

// 1 kHz döngünün bir turunun kaydı (8 bayt). Zamanlar CPU çevrimi (240 MHz).
struct __attribute__((packed)) Kayit {
  uint32_t periyotCyc;  // bu uyanış - önceki uyanış
  uint16_t gecikmeCyc;  // zamanlayıcı kesmesi → görev uyanışı (65535'te doyar)
  uint16_t isCyc4;      // kontrol adımının süresi / 4 (65535 = 1,09 ms'de doyar)
};
constexpr uint8_t KAYIT_PAKET = YUK_MAKS / sizeof(Kayit);  // 30

// Döngü durumu (T_DONGU_* cevabı, 40 bayt).
struct __attribute__((packed)) Durum {
  uint32_t durum;       // 0 boşta, 1 kayıt sürüyor, 2 kayıt bitti
  uint32_t kayitN;      // yazılan kayıt
  uint32_t hedefN;      // istenen kayıt
  uint32_t tick;        // açılıştan beri tur sayısı
  uint32_t kacan;       // kaçırılan zamanlayıcı kesmesi (görev yetişemedi)
  uint32_t yukIter;     // sahte kontrol yükü (float döngü tekrarı)
  uint32_t perMinCyc;   // kayıt boyunca en kısa / en uzun periyot
  uint32_t perMaxCyc;
  uint32_t gecMaxCyc;   // en uzun uyanma gecikmesi
  uint32_t isMaxCyc;    // en uzun kontrol adımı
};

// Kart tarafı sayaçlar (T_ISTAT cevabının yükü, 32 bayt).
struct __attribute__((packed)) Istat {
  uint32_t paketOk;      // CRC'si doğru paketler
  uint32_t crcHata;      // CRC tutmayan paketler
  uint32_t siraAtlama;   // beklenen sıra no gelmedi (kayıp ya da çift)
  uint32_t copBayt;      // başlık aranırken atılan baytlar (senkron kaybı)
  uint32_t uzunHata;     // uzunluk > YUK_MAKS
  uint32_t baud;         // şu anki baud
  uint32_t islemMaksUs;  // paket tamamlandı → cevap yazıldı, en uzun süre
  uint32_t calismaMs;    // millis()
};

uint16_t crc16(const uint8_t* v, size_t n, uint16_t crc = 0xFFFF);

// Bayt bayt beslenen ayrıştırıcı (durum makinesi).
class Ayristirici {
 public:
  // Bir bayt ver; tam ve CRC'si doğru paket oluştuysa true döner.
  bool besle(uint8_t b, Istat& ist);
  uint8_t tip() const { return tip_; }
  uint16_t sira() const { return sira_; }
  uint8_t uzunluk() const { return uzun_; }
  const uint8_t* yuk() const { return tampon_ + 4; }

 private:
  enum Durum { D_BAS0, D_BAS1, D_GOVDE, D_CRC };
  Durum d_ = D_BAS0;
  uint8_t tampon_[4 + YUK_MAKS];  // tip, siraL, siraH, uzunluk, yük
  size_t n_ = 0;      // tampona yazılan bayt
  size_t hedef_ = 4;  // gövdenin toplam boyu (4 + uzunluk)
  uint8_t crcB_[2];
  uint8_t crcN_ = 0;
  uint8_t tip_ = 0, uzun_ = 0;
  uint16_t sira_ = 0;
};

// Paketi çerçeveleyip çıkış tamponuna yazar, toplam bayt sayısını döner.
size_t paketle(uint8_t* cikis, uint8_t tip, uint16_t sira,
               const uint8_t* yuk, uint8_t uzunluk);

}  // namespace prot
