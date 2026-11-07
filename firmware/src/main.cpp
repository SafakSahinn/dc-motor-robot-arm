// Adım 2–4: seri ikili paket protokolü + 1 kHz kontrol görevi + kontrol algoritması.
//
// Görev yerleşimi (ESP32'nin iki çekirdeği):
//   Çekirdek 1: kontrol görevi, en yüksek öncelik. Donanım zamanlayıcısı her
//               1 ms'de kesme üretir, kesme görevi uyandırır (bildirim). Görev
//               sahte bir kontrol adımı koşar ve zamanlamayı kayıt tamponuna
//               yazar. yukIter = 0 ile kayıt başlatılırsa sahte yük yerine
//               gerçek algoritma (kontrol.cpp) sentetik girdiyle koşar: hesap
//               süresi 1 kHz bağlamında ölçülür (son T_KTL_BASLAT ayarıyla).
//   Çekirdek 0: haberleşme görevi. Seri port (ve UART kesmesi) burada; MATLAB
//               ile paket alışverişi kontrol döngüsünü rahatsız etmez.
// Yazılım benzetmesi: kontrol görevi bir cron işi değil, bir alarm saatinin
// uyandırdığı tek iş parçacığı; haberleşme görevi ayrı bir sunucu iş parçacığı.
// İkisi arasında paylaşılan tek şey kayıt tamponu ve birkaç sayaç.
//
// Protokol tanımı: protokol.h. MATLAB tarafı: simulasyon/6_esp32/.
// PIL / açık döngü eşdeğerlik testi (T_KTL_*): ayrı bir Kontrolcu örneği çekirdek
// 0'da, MATLAB'ın gönderdiği sensör örnekleriyle adım adım koşar (gerçek zamansız).
// Bu modda kart açılışta metin basmaz; seri hat yalnız ikili paketler içindir.
// Adım 6, kart içi ikiz (T_IKIZ_*): 1 kHz görev her kesmede ikizin ölçümünü üretir, kontrolcü
// adımını koşar, u'yu ikize uygular (10 RK4 alt adımı). MATLAB yalnız kurar, başlatır, kaydı okur.
#include <Arduino.h>
#include <esp_heap_caps.h>
#include <driver/uart.h>
#include <xtensa/core-macros.h>
#include "protokol.h"
#include "kontrol.h"
#include "ikiz.h"

#ifndef LED_BUILTIN
#define LED_BUILTIN 2
#endif

static constexpr uint32_t BAUD_ACILIS = 921600;
static constexpr uint32_t PERIYOT_US = 1000;     // 1 kHz
static constexpr uint32_t KAYIT_MAKS = 10000;    // 10 s, 80 kB
static constexpr uint32_t IKIZ_MAKS = 8000;      // 8 s; 4 ayrı dizi (32+32+32+8 kB): boş heap'in en
                                                 // büyük bloğu ~110 kB, tek parça 104 kB sınırda kalırdı

// ---------------------------------------------------------------- paylaşılan
static prot::Kayit* kayitlar = nullptr;
// İkiz kaydı (yapı dizisi değil, alan başına dizi: her biri küçük blok)
static float* ikTh = nullptr;      // th - thRef [rad], 1 ms sonunda
static float* ikDl = nullptr;      // phi - th [rad]
static float* ikU = nullptr;       // u [N m]
static uint8_t* ikSY = nullptr;    // bit 0: s^ > 0, bit 1..3: ykF
static volatile uint32_t isrCyc = 0;   // son kesmenin çevrim sayacı (çekirdek 1)
static TaskHandle_t kontrolGorevi = nullptr;

// Kontrol görevi yazar, haberleşme görevi okur. Kayıt sürerken yalnız durum
// alanları okunur; kayıt dizisi ancak durum == 2 iken gönderilir.
static volatile uint32_t dDurum = 0, dKayitN = 0, dHedefN = 0, dTick = 0,
                         dKacan = 0, dYukIter = 300;
