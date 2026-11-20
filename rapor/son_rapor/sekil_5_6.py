# Birleşik rapor, Şekil 5.1, 5.2 ve 6.2: mevcut logları okuyup çizer (benzetimi yeniden koşturmaz,
# logları değiştirmez). Kaynak loglar simulasyon/5_planlama/ altında:
#   konum_kaynagi_karsilastir_log.txt  -> Şekil 5.1 (kol / motor tarafı konum döngüsü)
#   ofset_tablosu_log.txt              -> Şekil 5.2 (ofset tablosu öncesi / sonrası)
#   belirsiz_bant_log.txt              -> Şekil 6.2 (belirsiz bant)
# Renkler: dataviz başvuru paleti, açık tema (Bölüm 3 betiğiyle aynı).
import os, re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

KOK = os.path.dirname(os.path.abspath(__file__))
LOG = os.path.join(KOK, '..', '..', 'simulasyon', '5_planlama')
IMG = os.path.join(KOK, 'img')
S1, S2, S3 = '#2a78d6', '#eb6834', '#1baf7a'
YAZI, YAZI2, IZGARA = '#0b0b0b', '#52514e', '#e4e3df'
plt.rcParams.update({'font.family': 'Arial', 'font.size': 8.5, 'axes.edgecolor': YAZI2,
                     'axes.labelcolor': YAZI2, 'xtick.color': YAZI2, 'ytick.color': YAZI2,
                     'axes.titlesize': 9, 'axes.titlecolor': YAZI, 'axes.spines.top': False,
                     'axes.spines.right': False, 'axes.grid': True, 'grid.color': IZGARA,
                     'grid.linewidth': 0.8, 'legend.frameon': False, 'legend.labelcolor': YAZI2,
                     'axes.formatter.use_locale': False})
CM = 1/2.54

def oku(ad):
    return open(os.path.join(LOG, ad), encoding='utf-8').read()

def blok(metin, baslik):
    """'== baslik' ile başlayan bloğu döndürür (bir sonraki '==' ya kadar)."""
    i = metin.index('== ' + baslik)
    j = metin.find('\n== ', i + 3)
    return metin[i: j if j > 0 else None]

def satir(b, rgs, etiket):
    m = re.search(r'^\s*%s %s\s*(.*)$' % (re.escape(rgs), re.escape(etiket)), b, re.M)
    return [float(v) for v in m.group(1).split()]

def virgul(ax):
    from matplotlib.ticker import FuncFormatter
    f = FuncFormatter(lambda v, _: ('%g' % v).replace('.', ','))
    ax.xaxis.set_major_formatter(f); ax.yaxis.set_major_formatter(f)

def kaydet(fig, ad):
    fig.savefig(os.path.join(IMG, ad), dpi=200, bbox_inches='tight', facecolor='white')
    plt.close(fig)

# ---------- Şekil 5.1 ----------
t = oku('konum_kaynagi_karsilastir_log.txt')
aci = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180]
kol, mot = blok(t, 'kol (ideal)'), blok(t, 'motor (ideal)')
fig, (a1, a2) = plt.subplots(1, 2, figsize=(17*CM, 6.5*CM))
a1.plot(aci, satir(kol, '0.50', 'A[°]:'), '-o', color=S1, lw=2, ms=4, label='konum kol açısından (eski)')
a1.plot(aci, satir(mot, '0.50', 'A[°]:'), '-o', color=S2, lw=2, ms=4, label='konum motor açısından')
a1.set_xlabel('θ$_0$ [°]'); a1.set_ylabel('son 5 s salınım genliği [°]'); a1.set_xticks(range(0, 181, 30))
a1.set_title('(a) Salınım (r$_{gs}$ = 0,50)'); a1.legend(loc='upper center')
a1.annotate('0°: sarkaç salınımı\n(her iki döngüde, sönümlü)', xy=(0, 0.92), xytext=(28, 1.35), color=YAZI2,
            fontsize=7.5, arrowprops=dict(arrowstyle='-', color=YAZI2, lw=0.6))
a2.axhline(0, color=YAZI2, lw=0.8)
a2.plot(aci, satir(kol, '0.50', 'e_son:'), '-o', color=S1, lw=2, ms=4)
a2.plot(aci, satir(mot, '0.50', 'e_son:'), '-o', color=S2, lw=2, ms=4)
a2.set_xlabel('θ$_0$ [°]'); a2.set_ylabel('kolun kalıcı hatası [°]'); a2.set_xticks(range(0, 181, 30))
a2.set_title('(b) Kalıcı hata: salınım gider, hata gelir')
a2.text(90, -1.3, 'motor tarafı: ≈ −(r + mgℓ sin θ$_0$ / K$_s$)', color=YAZI2, ha='center', fontsize=8)
for a in (a1, a2): virgul(a)
kaydet(fig, 'b5_konum_kaynagi.png')

