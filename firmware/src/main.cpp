// Adım 1: ilk yükleme sınaması.
// Kartın yaşadığını gösterir: LED yanıp söner, seri porttan çip bilgisi ve
// float hız ölçümü (FPU gerçekten çalışıyor mu) yazılır.
#include <Arduino.h>

#ifndef LED_BUILTIN
#define LED_BUILTIN 2   // çoğu ESP32 geliştirme kartında mavi LED GPIO2'de
#endif

static void floatHizOlc() {
  // 100000 float çarp-topla; FPU varsa ~1 ms civarı sürmeli
  volatile float a = 1.0001f, b = 0.9999f, s = 0.0f;
  uint32_t t0 = micros();
  for (int i = 0; i < 100000; ++i) s = s * b + a;
  uint32_t dt = micros() - t0;
  Serial.printf("float testi: 100000 islem %lu us (sonuc %.3f)\n",
                (unsigned long)dt, (double)s);
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(921600);
  delay(300);
  Serial.println();
  Serial.println("=== robot kol ESP32: adim 1 ===");
  Serial.printf("cip: %s rev %d, %d cekirdek, %lu MHz\n",
                ESP.getChipModel(), ESP.getChipRevision(),
                ESP.getChipCores(), (unsigned long)ESP.getCpuFreqMHz());
  Serial.printf("flash: %lu KB, bos heap: %lu B\n",
                (unsigned long)(ESP.getFlashChipSize() / 1024),
                (unsigned long)ESP.getFreeHeap());
  floatHizOlc();
}

void loop() {
  static uint32_t sayac = 0;
  digitalWrite(LED_BUILTIN, HIGH);
  delay(250);
  digitalWrite(LED_BUILTIN, LOW);
  delay(250);
  if (++sayac % 4 == 0) Serial.printf("canli, t=%lu s\n", (unsigned long)(millis() / 1000));
}
