// Adım 2–3: seri ikili paket protokolü + 1 kHz kontrol görevi iskeleti.
//
// Görev yerleşimi (ESP32'nin iki çekirdeği):
//   Çekirdek 1: kontrol görevi, en yüksek öncelik. Donanım zamanlayıcısı her
//               1 ms'de kesme üretir, kesme görevi uyandırır (bildirim). Görev
//               sahte bir kontrol adımı koşar ve zamanlamayı kayıt tamponuna
//               yazar. İleride gerçek algoritma (adım 4) buraya girecek.
//   Çekirdek 0: haberleşme görevi. Seri port (ve UART kesmesi) burada; MATLAB
//               ile paket alışverişi kontrol döngüsünü rahatsız etmez.
// Yazılım benzetmesi: kontrol görevi bir cron işi değil, bir alarm saatinin
// uyandırdığı tek iş parçacığı; haberleşme görevi ayrı bir sunucu iş parçacığı.
// İkisi arasında paylaşılan tek şey kayıt tamponu ve birkaç sayaç.
//
// Protokol tanımı: protokol.h. MATLAB tarafı: simulasyon/6_esp32/.
// Bu modda kart açılışta metin basmaz; seri hat yalnız ikili paketler içindir.
#include <Arduino.h>
#include <esp_heap_caps.h>
#include <xtensa/core-macros.h>
#include "protokol.h"

#ifndef LED_BUILTIN
#define LED_BUILTIN 2
#endif

static constexpr uint32_t BAUD_ACILIS = 921600;
static constexpr uint32_t PERIYOT_US = 1000;     // 1 kHz
static constexpr uint32_t KAYIT_MAKS = 10000;    // 10 s, 80 kB

// ---------------------------------------------------------------- paylaşılan
static prot::Kayit* kayitlar = nullptr;
static volatile uint32_t isrCyc = 0;   // son kesmenin çevrim sayacı (çekirdek 1)
static TaskHandle_t kontrolGorevi = nullptr;

// Kontrol görevi yazar, haberleşme görevi okur. Kayıt sürerken yalnız durum
// alanları okunur; kayıt dizisi ancak durum == 2 iken gönderilir.
static volatile uint32_t dDurum = 0, dKayitN = 0, dHedefN = 0, dTick = 0,
                         dKacan = 0, dYukIter = 300;
static volatile uint32_t dPerMin = 0, dPerMax = 0, dGecMax = 0, dIsMax = 0;
static volatile bool baslatIstegi = false;
static volatile uint32_t istenenN = 0, istenenIter = 0;

// ---------------------------------------------------------------- çekirdek 1
static void IRAM_ATTR zamanlayiciKesmesi() {
  isrCyc = XTHAL_GET_CCOUNT();
  BaseType_t uyandir = pdFALSE;
  vTaskNotifyGiveFromISR(kontrolGorevi, &uyandir);
  portYIELD_FROM_ISR(uyandir);
}

// Sahte kontrol adımı: gerçek algoritma gelene kadar yerini tutan float yükü.
// 1 tekrar ≈ 4 float işlem; 300 tekrar ≈ 20 µs (adım-1 ölçümünden).
static float sahteAdim(uint32_t iter) {
  volatile float a = 1.0001f, b = 0.9999f, s = 0.0f;
  for (uint32_t i = 0; i < iter; ++i) s = s * b + a;
  return s;
}

static void kontrolGorevFn(void*) {
  // Zamanlayıcıyı bu görevin içinde (çekirdek 1'de) kur: kesme de çekirdek 1'e
  // bağlanır, böylece kesme ve görev aynı çevrim sayacını okur.
  hw_timer_t* z = timerBegin(1000000);                 // 1 MHz sayaç
  timerAttachInterrupt(z, &zamanlayiciKesmesi);
  timerAlarm(z, PERIYOT_US, true, 0);                   // her 1000 µs, sürekli

  uint32_t oncekiCyc = 0;
  bool ilk = true;
  for (;;) {
    uint32_t n = ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
    uint32_t uyanCyc = XTHAL_GET_CCOUNT();
    uint32_t gec = uyanCyc - isrCyc;
    if (n > 1) dKacan = dKacan + (n - 1);
    dTick = dTick + 1;

    // Kayıt başlatma isteği (haberleşme görevinden): tur sınırında uygula.
    if (baslatIstegi) {
      dHedefN = istenenN; dYukIter = istenenIter;
      dKayitN = 0; dKacan = 0;
      dPerMin = 0xFFFFFFFF; dPerMax = 0; dGecMax = 0; dIsMax = 0;
      dDurum = 1;
      baslatIstegi = false;
    }

    // --- kontrol adımı (adım 4'te gerçek algoritma) ---
    sahteAdim(dYukIter);
    uint32_t isCyc = XTHAL_GET_CCOUNT() - uyanCyc;

    uint32_t per = uyanCyc - oncekiCyc;
    oncekiCyc = uyanCyc;
    if (ilk) { ilk = false; continue; }

    if (dDurum == 1) {
      uint32_t k = dKayitN;
      kayitlar[k].periyotCyc = per;
      kayitlar[k].gecikmeCyc = gec > 65535 ? 65535 : (uint16_t)gec;
      uint32_t i4 = isCyc / 4;
      kayitlar[k].isCyc4 = i4 > 65535 ? 65535 : (uint16_t)i4;
      if (per < dPerMin) dPerMin = per;
      if (per > dPerMax) dPerMax = per;
      if (gec > dGecMax) dGecMax = gec;
      if (isCyc > dIsMax) dIsMax = isCyc;
      dKayitN = k + 1;
      if (dKayitN >= dHedefN) dDurum = 2;
    }
  }
}