# ---------- Şekil 5.2 ----------
t = oku('ofset_tablosu_log.txt')
aci = [0, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 175, 180]
fig, ax = plt.subplots(figsize=(17*CM, 6.5*CM))
ax.axhline(0, color=YAZI2, lw=0.8)
ax.axhspan(-0.27, 0.27, color=IZGARA, lw=0, zorder=0, label='±0,27° (Hall enkoderinin bir adımı)')
ax.plot(aci, satir(blok(t, 'ofsetsiz'), '0.50', 'e[°]:'), '-o', color=S1, lw=2, ms=4, label='ofsetsiz')
ax.plot(aci, satir(blok(t, 'tam model:'), '0.50', 'e[°]:'), '-o', color=S2, lw=2, ms=4, label='ofset tablosu, ideal enkoder')
ax.plot(aci, satir(blok(t, 'tam model, 0,27° enkoder'), '0.50', 'e[°]:'), '-o', color=S3, lw=2, ms=4, label='ofset tablosu, 0,27° enkoder')
ax.annotate('180°: yanlış yüz,\nhata ≈ 2r ≈ 3,1°', xy=(180, 3.07), xytext=(130, 2.3), color=YAZI2, fontsize=8,
            arrowprops=dict(arrowstyle='-', color=YAZI2, lw=0.6))
ax.set_xlabel('θ$_0$ [°]'); ax.set_ylabel('kolun kalıcı hatası [°]'); ax.set_xticks([0, 30, 60, 90, 120, 150, 180])
ax.set_title('Motor tarafı P-PI, ofset φ$_{ref}$ = θ$_{ref}$ + sign(sin θ$_{ref}$)·r + mgℓ sin θ$_{ref}$ / K$_s$ (r$_{gs}$ = 0,50)')
ax.legend(loc='center', bbox_to_anchor=(0.47, 0.66), ncol=2); ax.set_ylim(-3.4, 3.6); virgul(ax)
kaydet(fig, 'b5_ofset.png')

# ---------- Şekil 6.2 ----------
t = oku('belirsiz_bant_log.txt')
kos = ['ideal, 1° alttan', 'ideal, 1° üstten', 'ideal, 5° alttan', '0,27°, 1° alttan', '0,27°, 1° üstten', '0,27°, 5° alttan']
aci, yuz, tork = [], [], []
for m in re.finditer(r'^\s*(1\d\d\.\d\d) \|(.*)\|\s*([\d.]+)\s*$', t, re.M):
    aci.append(float(m.group(1))); tork.append(float(m.group(3)))
    yuz.append(re.findall(r'([YX]) \(', m.group(2)))
fig, (a1, a2) = plt.subplots(2, 1, figsize=(17*CM, 9*CM), sharex=True, gridspec_kw={'height_ratios': [1.25, 1]})
for k in range(len(kos)):
    for a, y in zip(aci, yuz):
        if y[k] == 'X':
            a1.plot(a, k, 'o', ms=6.5, color=S2, mec='white', mew=0.8)
        else:
            a1.plot(a, k, 'o', ms=4, color=S1, alpha=0.55, mec='none')
a1.set_yticks(range(len(kos))); a1.set_yticklabels(kos); a1.invert_yaxis(); a1.grid(axis='y', visible=False)
a1.set_title('(a) Kol hangi yüzde kaldı? (sürtünmeli ikiz)', loc='left')
a1.plot([], [], 'o', color=S1, alpha=0.55, mec='none', ms=4, label='doğru yüz')
a1.plot([], [], 'o', color=S2, mec='white', ms=6.5, label='yanlış yüz (hata ≈ 3°)')
a1.legend(loc='lower right', bbox_to_anchor=(1, 0.98), ncol=2)
a1.axvspan(179, 180.05, color=IZGARA, lw=0, zorder=0)
a2.plot(aci, tork, '-', color=S1, lw=2, label='kolu yüzde tutan yerçekimi torku mgℓ sin(180° − θ)')
a2.axhline(0.04, color=YAZI2, ls='--', lw=1); a2.text(170.1, 0.0425, 'F$_c$ = 0,04 N m', color=YAZI2, fontsize=7.5)
a2.axhline(0.004, color=YAZI2, ls=':', lw=1); a2.text(170.1, 0.0065, 'F$_c$ / 10', color=YAZI2, fontsize=7.5)
a2.axvspan(179, 180.05, color=IZGARA, lw=0, zorder=0)
a2.set_ylabel('tork [N m]'); a2.set_xlabel('hedef açı [°]'); a2.legend(loc='upper right')
a2.set_title('(b) Belirsiz bantta (gri, 179–180°) tutma torku sürtünmenin onda birinin altında')
a2.set_xlim(169.9, 180.1); a2.set_ylim(0, 0.05); virgul(a2)
kaydet(fig, 'b6_belirsiz_bant.png')
print('ok')
