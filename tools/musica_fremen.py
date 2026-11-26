"""Trilha do trailerfilme2: uma voz que canta numa língua inventada, começa lenta e
quase sussurrada e vai ficando frenética (tambores, coro, cordas) até o corte seco.

Original: melodia, letra e arranjo são gerados aqui (escala hijaz em Ré). A voz é
síntese por formantes: um pulso glotal com vibrato e ornamentos passa por um filtro
de vogais (STFT), com consoantes feitas de ruído. Não imita nenhuma gravação.

  python tools/musica_fremen.py      # gera build/divulgacao/trilha_fremen.wav (só a música, para ouvir)

trailer_filme2.py chama compor(marcas) com os instantes das cenas.
"""
import os
import wave

import numpy as np
from numpy.lib.stride_tricks import sliding_window_view

SR = 48000
CR = 1000            # taxa de controle (altura e volume da voz)
RNG = np.random.default_rng(2026)

# escala hijaz em Ré: Ré Mi♭ Fá# Sol Lá Si♭ Dó Ré
HIJAZ = [0, 1, 4, 5, 7, 8, 10]
RE3 = 50             # Ré 3 (voz de barítono)


def grau(g, base=RE3):
    oit, k = divmod(g, 7)
    return base + 12 * oit + HIJAZ[k]


# formantes de voz masculina cantada: (frequências, amplitudes em dB)
VOGAIS = {
    "a": ((700, 1220, 2600, 3300, 3750), (0, -6, -18, -24, -32)),
    "e": ((420, 1900, 2550, 3300, 3750), (0, -12, -16, -24, -34)),
    "i": ((300, 2200, 2900, 3300, 3750), (0, -18, -22, -28, -36)),
    "o": ((460, 820, 2800, 3500, 4950), (0, -8, -16, -28, -50)),
    "u": ((340, 720, 2550, 3500, 4950), (0, -12, -28, -38, -60)),
}
LARG = (80, 90, 120, 130, 140)

# a "língua": sílabas sem sentido, com som de deserto
SILABAS = ["ya", "ha", "li", "ma", "sha", "ra", "ta", "ki", "ya", "hu", "la", "ma", "ra", "a",
           "na", "sa", "ri", "ka", "ha", "da", "yo", "sha", "le", "ma"]


# ---------------------------------------------------------------- voz

class Partitura:
    """Lista de notas da voz: (início s, duração s, nota midi, sílaba ou None = continua a vogal, trilo)."""

    def __init__(self):
        self.notas = []
        self.k = 0

    def frase(self, t, graus, duracoes, base=RE3, trilo_final=False, silaba_cada=1):
        for i, (g, d) in enumerate(zip(graus, duracoes)):
            sil = None
            if i % silaba_cada == 0:
                sil = SILABAS[self.k % len(SILABAS)]
                self.k += 1
            self.notas.append((t, d, grau(g, base), sil, trilo_final and i == len(graus) - 1))
            t += d
        return t


