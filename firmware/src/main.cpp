// Adım 2: seri ikili paket protokolü, yankı modu.
// Kart gelen paketleri doğrular (başlık, uzunluk, CRC, sıra no), YANKI
// paketlerini aynen geri gönderir ve hata sayaçlarını tutar. MATLAB tarafı:
// simulasyon/6_esp32/. Protokol tanımı: protokol.h.
//
// Not: Bu modda kart açılışta hiçbir metin basmaz; seri hat yalnız ikili
// paketler içindir (açılıştaki ROM çıktısı 115200 baud, PC tarafı atar).
#include <Arduino.h>
#include "protokol.h"

#ifndef LED_BUILTIN
#define LED_BUILTIN 2
#endif

static constexpr uint32_t BAUD_ACILIS = 921600;

static prot::Ayristirici ayr;
static prot::Istat ist;
static uint8_t cikis[prot::EK_YUK + prot::YUK_MAKS];
static uint16_t bekSira = 0;
static bool ilkPaket = true;

static void gonder(uint8_t tip, uint16_t sira, const void* yuk, uint8_t n) {
  size_t m = prot::paketle(cikis, tip, sira, (const uint8_t*)yuk, n);
  Serial.write(cikis, m);
}

static void paketIsle(uint32_t t0) {
  const uint8_t tip = ayr.tip();
  const uint16_t sira = ayr.sira();

  // Sıra denetimi: her paket bir öncekinin +1'i olmalı (16 bitte sarar).
  if (!ilkPaket && sira != bekSira) ist.siraAtlama++;
  ilkPaket = false;
  bekSira = (uint16_t)(sira + 1);

  switch (tip) {
    case prot::T_YANKI:
      gonder(tip | 0x80, sira, ayr.yuk(), ayr.uzunluk());
      break;
    case prot::T_ISTAT:
      ist.baud = Serial.baudRate();
      ist.calismaMs = millis();
      gonder(tip | 0x80, sira, &ist, sizeof(ist));
      break;
    case prot::T_ISTAT_SIFIR: {
      uint32_t b = ist.baud;
      memset(&ist, 0, sizeof(ist));
      ist.baud = b;
      ilkPaket = true;
      gonder(tip | 0x80, sira, nullptr, 0);
      break;
    }
    case prot::T_BAUD: {
      if (ayr.uzunluk() != 4) { gonder(prot::T_HATA, sira, &tip, 1); break; }
      uint32_t yeni;
      memcpy(&yeni, ayr.yuk(), 4);
      gonder(tip | 0x80, sira, &yeni, 4);  // onay eski hızda
      Serial.flush();                      // son bayt hatta çıkana kadar bekle
      delay(20);                           // PC tarafının portu ayarlamasına süre
      Serial.updateBaudRate(yeni);
      ilkPaket = true;
      return;  // işlem süresine flush/delay sayılmasın
    }
    default:
      gonder(prot::T_HATA, sira, &tip, 1);
      break;
  }
  uint32_t dt = micros() - t0;
  if (dt > ist.islemMaksUs) ist.islemMaksUs = dt;
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.setRxBufferSize(4096);
  Serial.begin(BAUD_ACILIS);
  ist.baud = BAUD_ACILIS;
}

void loop() {
  // Gelen baytları toplu oku (bayt bayt Serial.read() her çağrıda sürücü
  // kilidi alır, ~10 µs/bayt), ayrıştırıcıya ver; paket bitince hemen cevapla.
  static uint8_t giris[256];
  int n = Serial.available();
  while (n > 0) {
    size_t m = Serial.read(giris, n > (int)sizeof(giris) ? sizeof(giris) : (size_t)n);
    if (m == 0) break;
    n -= (int)m;
    for (size_t i = 0; i < m; ++i)
      if (ayr.besle(giris[i], ist)) paketIsle(micros());
  }
  // Canlılık: LED her 1024 iyi pakette bir durum değiştirir.
  digitalWrite(LED_BUILTIN, (ist.paketOk >> 10) & 1);
}