static volatile uint32_t dPerMin = 0, dPerMax = 0, dGecMax = 0, dIsMax = 0;
static volatile bool baslatIstegi = false;
static volatile uint32_t istenenN = 0, istenenIter = 0;
static volatile bool istenenIkiz = false;
static volatile bool sonKayitIkiz = false;   // bitmiş kayıt ikiz kaydı mı (T_IKIZ_OKU için)

// Son T_KTL_BASLAT ayarı (haberleşme görevi yazar; kontrol görevi yalnız kayıt
// başlatılırken, baslatIstegi el sıkışmasıyla okur).
static kontrol::Ayar sonAyar;
static volatile bool ayarVar = false;
static kontrol::Kontrolcu rtKtl;    // çekirdek 1: 1 kHz görevde süre ölçümü
// baslat() double eşik hesapları yüzünden ~1 ms sürer: haberleşme görevi rtHazir'ı
// önceden kurar, kontrol görevi kayıt başında yalnız kopyalar (birkaç yüz bayt).
static kontrol::Kontrolcu rtHazir;
static kontrol::Kontrolcu pilKtl;   // çekirdek 0: PIL / eşdeğerlik testi
// İkiz: haberleşme görevi kurar (double işler), kontrol görevi kayıt başında kopyalar.
static ikiz::Ikiz ikizHazir, rtIkiz;

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
  bool gercek = false;   // bu kayıtta gerçek algoritma mı (sentetik girdi)
  bool ikizKip = false;  // bu kayıtta kart içi ikiz mi
  uint32_t rtK = 0;
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
      ikizKip = istenenIkiz;
      gercek = !ikizKip && dYukIter == 0 && ayarVar;
      if (gercek || ikizKip) { rtKtl = rtHazir; rtK = 0; }
      if (ikizKip) rtIkiz = ikizHazir;
      sonKayitIkiz = ikizKip;
      dDurum = 1;
      baslatIstegi = false;
    }

    // --- kontrol adımı ---
    kontrol::Cikti ikC;
    if (ikizKip) {
      // ikiz ölçer → kontrolcü → u ikize (kol_benzetim.m kontrol örneği + 10 alt adım)
      const kontrol::Girdi g = rtIkiz.olc();
      ikC = rtKtl.adim(g);
      rtIkiz.ilerle(ikC.u);
    } else if (gercek) {
      // Sentetik girdi: motor ±64 sayım üçgen dalga (≈ ±0,19° kol tarafı, 2 s
      // periyot), küçük tork ölçümü. Amaç yalnız hesap süresi; sonuç kullanılmaz.
      uint32_t f = rtK % 2000;
      int32_t ofs = f < 1000 ? (int32_t)(f / 8) - 64 : 61 - (int32_t)((f - 1000) / 8);
      kontrol::Girdi g;
      g.ham = (uint16_t)(((sonAyar.ilkSayim + ofs) % 4096 + 4096) % 4096);
      g.v = 0.0f; g.torkOlc = 0.01f;
      volatile float u = rtKtl.adim(g).u; (void)u;
      ++rtK;
    } else {
      sahteAdim(dYukIter);
    }
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
      if (ikizKip) {
        ikTh[k] = rtIkiz.eTh(); ikDl[k] = rtIkiz.dl(); ikU[k] = ikC.u;
        ikSY[k] = (uint8_t)((ikC.sh > 0 ? 1 : 0) | ((ikC.ykF & 7) << 1));
      }
      dKayitN = k + 1;
      if (dKayitN >= dHedefN) {
        dDurum = 2;
        if (ikizKip) { ikizKip = false; dYukIter = 0; }   // ikiz durur; görev boşta (sahte yük 0)
      }
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
    case prot::T_KTL_BASLAT: {
      if (ayr.uzunluk() != sizeof(kontrol::Ayar) || dDurum == 1) { gonder(prot::T_HATA, sira, &tip, 1); break; }
      memcpy(&sonAyar, ayr.yuk(), sizeof(sonAyar));
      ayarVar = true;
      pilKtl.baslat(sonAyar);
      rtHazir = pilKtl;   // dDurum != 1: kontrol görevi şu an rtHazir'ı okumuyor
      gonder(tip | 0x80, sira, &pilKtl.turetilen(), sizeof(kontrol::Turetilen));
      break;
    }
    case prot::T_IKIZ_BASLAT: {
      // yük: uint32 N + ikiz::Ayar. Kontrolcü ayarı (T_KTL_BASLAT) önceden gelmiş olmalı.
      static ikiz::Ayar ia;
      uint32_t nIs;
      bool ok = ayr.uzunluk() == 4 + sizeof(ikiz::Ayar) && dDurum != 1 && ayarVar && ikTh;
      if (ok) {
        memcpy(&nIs, ayr.yuk(), 4);
        memcpy(&ia, ayr.yuk() + 4, sizeof(ia));
        ok = (ia.tOlc != 0) == (sonAyar.torkOlcum != 0) && ikizHazir.baslat(ia);
      }
      if (!ok) { gonder(prot::T_HATA, sira, &tip, 1); break; }
      // rtHazir: son T_KTL_BASLAT'ın taze kopyası (görev onu yalnız kopyalar, değiştirmez)
      istenenN = nIs > IKIZ_MAKS ? IKIZ_MAKS : (nIs ? nIs : 1);
      istenenIter = 0;
      istenenIkiz = true;
      baslatIstegi = true;
      while (baslatIstegi) vTaskDelay(1);
      istenenIkiz = false;
      durumGonder(tip | 0x80, sira);
      break;
    }
    case prot::T_IKIZ_OKU: {
      uint32_t v[2];
      if (ayr.uzunluk() != 8 || dDurum != 2 || !sonKayitIkiz) { gonder(prot::T_HATA, sira, &tip, 1); break; }
      memcpy(v, ayr.yuk(), 8);
      uint32_t bas = v[0], son = v[0] + v[1];
      if (son > dKayitN) son = dKayitN;
      static ikiz::Kayit pk[prot::IKIZ_PAKET];
      uint16_t parca = 0;
      for (uint32_t i = bas; i < son; i += prot::IKIZ_PAKET) {
        uint32_t m = son - i < prot::IKIZ_PAKET ? son - i : prot::IKIZ_PAKET;
        for (uint32_t j = 0; j < m; ++j) {
          pk[j].eTh = ikTh[i + j]; pk[j].dl = ikDl[i + j]; pk[j].u = ikU[i + j]; pk[j].shYk = ikSY[i + j];
        }
        gonder(tip | 0x80, parca++, pk, (uint8_t)(m * sizeof(ikiz::Kayit)));
      }
      return;
    }
    case prot::T_KTL_ADIM: {
      // n örnek arka arkaya (açık döngü eşdeğerlik testinde n = 12, PIL'de n = 1).
      constexpr uint8_t GB = sizeof(kontrol::Girdi), CB = sizeof(kontrol::Cikti);
      const uint8_t L = ayr.uzunluk();
      if (!ayarVar || L == 0 || L % GB != 0 || L / GB > prot::YUK_MAKS / CB) {
        gonder(prot::T_HATA, sira, &tip, 1); break;
      }
      static kontrol::Cikti cik[prot::YUK_MAKS / CB];
      const uint8_t n = L / GB;
      for (uint8_t j = 0; j < n; ++j) {
        kontrol::Girdi g;
        memcpy(&g, ayr.yuk() + j * GB, GB);
        uint32_t c0 = XTHAL_GET_CCOUNT();
        cik[j] = pilKtl.adim(g);
        uint32_t dc = XTHAL_GET_CCOUNT() - c0;
        cik[j].cyc = dc > 65535 ? 65535 : (uint16_t)dc;
      }
      gonder(tip | 0x80, sira, cik, (uint8_t)(n * CB));
      break;
    }
    default:
      gonder(prot::T_HATA, sira, &tip, 1);
      break;
  }
  uint32_t dt = micros() - t0;
  if (dt > ist.islemMaksUs) ist.islemMaksUs = dt;
}