def _suave(x, n):
    if n <= 1:
        return x
    w = np.hanning(n)
    w /= w.sum()
    return np.convolve(np.pad(x, (n // 2, n - n // 2 - 1), mode="edge"), w, mode="valid")


def _filtro_vogais(src, form_f, form_a, n_quadro=1024, salto=256):
    """Filtra `src` com formantes que mudam no tempo (um conjunto por quadro de STFT)."""
    n = len(src)
    pad = np.pad(src, (n_quadro, n_quadro + salto))
    janela = np.hanning(n_quadro)
    quadros = sliding_window_view(pad, n_quadro)[::salto] * janela
    X = np.fft.rfft(quadros, axis=1)
    f = np.fft.rfftfreq(n_quadro, 1 / SR)[None, :]
    nq = X.shape[0]
    idx = np.clip(((np.arange(nq) * salto - n_quadro + n_quadro / 2) / SR * CR).astype(int), 0, len(form_f) - 1)
    G = np.zeros((nq, f.shape[1]))
    for k in range(5):
        F = form_f[idx, k][:, None]
        A = 10 ** (form_a[idx, k][:, None] / 20)
        G += A / (1 + ((f - F) / LARG[k]) ** 2)
    G += 0.25 / (1 + ((f - 3000) / 260) ** 2)          # o "formante do cantor": a voz projeta
    G *= 1 / (1 + (f / 4500) ** 3)
    Y = np.fft.irfft(X * G, n_quadro, axis=1) * janela
    out = np.zeros(len(pad))
    soma = np.zeros(len(pad))
    for i in range(nq):
        a = i * salto
        out[a:a + n_quadro] += Y[i]
        soma[a:a + n_quadro] += janela ** 2
    out /= np.maximum(soma, 1e-3)
    return out[n_quadro:n_quadro + n]


def nivelar(x, janela=0.06, piso=0.03):
    """Compressor simples: deixa todas as notas com o mesmo volume (a curva vem depois)."""
    n = int(janela * SR)
    rms = np.sqrt(np.convolve(x * x, np.ones(n) / n, mode="same"))
    return x / np.maximum(rms, piso * rms.max()) * 0.25


def cantar(notas, total, desafina=0.0, atraso=0.0, formante=1.0, semente=1, folego=0.06):
    """Renderiza a voz: altura com portamento, vibrato que cresce na nota longa, trilos, consoantes."""
    r = np.random.default_rng(semente)
    nc = int(total * CR) + 1
    alt = np.full(nc, np.nan)
    vol = np.zeros(nc)
    vib = np.zeros(nc)
    tri = np.zeros(nc)
    vog_f = np.zeros((nc, 5))
    vog_a = np.full((nc, 5), -60.0)
    ataques = []
    vog_atual = "a"
    for (t, d, midi, sil, trilo) in notas:
        t += atraso
        a, b = int(t * CR), min(nc, int((t + d) * CR))
        if b <= a:
            continue
        alt[a:b] = midi
        env = np.ones(b - a)
        at, rel = min(40, (b - a) // 3), min(70, (b - a) // 3)
        env[:at] = np.linspace(0, 1, at) if at else env[:at]
        if rel:
            env[-rel:] *= np.linspace(1, 0.55, rel)
        vol[a:b] = np.maximum(vol[a:b], env)
        k = np.arange(b - a) / CR
        vib[a:b] = np.clip((k - 0.25) / 0.5, 0, 1) * (0.35 if d > 0.5 else 0.12)
        if trilo:
            tri[a:b] = np.clip((k - 0.15) / 0.2, 0, 1)
        if sil:
            cons, vog_atual = (sil[:-1], sil[-1]) if len(sil) > 1 else ("", sil)
            ataques.append((t, cons))
        F, A = VOGAIS[vog_atual]
        vog_f[a:b] = np.array(F) * formante
        vog_a[a:b] = A
    # entre notas: segura a altura anterior (portamento) e solta o volume
    ultimo = RE3
    for i in range(nc):
        if np.isnan(alt[i]):
            alt[i] = ultimo
        else:
            ultimo = alt[i]
    # vogal parada onde não há nota: copia a última
    for i in range(1, nc):
        if vog_f[i, 0] == 0:
            vog_f[i], vog_a[i] = vog_f[i - 1], vog_a[i - 1]
    vog_f = np.stack([_suave(vog_f[:, k], 60) for k in range(5)], 1)
    vog_a = np.stack([_suave(vog_a[:, k], 60) for k in range(5)], 1)
    alt = _suave(alt, 45)                                  # portamento de ~45 ms
    tc = np.arange(nc) / CR
    alt = alt + vib * np.sin(2 * np.pi * 5.6 * tc + r.random() * 6) + tri * 1.0 * (np.sin(2 * np.pi * 8.5 * tc) > 0)
    alt = alt + _suave(r.normal(size=nc) * 0.08, 30) + desafina
    vol = _suave(vol, 25)
    # para a taxa de áudio
    n = int(total * SR)
    ta = np.arange(n) / SR * CR
    f0 = 440 * 2 ** ((np.interp(ta, np.arange(nc), alt) - 69) / 12)
    amp = np.interp(ta, np.arange(nc), vol)
    fase = np.cumsum(f0) / SR
    pulso = 2 * (fase % 1.0) - 1
    pulso = pulso - np.r_[0, pulso[:-1]] * 0.6           # puxa o espectro para o de uma glote
    src = (pulso + r.normal(size=n) * folego) * amp
    voz = _filtro_vogais(src, vog_f, vog_a)
    # consoantes: ruído curto no começo da sílaba
    for t, c in ataques:
        a = int((t + atraso) * SR)
        if c in ("", "y", "l", "m", "n", "r"):
            if c == "r":
                m = min(n - a, int(0.09 * SR))
                voz[a:a + m] *= 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 26 * np.arange(m) / SR))
            if c in ("m", "n"):
                m = min(n - a, int(0.07 * SR))
                voz[a:a + m] *= np.linspace(0.25, 1, m)
            continue
        dur = {"h": 0.07, "sh": 0.09, "s": 0.08, "t": 0.012, "k": 0.015, "d": 0.01}.get(c, 0.03)
        m = min(n - a, int(dur * SR))
        if m <= 0:
            continue
        ruido = r.normal(size=m)
        X = np.fft.rfft(ruido)
        fr = np.fft.rfftfreq(m, 1 / SR)
        lo, hi = {"h": (500, 3000), "sh": (1800, 6000), "s": (4000, 9000)}.get(c, (1500, 8000))
        X *= ((fr > lo) & (fr < hi))
        burst = np.fft.irfft(X, m) * np.hanning(m) * (0.10 if c == "h" else 0.18)
        voz[a:a + m] = voz[a:a + m] * (0.3 if c in ("t", "k", "d") else 0.7) + burst
    pico = np.abs(voz).max() + 1e-9
    return voz / pico


# ---------------------------------------------------------------- instrumentos

def _filtro(x, baixo=None, alto=None):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    g = np.ones_like(f)
    if alto:
        g /= 1 + (f / alto) ** 4
    if baixo:
        g /= 1 + (baixo / np.maximum(f, 1)) ** 4
    return np.fft.irfft(X * g, len(x))


def serra(freq, n, detune=0.0):
    t = np.arange(n) / SR
    return sum(2 * ((t * freq * (1 + d)) % 1.0) - 1 for d in (-detune, 0, detune)) / 3


def zumbido(dur, fund=36.71):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = _filtro(serra(fund, n, 0.004) + 0.6 * serra(fund * 2, n, 0.003) + 0.3 * serra(fund * 3, n, 0.002), alto=220)
    return x * (0.7 + 0.3 * np.sin(2 * np.pi * t / 6.5)) * 0.5


def daf(forte=1.0, aberto=True):
    """Pandeiro grande de moldura: grave curto + tapa."""
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    corpo = np.sin(2 * np.pi * (70 + 60 * np.exp(-t / 0.02)) * t) * np.exp(-t / (0.16 if aberto else 0.05))
    tapa = _filtro(RNG.normal(size=n), 900, 6000) * np.exp(-t / 0.012) * 0.6
    return (corpo * (1.0 if aberto else 0.3) + tapa) * forte


def tambor(f0=95, f1=42, dur=1.0, forte=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    freq = f1 + (f0 - f1) * np.exp(-t / 0.06)
    corpo = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t / 0.33)
    estalo = _filtro(RNG.normal(size=n) * np.exp(-t / 0.012), alto=2500) * 0.5
    return np.tanh((corpo + estalo) * 1.6 * forte) * 0.9


def chocalho(forte=1.0):
    n = int(0.08 * SR)
    t = np.arange(n) / SR
    return _filtro(RNG.normal(size=n), 5000, 12000) * np.exp(-t / 0.02) * 0.35 * forte


def pizz(midi, forte=1.0):
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    f = 440 * 2 ** ((midi - 69) / 12)
    x = _filtro(serra(f, n, 0.003), alto=1800) * np.exp(-t / 0.07)
    return x * forte * 0.5


# ---------------------------------------------------------------- composição

def batidas(ini, fim, bpm_ini, bpm_fim, curva=1.6):
    """Instantes das batidas com o andamento acelerando de bpm_ini a bpm_fim."""
    ts, t = [], ini
    while t < fim:
        u = (t - ini) / max(fim - ini, 1e-6)
        bpm = bpm_ini + (bpm_fim - bpm_ini) * u ** curva
        ts.append(t)
        t += 60.0 / bpm
    return ts


def compor(m, total):
    """m: marcas da montagem (s). Devolve a trilha musical mono (sem os efeitos das cenas)."""
    p = Partitura()
    # Ato 1: solo lento, rubato, grave e com ar entre as frases
    t = m["mar"] + 0.6
    t = p.frase(t, [4, 3, 1, 0], [1.6, 0.5, 0.5, 2.6], trilo_final=True) + 0.9
    t = p.frase(t, [0, 1, 4, 5, 4], [0.7, 0.5, 0.9, 1.4, 2.2], silaba_cada=1) + 1.2
    t = max(t, m["tronos"] + 0.4)
    t = p.frase(t, [5, 7, 8, 7, 5, 4], [1.0, 0.6, 0.6, 0.6, 0.8, 2.2], trilo_final=True) + 0.8
    t = max(t, m["brasa"] - 0.2)
    t = p.frase(t, [7, 8, 10, 8, 7], [0.8, 0.5, 0.9, 0.5, 2.4], trilo_final=True) + 0.4
    # o herói se ergue: a voz sobe e começa a repetir
    t = max(t, m["c3"] - 0.3)
    t = p.frase(t, [7, 9, 10, 11, 10, 9, 7], [0.45, 0.45, 0.45, 1.4, 0.4, 0.4, 1.6], trilo_final=True)
    t = max(t + 0.2, m["guardiao"])
    for g in ([7, 8, 7, 5, 4, 5, 7], [8, 10, 8, 7, 5, 7, 8]):
        t = p.frase(t, g, [0.4] * 6 + [1.0])
    # Ato 2: frenético. Notas no tempo das batidas, cada vez mais rápido, mais agudo
    ato2, fim2 = m["ato2"] - 1.0, m["fim_ato2"]
    bts = batidas(ato2, fim2, 96, 164)
    motivos = [[7, 8, 7, 5], [4, 5, 7, 8], [10, 8, 7, 8], [7, 11, 10, 8], [12, 11, 10, 11], [14, 12, 11, 12],
               [10, 11, 12, 14], [12, 14, 15, 14]]
    i = 0
    while i < len(bts) - 2:
        u = (bts[i] - ato2) / (fim2 - ato2)
        sub = 2 if u < 0.45 else 3 if u < 0.8 else 4     # colcheias, tercinas, semicolcheias
        mot = motivos[min(int(u * len(motivos)), len(motivos) - 1)]
        d = (bts[i + 1] - bts[i]) / sub
        notas = [mot[k % 4] for k in range(sub * 2)]
        p.frase(bts[i], notas, [d] * len(notas), silaba_cada=2 if u < 0.5 else 1)
        i += 2
    # o último grito, segurado e tremendo, até o corte
    grito = fim2 - 1.6
    p.notas = [n for n in p.notas if n[0] < grito]
    p.frase(grito, [14], [1.55], trilo_final=True)
    # o Imperador: um murmúrio
    t = m["imperador"] + 1.4
    t = p.frase(t, [0, 1, 0], [1.2, 0.6, 2.2])
    # o logo: o coro segura um acorde
    coro_t = m["logo"] + 3.35

    tt0 = np.arange(int(total * SR)) / SR
    # a curva da música: sussurro no começo, grito no fim do ato 2
    curva = 0.3 + 0.35 * np.clip((tt0 - m["mar"]) / (m["guardiao"] - m["mar"]), 0, 1)         + 0.45 * np.clip((tt0 - m["guardiao"]) / (fim2 - m["guardiao"]), 0, 1) ** 1.3
    curva[tt0 > fim2] = 0.45
    solo = nivelar(cantar(p.notas, total, semente=1))
    mix = solo * curva
    # o coro entra no ato 2 (vozes desafinadas e atrasadas + uma oitava abaixo)
    coro_notas = [n for n in p.notas if m["guardiao"] <= n[0] < fim2]
    for j, (des, atr, form) in enumerate(((0.12, 0.018, 1.03), (-0.1, 0.031, 0.97), (-12.0, 0.0, 1.0))):
        v = cantar(coro_notas, total, desafina=des, atraso=atr, formante=form, semente=10 + j, folego=0.1)
        ganho = np.clip((np.arange(len(v)) / SR - m["guardiao"]) / (fim2 - m["guardiao"]), 0, 1) ** 1.2
        mix += nivelar(v) * ganho * (0.35 if des > -6 else 0.4)
    acorde = Partitura()
    for g, ofs in ((0, 0), (4, 0.03), (7, 0.06), (14, 0.02), (-7, 0.0)):
        acorde.notas.append((coro_t + ofs, 5.0, grau(g), "a", False))
    for j, nt in enumerate(acorde.notas):
        mix += nivelar(cantar([nt], total, semente=40 + j, folego=0.12)) * 0.22

    n = len(mix)
    tt = np.arange(n) / SR

    def por(ini, x, vol=1.0):
        # a percussão começa atrás da voz e cresce até dominar no fim do ato 2
        vol *= 0.3 + 0.7 * min(max((ini - m["guardiao"]) / (fim2 - m["guardiao"]), 0), 1) ** 1.5
        a = int(ini * SR)
        b = min(n, a + len(x))
        if b > a:
            mix[a:b] += x[:b - a] * vol

    # zumbido: do começo até o corte, crescendo; volta baixo no Imperador e no logo
    z = zumbido(total)
    env = np.clip((tt - 0.5) / 6, 0, 1) * (0.5 + 0.5 * np.clip((tt - m["c3"]) / (fim2 - m["c3"]), 0, 1))
    env[(tt > fim2)] = 0
    env[(tt > m["imperador"]) & (tt < m["logo"])] = 0.35
    env[tt > m["logo"]] = 0.6 * np.exp(-(tt[tt > m["logo"]] - m["logo"]) / 6)
    mix += z * env * 0.4
    # pulso de pandeiro a partir do guardião (lento) que acelera no ato 2
    for k, b in enumerate(batidas(m["guardiao"], ato2, 72, 96)):
        por(b, daf(0.5), 0.6)
    bts2 = batidas(ato2, fim2, 96, 164)
    for k, b in enumerate(bts2):
        u = (b - ato2) / (fim2 - ato2)
        por(b, daf(0.8 + 0.4 * u), 0.7)
        if k % 2 == 0:
            por(b, tambor(90, 40, 0.9, 0.9 + 0.5 * u), 0.8)
        d = (bts2[k + 1] - b) if k + 1 < len(bts2) else 0.4
        for s in range(1, 4 if u > 0.4 else 2):
            por(b + d * s / (4 if u > 0.4 else 2), daf(0.35 + 0.3 * u, aberto=False), 0.6)
        for s in range(4):
            por(b + d * s / 4, chocalho(0.4 + 0.8 * u), 0.5 * u)
        # cordas em ostinato a partir do meio
        if u > 0.3:
            for s, g in enumerate((0, 1, 0, 4)):
                por(b + d * s / 4, pizz(grau(g, 38) + (12 if u > 0.75 and s % 2 else 0), 0.6 + 0.6 * u), 0.7)
    return mix


def salvar(caminho, mono):
    x = mono / (np.abs(mono).max() + 1e-9) * 0.89
    est = np.c_[x, np.roll(x, int(0.011 * SR))]
    with wave.open(caminho, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((est * 32767).astype(np.int16).tobytes())


# marcas do trailerfilme2 (para ouvir a música sozinha; o trailer passa as reais)
MARCAS_PADRAO = {"mar": 1.6, "tronos": 12.2, "brasa": 21.8, "c3": 28.2, "guardiao": 31.2, "ato2": 40.2, "fim_ato2": 59.9,
                 "imperador": 61.1, "logo": 69.1}

if __name__ == "__main__":
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(raiz, "build", "divulgacao", "trilha_fremen.wav")
    salvar(out, compor(MARCAS_PADRAO, 80.0))
    print("ok", out)
