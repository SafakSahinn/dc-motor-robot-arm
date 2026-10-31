"""B2 (açı yönünde sınır hatası) ayrışması, D düzeneği. Veri: yercekimli_kritik_D.csv
(açı, benzetim kritik r_gs, yerçekimli DF kritik r_gs, tork sınırsız DF).
Soru: 15°'lik açı hatası bağımsız bir hata mı, yoksa kazanç hatasının sınır eğrisinin
açıya göre yatık olmasıyla büyümesi mi? Kullanım: python aci_hatasi.py > aci_hatasi_log.txt"""
import csv
import math
import statistics as st

R = list(csv.reader(open("yercekimli_kritik_D.csv")))
f = lambda x: float("nan") if x == "NaN" else float(x)
ac = [f(r[0]) for r in R]
ks = [f(r[1]) for r in R]
kd = [f(r[2]) for r in R]
rgs = [round(0.30 + 0.05 * i, 2) for i in range(21)]


def bolge(k, r):
    """r kazancında salınımsız açıların en büyük bitişik parçası (yercekimli_karsilastirma.m ile aynı)."""
    v = [(math.isnan(x) and 0 < a < 180) or ((not math.isnan(x)) and x > r + 1e-9) for a, x in zip(ac, k)]
    en, i = None, 0
    while i < len(v):
        if v[i]:
            j = i
            while j + 1 < len(v) and v[j + 1]:
                j += 1
            if en is None or j - i > en[1] - en[0]:
                en = (i, j)
            i = j + 1
        else:
            i += 1
    return (ac[en[0]], ac[en[1]]) if en else (None, None)


def b2(kdf, ksim, etiket):
    e = []
    for r in rgs:
        l1, u1 = bolge(ksim, r)
        l2, u2 = bolge(kdf, r)
        if l1 is not None and l2 is not None:
            e += [abs(l1 - l2), abs(u1 - u2)]
    print(f"{etiket}: açı hatası medyan {st.median(e):.1f}°, en çok {max(e):.0f}° ({len(e)} sınır)")


# benzetimin yüksek kazançtaki düzensiz bölgesinden gelen dört aykırı nokta komşulardan ara değerle
ks2 = ks[:]
for a in (40, 45, 140, 145):
    ks2[ac.index(a)] = None
for i, x in enumerate(ks2):
    if x is None:
        lo = max(j for j in range(i) if ks2[j] is not None)
        hi = min(j for j in range(i + 1, len(ks2)) if ks2[j] is not None)
        ks2[i] = ks2[lo] + (ks2[hi] - ks2[lo]) * (i - lo) / (hi - lo)

b2(kd, ks, "Yerçekimli DF")
b2(kd, ks2, "Yerçekimli DF, aykırı 4 nokta ara değerle")

print("\nKazanç hatasının açıya yansıması: Δθ ≈ Δk / (dk/dθ)")
print(" açı   sim    DF   Δk/k  eğim (r_gs/°)  Δk/eğim (°)")
oran = []
for i in range(1, len(ac) - 1):
    if math.isnan(kd[i]):
        continue
    oran.append(ks2[i] / kd[i])
    if ac[i] > 90 or math.isnan(kd[i - 1]) or math.isnan(kd[i + 1]):
        continue
    eg = (kd[i + 1] - kd[i - 1]) / (ac[i + 1] - ac[i - 1])
    dk = ks2[i] - kd[i]
    yans = f"{dk / eg:6.1f}" if abs(eg) > 1e-4 else "     ∞"
    print(f"{ac[i]:4.0f}  {ks2[i]:.2f}  {kd[i]:.2f}  {100 * dk / ks2[i]:+4.0f}%     {eg:.4f}       {yans}")

c = st.median(oran)
print(f"\nTek sabit kazanç düzeltmesi: benzetim/DF medyanı c = {c:.2f} (aynı veriye uydurma, öngörü değil)")
b2([x * c for x in kd], ks2, f"DF × {c:.2f}, aykırı noktalar ara değerle")
b2([x * c for x in kd], ks, f"DF × {c:.2f}, ham benzetim")
