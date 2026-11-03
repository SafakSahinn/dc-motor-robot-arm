import sys, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
sys.stdout.reconfigure(encoding="utf-8")
import os
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "simulasyon", "4a_ghaffari")
O = sys.argv[1]
from matplotlib.ticker import FuncFormatter
VF = FuncFormatter(lambda v, p: f"{v:g}".replace(".", ","))
B, OR, AQ, GR = "#2a78d6", "#eb6834", "#1baf7a", "#8a8984"
INK, MUT = "#0b0b0b", "#52514e"
plt.rcParams.update({"font.family": "Segoe UI", "font.size": 9, "axes.edgecolor": "#c9c8c2",
    "axes.labelcolor": INK, "xtick.color": MUT, "ytick.color": MUT, "axes.spines.top": False,
    "axes.spines.right": False, "axes.grid": True, "grid.color": "#ecebe7", "grid.linewidth": .6,
    "figure.facecolor": "white", "axes.facecolor": "#fcfcfb", "legend.frameon": False})

# 1) Kritik kazanç - açı
fig, axs = plt.subplots(1, 2, figsize=(9, 3.4), sharey=True)
for ax, ad, bas in zip(axs, "DA", ["D düzeneği (R ≈ 1, γ(90°) = 0,92)", "A düzeneği (R = 0,17)"]):
    d = np.genfromtxt(f"{R}\\yercekimli_kritik_{ad}.csv", delimiter=",")
    ax.plot(d[:, 0], d[:, 1], "o", ms=4.5, color=B, mec="white", mew=.8, label="Benzetim (kol_benzetim.m)")
    ax.plot(d[:, 0], d[:, 2], "-", lw=2, color=OR, label="Yerçekimli DF (bu çalışma)")
    if ad == "D":
        ax.plot(d[:, 0], d[:, 3], "--", lw=1.6, color=AQ, label="Yerçekimli DF, tork sınırsız")
    ax.axhspan(0.3, 0.33, color=GR, alpha=.35, lw=0)
    ax.text(90, 0.345, "Ghaffari DF: her kazançta çevrim (açıya duyarsız)", ha="center", va="bottom", color=MUT, fontsize=8)
    ax.set_title(bas, loc="left", fontsize=9.5, color=INK)
    ax.yaxis.set_major_formatter(VF); ax.set_xlabel("Kol açısı θ₀ [°]"); ax.set_xticks(range(0, 181, 30)); ax.set_xlim(-3, 183)
axs[0].set_ylabel("Kritik r_gs (salınımın başladığı kazanç)"); axs[0].set_ylim(0.28, 1.32)
h, l = axs[0].get_legend_handles_labels()
fig.legend(h, l, loc="upper center", ncol=3, bbox_to_anchor=(.5, 1.02), fontsize=8.5)
fig.tight_layout(rect=(0, 0, 1, .92)); fig.savefig(f"{O}\\kritik_kazanc.png", dpi=200); plt.close(fig)

# 2) Betik / Simulink / Simscape üst üste
fig, axs = plt.subplots(2, 2, figsize=(9, 4.6), gridspec_kw={"height_ratios": [2.2, 1]}, sharex="col")
for j, (k, bas, ac) in enumerate([(5, "Hücre 5: 90°, r_gs 0,95, başlangıç 5° → kalıcı çevrim", 90),
                                  (1, "Hücre 1: 90°, r_gs 1,20, başlangıç 1° → düzensiz salınım", 90)]):
    M = np.loadtxt(f"{O}\\hucre{k}.csv", delimiter=",")
    s = M[:, 0] <= 2.0; t = M[s, 0]
    a = axs[0, j]
    a.plot(t, M[s, 1] - ac, "-", lw=2.4, color=B, label="kol_benzetim.m (betik)")
    a.plot(t, M[s, 2] - ac, "--", lw=1.3, color=OR, label="kol_model.slx (Simulink)")
    a.plot(t, M[s, 3] - ac, ":", lw=1.5, color=AQ, label="sm_kol_model.slx (Simscape)")
    a.yaxis.set_major_formatter(VF); a.set_title(bas, loc="left", fontsize=9, color=INK); a.set_ylabel("θ − θ₀ [°]" if j == 0 else "")
    b = axs[1, j]
    e2 = np.abs(M[:, 3] - M[:, 1]); e1 = np.abs(M[:, 2] - M[:, 1])
    b.semilogy(M[s, 0], np.maximum(e2[s], 1e-9), "-", lw=1.2, color=AQ)
    b.set_ylim(1e-7, 3); b.set_xlabel("t [s]"); b.xaxis.set_major_formatter(VF)
    b.text(.02, .9, f"Simulink − betik: tam sıfır (8 s boyunca)\nSimscape − betik, en çok: {e2.max():.2g}° (8 s)".replace("0.", "0,"),
           transform=b.transAxes, va="top", fontsize=7.5, color=MUT, bbox=dict(fc="white", ec="none", alpha=.85, pad=2))
    if j == 0: b.set_ylabel("|fark| [°]")
h, l = axs[0, 0].get_legend_handles_labels()
fig.legend(h, l, loc="upper center", ncol=3, bbox_to_anchor=(.5, 1.01), fontsize=8.5)
fig.tight_layout(rect=(0, 0, 1, .93)); fig.savefig(f"{O}\\ust_uste.png", dpi=200); plt.close(fig)
print("tamam")