// ---------------------------------------------------------------- çekirdek 0
static prot::Ayristirici ayr;
static prot::Istat ist;
static uint8_t cikis[prot::EK_YUK + prot::YUK_MAKS];
static uint16_t bekSira = 0;
static bool ilkPaket = true;

static void gonder(uint8_t tip, uint16_t sira, const void* yuk, uint8_t n) {
  size_t m = prot::paketle(cikis, tip, sira, (const uint8_t*)yuk, n);
  Serial.write(cikis, m);
}

static void durumGonder(uint8_t tip, uint16_t sira) {
  prot::Durum d;
  d.durum = dDurum; d.kayitN = dKayitN; d.hedefN = dHedefN; d.tick = dTick;
  d.kacan = dKacan; d.yukIter = dYukIter; d.perMinCyc = dPerMin;
  d.perMaxCyc = dPerMax; d.gecMaxCyc = dGecMax; d.isMaxCyc = dIsMax;
  gonder(tip, sira, &d, sizeof(d));
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
    case prot::T_DONGU_BASLAT: {
      uint32_t v[2];
      if (ayr.uzunluk() != 8 || dDurum == 1) { gonder(prot::T_HATA, sira, &tip, 1); break; }
      memcpy(v, ayr.yuk(), 8);
      istenenN = v[0] > KAYIT_MAKS ? KAYIT_MAKS : (v[0] ? v[0] : 1);
      istenenIter = v[1];
      baslatIstegi = true;
      while (baslatIstegi) vTaskDelay(1);  // kontrol görevi bir sonraki turda alır
      durumGonder(tip | 0x80, sira);
      break;
    }
    case prot::T_DONGU_DURUM:
      durumGonder(tip | 0x80, sira);
      break;
    case prot::T_KAYIT_OKU: {
      // Toplu gönderim: istenen aralık art arda paketlerle, bekleme olmadan.
      // Her paketin sıra no'su = parça indisi (0, 1, 2, ...).
      uint32_t v[2];
      if (ayr.uzunluk() != 8 || dDurum != 2) { gonder(prot::T_HATA, sira, &tip, 1); break; }
      memcpy(v, ayr.yuk(), 8);
      uint32_t bas = v[0], son = v[0] + v[1];
      if (son > dKayitN) son = dKayitN;
      uint16_t parca = 0;
      for (uint32_t i = bas; i < son; i += prot::KAYIT_PAKET) {
        uint32_t m = son - i < prot::KAYIT_PAKET ? son - i : prot::KAYIT_PAKET;
        gonder(tip | 0x80, parca++, &kayitlar[i], (uint8_t)(m * sizeof(prot::Kayit)));
      }
      return;
    }
    default:
      gonder(prot::T_HATA, sira, &tip, 1);
      break;
  }
  uint32_t dt = micros() - t0;
  if (dt > ist.islemMaksUs) ist.islemMaksUs = dt;
}

static void haberlesmeGorevFn(void*) {
  // Serial.begin burada: UART kesmesi de çekirdek 0'a kurulur.
  Serial.setRxBufferSize(4096);
  Serial.setTimeout(100);   // readBytes en fazla 100 ms bekler
  Serial.begin(BAUD_ACILIS);
  ist.baud = BAUD_ACILIS;

  static uint8_t giris[256];
  for (;;) {
    // İlk baytı engelleyerek bekle (görev uyur, çekirdek 0 boşta kalır; UART
    // kesmesi bayt gelince uyandırır), ardından kuyruktakileri toplu oku.
    size_t m = Serial.readBytes(giris, 1);
    int n = Serial.available();
    if (n > 0) {
      size_t ek = Serial.read(giris + m, n > (int)sizeof(giris) - 1 ? sizeof(giris) - 1 : (size_t)n);
      m += ek;
    }
    for (size_t i = 0; i < m; ++i)
      if (ayr.besle(giris[i], ist)) paketIsle(micros());
    // Canlılık: LED her 1024 iyi pakette bir durum değiştirir.
    digitalWrite(LED_BUILTIN, (ist.paketOk >> 10) & 1);
  }
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  kayitlar = (prot::Kayit*)heap_caps_malloc(KAYIT_MAKS * sizeof(prot::Kayit),
                                            MALLOC_CAP_8BIT | MALLOC_CAP_INTERNAL);
  xTaskCreatePinnedToCore(kontrolGorevFn, "kontrol", 4096, nullptr,
                          configMAX_PRIORITIES - 1, &kontrolGorevi, 1);
  xTaskCreatePinnedToCore(haberlesmeGorevFn, "haberlesme", 8192, nullptr,
                          5, nullptr, 0);
}

void loop() {
  // Arduino'nun loop görevi (çekirdek 1) iş yapmaz; kontrol görevine yer açar.
  vTaskDelete(nullptr);
}
