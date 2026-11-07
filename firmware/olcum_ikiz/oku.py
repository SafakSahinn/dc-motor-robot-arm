# Kartı yeniden başlatıp ölçüm çıktısını "bitti" satırına kadar okur, ekrana ve log'a yazar.
# Kullanım: python oku.py COM4 [log_dosyası]
import sys, time, serial

port = sys.argv[1] if len(sys.argv) > 1 else "COM4"
log = sys.argv[2] if len(sys.argv) > 2 else "olcum_log.txt"
s = serial.Serial(port, 921600, timeout=0.5)
s.dtr = False; s.rts = True; time.sleep(0.1); s.rts = False   # EN ile yeniden başlat
satirlar, bas, t0 = [], False, time.time()
while time.time() - t0 < 90:
    l = s.readline().decode("utf-8", "replace").rstrip()
    if not l:
        continue
    if "basla" in l:
        bas = True; satirlar = []
    if bas:
        print(l, flush=True); satirlar.append(l)
    if "bitti" in l:
        break
s.close()
open(log, "w", encoding="utf-8").write("\n".join(satirlar) + "\n")
