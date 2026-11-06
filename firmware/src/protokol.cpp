#include "protokol.h"
#include <string.h>

namespace prot {

uint16_t crc16(const uint8_t* v, size_t n, uint16_t crc) {
  // Bit bit hesap: 30 baytlık paket için ~240 döngü, 240 MHz'te ~2 µs.
  for (size_t i = 0; i < n; ++i) {
    crc ^= (uint16_t)v[i] << 8;
    for (int k = 0; k < 8; ++k)
      crc = (crc & 0x8000) ? (uint16_t)((crc << 1) ^ 0x1021) : (uint16_t)(crc << 1);
  }
  return crc;
}

bool Ayristirici::besle(uint8_t b, Istat& ist) {
  switch (d_) {
    case D_BAS0:
      if (b == BAS0) d_ = D_BAS1;
      else ist.copBayt++;
      return false;
    case D_BAS1:
      if (b == BAS1) { d_ = D_GOVDE; n_ = 0; hedef_ = 4; }
      else if (b == BAS0) { ist.copBayt++; }      // A5 A5 5A: ikinci A5 başlangıç olabilir
      else { ist.copBayt += 2; d_ = D_BAS0; }
      return false;
    case D_GOVDE:
      tampon_[n_++] = b;
      if (n_ == 4) {
        if (tampon_[3] > YUK_MAKS) { ist.uzunHata++; d_ = D_BAS0; return false; }
        hedef_ = 4 + tampon_[3];
      }
      if (n_ >= 4 && n_ == hedef_) { d_ = D_CRC; crcN_ = 0; }
      return false;
    case D_CRC:
      crcB_[crcN_++] = b;
      if (crcN_ < 2) return false;
      d_ = D_BAS0;
      {
        uint16_t gelen = (uint16_t)crcB_[0] | ((uint16_t)crcB_[1] << 8);
        if (gelen != crc16(tampon_, hedef_)) { ist.crcHata++; return false; }
      }
      tip_ = tampon_[0];
      sira_ = (uint16_t)tampon_[1] | ((uint16_t)tampon_[2] << 8);
      uzun_ = tampon_[3];
      ist.paketOk++;
      return true;
  }
  return false;
}

size_t paketle(uint8_t* c, uint8_t tip, uint16_t sira,
               const uint8_t* yuk, uint8_t uzunluk) {
  c[0] = BAS0; c[1] = BAS1;
  c[2] = tip;
  c[3] = (uint8_t)(sira & 0xFF); c[4] = (uint8_t)(sira >> 8);
  c[5] = uzunluk;
  if (uzunluk) memcpy(c + 6, yuk, uzunluk);
  uint16_t crc = crc16(c + 2, 4 + uzunluk);
  c[6 + uzunluk] = (uint8_t)(crc & 0xFF);
  c[7 + uzunluk] = (uint8_t)(crc >> 8);
  return EK_YUK + uzunluk;
}

}  // namespace prot