// Yanıtın tamamı hatta çıktı mı? Adım 6'da yanıtın sonu ara sıra kartın TX tamponunda kalıyordu
// ("TX boşaldı" kesmesi kapalı kalıyor; kart bir sonraki yanıtı yazana dek çıkmıyordu, PC'den
// gelen bayt açmıyordu). Her paket işlendikten sonra sınırlı bekle; boşalmadıysa kesmeyi aç.
// 200 ms: 4 kB halka tampon 921600 baud'da ~45 ms'de boşalır.
static void txBitir() {
  if (uart_wait_tx_done(UART_NUM_0, pdMS_TO_TICKS(200)) == ESP_OK) return;
  ist.txDurtme++;
  uart_enable_tx_intr(UART_NUM_0, 1, 10);
  uart_wait_tx_done(UART_NUM_0, pdMS_TO_TICKS(200));
}

static void haberlesmeGorevFn(void*) {
  // Serial.begin burada: UART kesmesi de çekirdek 0'a kurulur.
  Serial.setRxBufferSize(4096);
  // TX halka tamponu: varsayılan 0'da yazan görev her 128 B'lık FIFO dolumunu kesmeyle bekliyor
  // ve toplu okumada (T_KAYIT_OKU / T_IKIZ_OKU) ara sıra yanıtın son 384 B'ı (3 FIFO) PC'den
  // yeni bir bayt gelene dek kartta takılı kalıyordu (adım 6, esp32.md). Halka tamponla yazım
  // ISR'nin boşalttığı tampona kopyalanır.
  Serial.setTxBufferSize(4096);
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
      if (ayr.besle(giris[i], ist)) { paketIsle(micros()); txBitir(); }
    // Canlılık: LED her 1024 iyi pakette bir durum değiştirir.
    digitalWrite(LED_BUILTIN, (ist.paketOk >> 10) & 1);
  }
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  kayitlar = (prot::Kayit*)heap_caps_malloc(KAYIT_MAKS * sizeof(prot::Kayit),
                                            MALLOC_CAP_8BIT | MALLOC_CAP_INTERNAL);
  ikTh = (float*)heap_caps_malloc(IKIZ_MAKS * 4, MALLOC_CAP_8BIT | MALLOC_CAP_INTERNAL);
  ikDl = (float*)heap_caps_malloc(IKIZ_MAKS * 4, MALLOC_CAP_8BIT | MALLOC_CAP_INTERNAL);
  ikU = (float*)heap_caps_malloc(IKIZ_MAKS * 4, MALLOC_CAP_8BIT | MALLOC_CAP_INTERNAL);
  ikSY = (uint8_t*)heap_caps_malloc(IKIZ_MAKS, MALLOC_CAP_8BIT | MALLOC_CAP_INTERNAL);
  if (!ikDl || !ikU || !ikSY) ikTh = nullptr;   // biri yoksa ikiz modu kapalı (T_IKIZ_BASLAT reddeder)
  xTaskCreatePinnedToCore(kontrolGorevFn, "kontrol", 4096, nullptr,
                          configMAX_PRIORITIES - 1, &kontrolGorevi, 1);
  xTaskCreatePinnedToCore(haberlesmeGorevFn, "haberlesme", 8192, nullptr,
                          5, nullptr, 0);
}

void loop() {
  // Arduino'nun loop görevi (çekirdek 1) iş yapmaz; kontrol görevine yer açar.
  vTaskDelete(nullptr);
}
