"""Trilhas do jogo, sintetizadas (nada gravado, nada de terceiros).

    python tools/gen_music.py              -> assets/music/<faixa>.wav (todas)
    python tools/gen_music.py titulo chefe -> só essas

Clima: deserto ritual, cinema grande. Drones graves enormes que respiram,
"BRAAMs" de metal grave distorcido, tambores rituais pesados e esparsos,
raspagens de metal ressonante, uma voz feminina sem palavras (formantes) com
ornamentos e melismas, canto gutural com harmônicos, palhetas (duduk/gaita de
fole) e escalas como frígio dominante / Hijaz / dupla harmônica. Tudo autoral:
as melodias saem de um gerador com semente fixa, nenhuma é copiada.

Como é montado
- Cada faixa é um buffer CIRCULAR do tamanho exato do loop: um evento que
  passa do fim continua no começo, o reverb é convolução circular (o rabo cai
  no início) e os drones contínuos têm frequência ajustada para fechar um
  número inteiro de ciclos. O loop não tem emenda por construção.
- Filtros são feitos no domínio da frequência (FFT), sem scipy.
- Voz, canto gutural e palhetas: síntese aditiva. Cada harmônico da fonte
  recebe o ganho do envelope de formantes (vogais a/e/i/o/u interpoladas no
  tempo), com vibrato, glissando e ornamentos.
- BRAAM: pilha de dentes-de-serra desafinadas (fundamental, oitava, quinta)
  passando por três filtros fixos que se cruzam conforme o brilho abre e
  fecha, depois saturação.
- Mixagem: barramento seco + envio para reverb (resposta de sala sintética,
  decaimento por banda). Volume normalizado por sonoridade ponderada (graves
  pesam menos), limitador suave sem estalo, pico <= 0,94.

Formato: mono, 22 050 Hz, 16 bits (como antes).
"""
import math
import os
import sys
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "music")

SCALES = {
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
    "lydian": [0, 2, 4, 6, 7, 9, 11],
    "harmonic": [0, 2, 3, 5, 7, 8, 11],
    "phrygdom": [0, 1, 4, 5, 7, 8, 10],     # frígio dominante
    "hijaz": [0, 1, 4, 5, 7, 8, 10],        # mesmo desenho, nome do maqam
    "dharm": [0, 1, 4, 5, 7, 8, 11],        # dupla harmônica
    "locrian": [0, 1, 3, 5, 6, 8, 10],
}
NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7,
        "G#": 8, "Ab": 8, "A": 9, "Bb": 10, "B": 11}


def hz(m):
    return 440.0 * 2 ** ((np.asarray(m, dtype=float) - 69) / 12)


def tsec(n):
    return np.arange(n) / SR


# --- filtros no domínio da frequência ----------------------------------------------------

def spectral(x, curve, pad=0):
    """Aplica uma curva de ganho |H(f)|. Sem pad = filtro circular (bom para loop)."""
    if pad:
        x = np.concatenate([x, np.zeros(pad)])
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(np.fft.rfft(x) * curve(f), len(x))


def lp(fc, order=2):
    return lambda f: 1 / np.sqrt(1 + (f / fc) ** (2 * order))


def hp(fc, order=2):
    return lambda f: 1 / np.sqrt(1 + (fc / np.maximum(f, 1e-3)) ** (2 * order))


def bp(fc, q):
    bw = fc / q
    return lambda f: 1 / np.sqrt(1 + ((f - fc) / (bw / 2)) ** 2)


def chain(*curves):
    def c(f):
        g = np.ones_like(f)
        for k in curves:
            g = g * k(f)
        return g
    return c


def bands(*curves):
    def c(f):
        return sum(k(f) for k in curves)
    return c


def smooth(x, sec, circular=False):
    """Média móvel (cumsum), centrada."""
    w = int(sec * SR)
    if w < 2:
        return x.copy()
    h = w // 2
    if circular:
        xp = np.concatenate([x[-h:], x, x[:w - h]])
    else:
        xp = np.concatenate([np.full(h, x[0]), x, np.full(w - h, x[-1])])
    c = np.cumsum(np.concatenate([[0.0], xp]))
    return (c[w:] - c[:-w])[:len(x)] / w


def lfo(n, cycles, phase=0.0):
    """Senoide com número inteiro de ciclos no loop (fecha sem emenda)."""
    return np.sin(2 * np.pi * cycles * np.arange(n) / n + phase)


def qf(f, n):
    """Ajusta a frequência para caber um número inteiro de ciclos em n amostras."""
    T = n / SR
    return max(1, round(f * T)) / T


def ar(n, a, r, curve=2.0):
    """Envelope ataque (curvo) / sustentação / soltura."""
    e = np.ones(n)
    an = min(n, max(1, int(a * SR)))
    rn = min(n - an, max(1, int(r * SR))) if n > an else 0
    e[:an] = np.linspace(0, 1, an) ** curve
    if rn > 0:
        e[n - rn:] *= np.linspace(1, 0, rn) ** 1.6
    return e


def norm(x):
    return x / max(np.max(np.abs(x)), 1e-9)


# --- formantes ---------------------------------------------------------------------------
# (frequências Hz, amplitudes dB, larguras Hz) de 5 formantes por vogal

TABLES = {
    "sop": {
        "a": ([800, 1150, 2900, 3900, 4950], [0, -6, -32, -20, -50], [80, 90, 120, 130, 140]),
        "e": ([350, 2000, 2800, 3600, 4950], [0, -20, -15, -40, -56], [60, 100, 120, 150, 200]),
        "i": ([270, 2140, 2950, 3900, 4950], [0, -12, -26, -26, -44], [60, 90, 100, 120, 120]),
        "o": ([450, 800, 2830, 3800, 4950], [0, -11, -22, -22, -50], [70, 80, 100, 130, 135]),
        "u": ([325, 700, 2700, 3800, 4950], [0, -16, -35, -40, -60], [50, 60, 170, 180, 200]),
    },
    "alto": {
        "a": ([800, 1150, 2800, 3500, 4950], [0, -4, -20, -36, -60], [80, 90, 120, 130, 140]),
        "o": ([450, 800, 2830, 3500, 4950], [0, -9, -16, -28, -55], [70, 80, 100, 130, 135]),
        "u": ([325, 700, 2530, 3500, 4950], [0, -12, -30, -40, -64], [50, 60, 170, 180, 200]),
        "e": ([400, 1600, 2700, 3300, 4950], [0, -24, -30, -35, -60], [60, 80, 120, 150, 200]),
    },
    "bass": {
        "a": ([600, 1040, 2250, 2450, 2750], [0, -7, -9, -9, -20], [60, 70, 110, 120, 130]),
        "e": ([400, 1620, 2400, 2800, 3100], [0, -12, -9, -12, -18], [40, 80, 100, 120, 120]),
        "i": ([250, 1750, 2600, 3050, 3340], [0, -30, -16, -22, -28], [60, 90, 100, 120, 120]),
        "o": ([400, 750, 2400, 2600, 2900], [0, -11, -21, -20, -40], [40, 80, 100, 120, 120]),
        "u": ([350, 600, 2400, 2675, 2950], [0, -20, -32, -28, -36], [40, 80, 100, 120, 120]),
    },
    # palheta dupla (duduk / gaita): corpo escuro e anasalado, sem "vogal" de fato
    "reed": {
        "a": ([560, 1250, 2350, 3300, 4400], [0, -4, -14, -24, -36], [180, 220, 300, 400, 500]),
        "o": ([480, 1050, 2200, 3100, 4400], [0, -6, -18, -28, -40], [160, 200, 300, 400, 500]),
    },
    "pipe": {   # gaita de fole: mais zumbido no agudo
        "a": ([700, 1500, 2600, 3500, 4600], [0, -2, -8, -16, -28], [200, 300, 400, 500, 600]),
    },
}
CTRL = 32   # taxa de controle dos envelopes de harmônico (1 a cada 32 amostras)


def formant_synth(f0, amp, vpos, table, seq, rng, tilt=0.3, fmax=5000.0, odd=1.0,
                  extra=None, bwmul=1.4):
    """Aditiva: cada harmônico de f0 recebe o ganho do envelope de formantes.

    f0, amp, vpos: arrays por amostra (vpos = posição na lista de vogais seq).
    extra = (freq_array, ganho, largura): uma ressonância a mais (canto de harmônicos).
    """
    n = len(f0)
    phase = np.cumsum(f0) / SR
    ci = np.arange(0, n, CTRL)
    if ci[-1] != n - 1:
        ci = np.append(ci, n - 1)
    f0c, ampc, pc = f0[ci], amp[ci], vpos[ci]
    tab = TABLES[table]
    V = np.array([tab[v] for v in seq], dtype=float)    # (V, 3, 5)
    i0 = np.clip(np.floor(pc).astype(int), 0, len(seq) - 1)
    i1 = np.minimum(i0 + 1, len(seq) - 1)
    fr = np.clip(pc - i0, 0, 1)[:, None]
    F = V[i0, 0] * (1 - fr) + V[i1, 0] * fr
    A = 10 ** ((V[i0, 1] * (1 - fr) + V[i1, 1] * fr) / 20)
    B = (V[i0, 2] * (1 - fr) + V[i1, 2] * fr) * bwmul
    if extra is not None:
        ef = extra[0][ci]
    K = int(fmax / max(np.min(f0), 20))
    idx = np.arange(n)
    out = np.zeros(n)
    for k in range(1, K + 1):
        fk = k * f0c
        g = (A / np.sqrt(1 + ((fk[:, None] - F) / (B / 2)) ** 2)).sum(1)
        g = g * k ** -tilt
        if k % 2 == 0:
            g = g * odd
        if extra is not None:
            g = g + extra[1] / np.sqrt(1 + ((fk - ef) / (extra[2] / 2)) ** 2) * k ** -0.2
        g = g * np.clip((fmax - fk) / 400, 0, 1)
        if not np.any(g > 1e-5):
            continue
        out += np.interp(idx, ci, g * ampc) * np.sin(2 * np.pi * (k * phase + rng.random()))
    return out


# --- frases melódicas (voz, duduk) -------------------------------------------------------

def phrase_events(rng, ctx, start_beat, n_beats, lo, hi, ornate):
    """Lista de (grau, duração_s). Notas longas ligadas por melismas e voltas."""
    beat = ctx["beat"]
    total = n_beats * beat
    c0 = ctx["chord_at"](start_beat)
    c1 = ctx["chord_at"](start_beat + n_beats - 0.01)

    def chord_tone(c, near):
        opts = [c + o + 7 * j for o in (0, 2, 4) for j in range(-1, 5)]
        opts = [d for d in opts if lo <= d <= hi] or [lo]
        return min(opts, key=lambda d: abs(d - near) + rng.random() * 0.8)

    p = chord_tone(c0, (lo + hi) / 2 + rng.integers(-2, 3))
    ev = []
    t = 0.0
    while True:
        rem = total - t
        final = rem < 3.2 * beat
        if final:
            p = chord_tone(c1, p)
        if ev and rng.random() < ornate and rem > 1.0:
            kind = rng.integers(0, 5)
            if kind == 0:
                orn = [p + 1, p, p - 1]                  # volta
            elif kind == 1:
                orn = [p - 3, p - 2, p - 1]              # corrida subindo
            elif kind == 2:
                orn = [p + 2, p + 1]                     # descida
            elif kind == 3:
                orn = [p, p + 1, p, p - 1]               # mordente estendido
            else:
                orn = [p + 1, p + 2, p + 1]              # floreio por cima
            for q in orn:
                d = rng.uniform(0.09, 0.15)
                ev.append((q, d))
                t += d
            rem = total - t
        if final:
            ev.append((p, max(rem, 0.4)))
            break
        hold = float(rng.choice([1, 1.5, 2, 2, 3])) * beat
        hold = min(hold, rem - 2.0 * beat)
        if hold < 0.35:
            hold = 0.35
        ev.append((p, hold))
        t += hold
        step = int(rng.choice([-2, -1, -1, 1, 1, 2, 3, -3, 0]))
        p = int(np.clip(p + step, lo, hi))
    return ev


def sing(ev, ctx, rng, table="sop", seq=("a", "o", "a", "e"), vib=0.32, glide=0.06,
         tilt=0.3, odd=1.0, breath=0.03, fmax=5000.0):
    """Transforma eventos em som: curva de altura com glissando, vibrato que cresce
    nas notas longas, deriva lenta, vogal que muda nota a nota."""
    deg = ctx["deg"]
    total = sum(d for _, d in ev)
    tail = 0.6
    n = int((total + tail) * SR)
    semi = np.zeros(n)
    age = np.zeros(n)
    dur = np.zeros(n)
    vow = np.zeros(n)
    i = 0
    vcur = rng.integers(0, len(seq))
    for d, length in ev:
        j = min(n, i + int(length * SR))
        semi[i:j] = deg(d)
        age[i:j] = np.arange(j - i) / SR
        dur[i:j] = length
        if length > 0.5 and rng.random() < 0.6:
            vcur = rng.integers(0, len(seq))
        vow[i:j] = vcur
        i = j
    semi[i:] = semi[i - 1]
    age[i:] = age[i - 1] + np.arange(n - i) / SR
    dur[i:] = dur[i - 1]
    vow[i:] = vow[i - 1]
    semi = smooth(semi, glide)
    t = tsec(n)
    semi -= 0.9 * np.exp(-t / 0.07)                               # entrada "de baixo"
    rate = 5.0 + rng.random() * 0.8
    depth = vib * np.clip((age - 0.25) / 0.6, 0, 1) * (dur > 0.5)
    drift = smooth(rng.standard_normal(n), 0.25) * 0.6
    semi = semi + depth * np.sin(2 * np.pi * rate * t) + drift
    f0 = hz(semi)
    amp = ar(n, 0.14, tail + 0.25, 1.5) * (1 + 0.025 * (semi - semi.mean()))
    amp *= 1 + 0.05 * smooth(rng.standard_normal(n), 0.05) * 3
    vpos = smooth(vow, 0.15)
    x = formant_synth(f0, amp, vpos, table, list(seq), rng, tilt=tilt, odd=odd, fmax=fmax)
    if breath:
        F = TABLES[table][seq[0]][0]
        nb = rng.standard_normal(n) * amp
        nb = spectral(nb, chain(bands(bp(F[0], 3), bp(F[1], 4), bp(F[2], 5)), hp(300)))
        x = norm(x) + breath * norm(nb) * 0.8
    return norm(x)


# --- instrumentos contínuos (loop inteiro) -----------------------------------------------

def sub_drone(n, midi, swells, rng):
    f = qf(hz(midi), n)
    t = tsec(n)
    x = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * 2 * f * t + 0.5) \
        + 0.15 * np.sin(2 * np.pi * 3 * f * t + 1.1)
    amp = 0.62 + 0.38 * (0.5 + 0.5 * lfo(n, swells, rng.random() * 6))
    return norm(x * amp)


def throat_drone(n, midi, rng, overtones=(8, 9, 10, 12, 10, 9, 8, 6), growl=0.3, breaths=None):
    """Canto gutural: fundamental grave, vogal o<->a e uma ressonância estreita
    que caminha pelos harmônicos (o "assobio" do canto de harmônicos)."""
    T = n / SR
    fh = qf(hz(midi) / 2, n)
    f = 2 * fh
    f0 = f * (1 + 0.0025 * lfo(n, max(1, round(T / 7))))
    vpos = 0.5 + 0.5 * lfo(n, max(1, round(T / 11)), 1.0)
    m = len(overtones)
    ef = np.repeat(np.array(overtones, dtype=float) * f, n // m + 1)[:n]
    ef = smooth(ef, 0.5, circular=True)
    x = formant_synth(f0, np.ones(n), vpos, "bass", ["o", "a"], rng, tilt=0.15, fmax=4200,
                      extra=(ef, 2.2, 45))
    t = tsec(n)
    x = norm(x) * (1 + growl * np.sin(2 * np.pi * fh * t))       # sub-harmônico (kargyraa)
    nb = breaths or max(1, round(T / 9))
    gap = np.zeros(n)
    for b in range(nb):
        c = int((b + 0.5) * n / nb)
        w = int(0.45 * SR)
        k = np.arange(-2 * w, 2 * w)
        gap[(c + k) % n] = np.maximum(gap[(c + k) % n], np.exp(-0.5 * (k / (w / 2)) ** 2))
    return norm(x * (1 - 0.9 * gap))


def reed_drone(n, midis, rng, table="pipe"):
    """Bordão de palheta: tônica e quinta, um pouco de batimento entre elas."""
    T = n / SR
    out = np.zeros(n)
    for i, m in enumerate(midis):
        f = qf(hz(m), n)
        f0 = f * (1 + 0.0015 * lfo(n, max(1, round(T / 5)) + i, rng.random() * 6))
        amp = 0.85 + 0.15 * lfo(n, max(1, round(T / 13)) + i, rng.random() * 6)
        x = formant_synth(f0, amp, np.zeros(n), table, ["a"], rng, tilt=0.5, odd=0.45, fmax=4500,
                          bwmul=1.0)
        out += norm(x) * (1.0 if i == 0 else 0.6)
    nb = rng.standard_normal(n)
    nb = spectral(nb, chain(bp(1600, 1.5), hp(500)))
    return norm(out + 0.06 * norm(nb))


def wind(n, rng, center=500):
    T = n / SR
    x = rng.standard_normal(n)
    a = spectral(x, bp(center, 1.3))
    b = spectral(rng.standard_normal(n), bp(center * 2.7, 7))
    ea = 0.5 + 0.5 * lfo(n, max(1, round(T / 9)), rng.random() * 6) * lfo(n, max(1, round(T / 23)) + 1, 1)
    eb = np.clip(lfo(n, max(1, round(T / 6)), rng.random() * 6), 0, 1) ** 2
    return norm(norm(a) * ea + 0.35 * norm(b) * eb)


# --- eventos -----------------------------------------------------------------------------

_cache = {}


def braam(midi, dur, rng, voicing=(0, 12, 19), bright=1.0):
    key = ("braam", round(midi, 2), round(dur, 2), voicing, bright)
    if key in _cache:
        return _cache[key]
    rel = 2.6
    n = int((dur + rel) * SR)
    t = tsec(n)
    raw = np.zeros(n)
    gains = (1.0, 0.75, 0.5, 0.4, 0.3)
    for v, g in zip(voicing, gains):
        f = float(hz(midi + v))
        for det in (-0.0045, 0.0, 0.005):
            raw += g * (2 * ((f * (1 + det) * t + rng.random()) % 1) - 1)
    raw = norm(raw)
    dark = spectral(raw, lp(160, 2))
    mid = spectral(raw, lp(550, 2))
    hi = spectral(raw, lp(1900 * bright, 2))
    peak = min(dur * 0.45, 1.6)
    b = np.interp(t, [0, peak, dur, dur + rel], [0.0, 1.0, 0.35, 0.0])
    y = np.where(b < 0.5, dark * (1 - 2 * b) + mid * 2 * b, mid * (2 - 2 * b) + hi * (2 * b - 1))
    y = np.tanh(3.0 * norm(y)) * (1 + 0.12 * np.sin(2 * np.pi * 29 * t))
    e = np.interp(t, [0, peak * 0.8, dur, dur + rel], [0.0, 1.0, 0.8, 0.0]) ** 1.4
    out = norm(spectral(y * e, hp(28, 2)))
    _cache[key] = out
    return out


def pluck(midi, dur=1.6, bright=0.6, rng=None):
    key = ("pluck", round(float(midi), 2), dur, bright)
    if key in _cache:
        return _cache[key]
    f = float(hz(midi))
    n = int(dur * SR)
    t = tsec(n)
    x = np.zeros(n)
    k = 1
    while True:
        fk = f * k * (1 + 0.0003 * k * k)
        if fk > 6500 or k > 40:
            break
        a = abs(math.sin(math.pi * k / 5.3)) / k * math.exp(-(k - 1) * (1 - bright) * 0.35)
        x += a * np.sin(2 * np.pi * fk * t + k) * np.exp(-t * (1.8 + 0.9 * k))
        k += 1
    x += np.random.default_rng(int(midi)).standard_normal(n) * np.exp(-t * 300) * 0.3
    out = norm(x * ar(n, 0.002, 0.08, 1))
    _cache[key] = out
    return out


def glass(midi, dur=3.5):
    f = float(hz(midi))
    while f > 1800:
        f /= 2
    n = int(dur * SR)
    t = tsec(n)
    x = np.zeros(n)
    for r, a, d in ((1, 1, 1.4), (2.76, 0.45, 2.5), (5.40, 0.22, 4.0), (8.93, 0.1, 6.0)):
        if f * r < 9000:
            x += a * np.sin(2 * np.pi * f * r * t) * np.exp(-t * d)
    return norm(x * ar(n, 0.003, 0.2, 1))


def church_bell(midi, dur=7.0, rng=None):
    key = ("church", midi, dur)
    if key in _cache:
        return _cache[key]
    f = float(hz(midi))
    n = int(dur * SR)
    t = tsec(n)
    x = np.zeros(n)
    parts = ((0.5, 0.6, 0.35), (1.0, 0.8, 0.6), (1.19, 0.6, 0.8), (1.5, 0.35, 0.9), (2.0, 0.5, 1.1),
             (2.51, 0.25, 1.6), (2.66, 0.2, 1.7), (3.01, 0.18, 2.1), (4.1, 0.1, 3.0))
    for r, a, d in parts:
        fr = f * r
        if fr < 8000:
            x += a * (np.sin(2 * np.pi * fr * t) + 0.5 * np.sin(2 * np.pi * fr * 1.0015 * t)) * np.exp(-t * d)
    strike = np.random.default_rng(midi).standard_normal(n) * np.exp(-t * 80)
    x += 0.3 * spectral(strike, bp(2500, 1.5))
    out = norm(x)
    _cache[key] = out
    return out


def scrape(dur, rng, f0):
    """Metal raspado: parciais inarmônicos com amplitude trêmula + ruído ressonante."""
    n = int(dur * SR)
    t = tsec(n)
    glide = 1 + rng.uniform(-0.07, 0.07) * t / dur
    ph = np.cumsum(glide) / SR
    x = np.zeros(n)
    peaks = []
    for r, a in ((1, 1), (2.32, 0.7), (3.86, 0.5), (5.11, 0.4), (7.3, 0.25), (9.6, 0.15)):
        fr = f0 * r
        if fr > 7000:
            continue
        jit = np.abs(smooth(rng.standard_normal(n), 0.025)) * 6
        x += a * jit * np.sin(2 * np.pi * fr * ph + rng.random() * 6)
        peaks.append(bp(fr, 40))
    nz = rng.standard_normal(n) * np.abs(smooth(rng.standard_normal(n), 0.04)) * 5
    if peaks:
        nz = spectral(nz, bands(*peaks))
    y = norm(x) + 0.6 * norm(nz)
    e = np.interp(t, [0, dur * rng.uniform(0.3, 0.6), dur], [0, 1, 0]) ** 1.5
    return norm(spectral(y * e, hp(150)))


def drum(kind, rng):
    t = None
    if kind in ("T", "t", "f", "d"):            # taiko grave, taiko médio, bendir, doum
        f, dec, skin, buzz = {"T": (52, 0.85, 0.6, 0.0), "t": (88, 0.6, 0.55, 0.0),
                              "f": (118, 0.45, 0.5, 0.35), "d": (96, 0.35, 0.3, 0.0)}[kind]
        f *= rng.uniform(0.96, 1.04)
        n = int(dec * 2.6 * SR)
        t = tsec(n)
        fp = f * (1 + 0.7 * np.exp(-t * 28))
        ph = 2 * np.pi * np.cumsum(fp) / SR
        x = np.sin(ph) * np.exp(-t * 3 / dec) + 0.45 * np.sin(1.59 * ph + 1) * np.exp(-t * 5.5 / dec) \
            + 0.25 * np.sin(2.14 * ph + 2) * np.exp(-t * 8 / dec) + 0.12 * np.sin(2.65 * ph) * np.exp(-t * 11 / dec)
        nz = rng.standard_normal(n)
        x += skin * spectral(nz * np.exp(-t * 45), lp(1400, 2))
        if buzz:
            x += buzz * spectral(nz * np.exp(-t * 14), chain(hp(2200), lp(6000)))
        return norm(np.tanh(1.6 * norm(x)))
    if kind == "k":                              # tek: borda aguda
        n = int(0.18 * SR)
        t = tsec(n)
        x = np.sin(2 * np.pi * 640 * rng.uniform(0.95, 1.05) * t) * np.exp(-t * 40) \
            + 0.8 * spectral(rng.standard_normal(n) * np.exp(-t * 70), bp(3200, 2))
        return norm(x)
    if kind == "c":                              # baqueta / estalo de madeira
        n = int(0.12 * SR)
        t = tsec(n)
        x = spectral(rng.standard_normal(n) * np.exp(-t * 90), bp(2100 * rng.uniform(0.9, 1.1), 5)) \
            + 0.5 * np.sin(2 * np.pi * 1100 * t) * np.exp(-t * 60)
        return norm(x)
    if kind == "r":                              # chocalho de sementes
        n = int(0.16 * SR)
        t = tsec(n)
        grains = (rng.random(n) < 0.02) * rng.standard_normal(n)
        x = spectral(grains + rng.standard_normal(n) * 0.2, chain(hp(3500), lp(8000)))
        return norm(x * ar(n, 0.015, 0.1, 1))
    if kind == "B":                              # golpe de cinema: sub + taiko + estalo
        n = int(3.2 * SR)
        t = tsec(n)
        fp = 30 + 40 * np.exp(-t * 9)
        x = np.sin(2 * np.pi * np.cumsum(fp) / SR) * np.exp(-t * 1.1)
        tk = drum("T", rng)
        x[:len(tk)] += 0.55 * tk[:n]
        x += 0.35 * spectral(rng.standard_normal(n) * np.exp(-t * 18), lp(900, 2))
        return norm(np.tanh(2.2 * norm(x)))
    if kind == "h":                              # coração: tum-tum
        n = int(0.9 * SR)
        t = tsec(n)
        x = np.zeros(n)
        for off, f, g in ((0.0, 58, 1.0), (0.21, 46, 0.75)):
            i = int(off * SR)
            tt = t[: n - i]
            fp = f * (1 + 0.5 * np.exp(-tt * 30))
            x[i:] += g * np.sin(2 * np.pi * np.cumsum(fp) / SR) * np.exp(-tt * 9)
        x += 0.25 * spectral(rng.standard_normal(n) * np.exp(-t * 25), lp(300, 2))
        return norm(np.tanh(1.8 * x))
    if kind == "a":                              # bigorna
        n = int(1.4 * SR)
        t = tsec(n)
        x = sum(np.sin(2 * np.pi * f * t) * w * np.exp(-t * d) for f, w, d in
                ((1180, 0.5, 3.5), (1730, 0.35, 4.5), (2650, 0.25, 6), (3990, 0.15, 9)))
        x += rng.standard_normal(n) * np.exp(-t * 60) * 0.4
        return norm(x)
    if kind == "m":                              # gongo / metal grande
        n = int(4.0 * SR)
        t = tsec(n)
        f = 150 * rng.uniform(0.85, 1.2)
        x = np.zeros(n)
        for r, a, d in ((1, 1, 0.9), (1.52, 0.7, 1.1), (2.27, 0.55, 1.4), (2.73, 0.4, 1.7),
                        (3.37, 0.3, 2.2), (4.1, 0.2, 2.8), (5.2, 0.12, 3.5)):
            x += a * (np.sin(2 * np.pi * f * r * t) + 0.6 * np.sin(2 * np.pi * f * r * 1.003 * t)) * np.exp(-t * d)
        x *= ar(n, 0.01, 0.5, 1)
        return norm(x)
    if kind == "w":                              # gota em caverna (bolha + "ping" metálico)
        n = int(1.2 * SR)
        t = tsec(n)
        f1 = rng.uniform(500, 900)
        fp = f1 * (1 + 1.4 * (1 - np.exp(-t * 40)))
        x = np.sin(2 * np.pi * np.cumsum(fp) / SR) * np.exp(-t * 35)
        fping = rng.uniform(1800, 3200)
        x += 0.35 * (np.sin(2 * np.pi * fping * t) + 0.5 * np.sin(2 * np.pi * fping * 2.71 * t)) * np.exp(-t * 6)
        return norm(x)
    raise ValueError(kind)


DRUM_SEND = {"T": 0.4, "t": 0.35, "f": 0.3, "d": 0.25, "k": 0.3, "c": 0.5, "r": 0.3, "B": 0.5,
             "h": 0.15, "a": 0.45, "m": 0.6, "w": 0.75}


# --- reverb ------------------------------------------------------------------------------

def reverb_ir(rt, rng, pre=0.03):
    L = int((rt * 1.15 + pre) * SR)
    t = tsec(L)
    w = rng.standard_normal(L)
    f = np.fft.rfftfreq(L, 1 / SR)
    W = np.fft.rfft(w)
    low = 1 / (1 + (f / 350) ** 4)
    high = 1 / (1 + (2800 / np.maximum(f, 1)) ** 4)
    mid = np.clip(1 - low - high, 0, 1)
    ir = np.zeros(L)
    for band, k in ((low, 1.15), (mid, 1.0), (high, 0.45)):
        ir += np.fft.irfft(W * band, L) * np.exp(-6.9 * t / (rt * k))
    ir *= np.clip((t - pre) / 0.07, 0, 1)                    # pré-atraso + densidade crescendo
    for d, g in ((0.011, 0.5), (0.019, -0.4), (0.029, 0.35), (0.041, -0.3), (0.057, 0.25)):
        i = int((pre + d) * SR)
        if i < L:
            ir[i] += g * np.max(np.abs(ir)) * 2
    ir = spectral(ir, lp(7000, 1))
    return ir / np.sqrt(np.sum(ir ** 2))


# --- composição --------------------------------------------------------------------------

SEND = {"sub": 0.04, "throat": 0.3, "reed": 0.25, "braam": 0.4, "voice": 0.6, "voice2": 0.65,
        "duduk": 0.45, "choir": 0.55, "organ": 0.5, "bells": 0.6, "pluck": 0.35, "shimmer": 0.75,
        "scrape": 0.7, "wind": 0.3, "drone5": 0.1}


class Mix:
    def __init__(self, n):
        self.n = n
        self.dry = np.zeros(n)
        self.send = np.zeros(n)

    def _add(self, buf, x, i):
        i %= self.n
        while len(x):
            j = min(self.n - i, len(x))
            buf[i:i + j] += x[:j]
            x = x[j:]
            i = 0

    def put(self, x, at_sec, gain, send):
        i = int(round(at_sec * SR))
        self._add(self.dry, x * gain, i)
        if send:
            self._add(self.send, x * gain * send, i)


def render(r):
    rng = np.random.default_rng(r["seed"])
    bpm = r["bpm"]
    beat = 60.0 / bpm
    meter = r.get("meter", 4)
    bars = r["bars"]
    total_beats = bars * meter
    n = int(round(total_beats * beat * SR))
    mix = Mix(n)
    root = 36 + NOTE[r["key"]]                       # C2..B2
    scale = SCALES[r["scale"]]
    prog = r.get("prog", [0])
    cb = r.get("chord_bars", 4)

    def deg(d, octave=0):
        d = int(d)
        return root + scale[d % 7] + 12 * (d // 7 + octave)

    def chord_at(b):
        return prog[int((b % total_beats) // (cb * meter)) % len(prog)]

    ctx = {"beat": beat, "deg": deg, "chord_at": chord_at}
    L = r["layers"]

    def gain_of(name):
        return L[name]["gain"]

    def send_of(name):
        return L[name].get("send", SEND.get(name, 0.3))

    sub_m = root - 12                                # C1..B1: o chão de tudo
    # drones contínuos -----------------------------------------------------------------
    if "sub" in L:
        x = sub_drone(n, sub_m, L["sub"].get("swells", max(1, bars // 4)), rng)
        mix.put(x, 0, gain_of("sub"), send_of("sub"))
        if L["sub"].get("fifth"):
            x = sub_drone(n, sub_m + 7, max(1, bars // 4) + 1, rng)
            mix.put(x, 0, gain_of("sub") * L["sub"]["fifth"], send_of("sub"))
        if L["sub"].get("cluster"):                  # segunda menor: tensão no grave
            x = sub_drone(n, sub_m + 13, max(1, bars // 3), rng)
            mix.put(x, 0, gain_of("sub") * L["sub"]["cluster"], send_of("sub"))
    if "throat" in L:
        o = L["throat"]
        m = root if root <= 43 else root - 12
        x = throat_drone(n, m + o.get("shift", 0), rng, o.get("overtones", (8, 9, 10, 12, 10, 9, 8, 6)),
                         o.get("growl", 0.3))
        mix.put(x, 0, o["gain"], send_of("throat"))
    if "reed" in L:
        o = L["reed"]
        m = root + 12 * o.get("octave", 0)
        x = reed_drone(n, [m, m + 7] if o.get("fifth", True) else [m], rng, o.get("table", "pipe"))
        mix.put(x, 0, o["gain"], send_of("reed"))
    if "wind" in L:
        x = wind(n, rng, L["wind"].get("center", 500))
        mix.put(x, 0, gain_of("wind"), send_of("wind"))

    # acordes: coro e órgão ----------------------------------------------------------------
    nchords = int(math.ceil(bars / cb))
    seg = cb * meter * beat
    if "choir" in L:
        o = L["choir"]
        table = o.get("table", "bass")
        vowels = o.get("vowels", ["o", "u", "o", "a"])
        for c in range(nchords):
            d = prog[c % len(prog)]
            notes = [deg(d + k, o.get("octave", 1)) for k in o.get("voicing", (0, 2, 4, 7))]
            ln = seg + 2.5
            m_ = int(ln * SR)
            acc = np.zeros(m_)
            for j, note in enumerate(notes):
                for det in (-0.07, 0.08):
                    tt = tsec(m_)
                    semi = note + det + 0.12 * np.sin(2 * np.pi * (4.3 + rng.random()) * tt + rng.random() * 6)
                    semi = semi + smooth(rng.standard_normal(m_), 0.3) * 0.5
                    vp = np.full(m_, float(rng.integers(0, len(vowels))))
                    vp = np.clip(vp + np.linspace(0, rng.uniform(-1, 1), m_), 0, len(vowels) - 1)
                    v = formant_synth(hz(semi), np.ones(m_), vp, table, vowels, rng, tilt=0.4, fmax=3800)
                    acc += norm(v) * (1.0 if j == 0 else 0.8)
            acc = norm(acc) * ar(m_, 1.6, 2.4, 1.5)
            mix.put(acc, c * seg - 0.6, o["gain"], send_of("choir"))
    if "organ" in L:
        o = L["organ"]
        draw = ((0.5, 0.55), (1, 1.0), (2, 0.65), (3, 0.35), (4, 0.3), (6, 0.12), (8, 0.08))
        for c in range(nchords):
            d = prog[c % len(prog)]
            notes = [deg(d, 1), deg(d + 2, 1), deg(d + 4, 1), deg(d, 0), deg(d + 7, 1)]
            ln = seg + 1.2
            m_ = int(ln * SR)
            tt = tsec(m_)
            acc = np.zeros(m_)
            for note in notes:
                f = float(hz(note))
                for det in (0.9991, 1.0009):
                    for rr, w in draw:
                        if f * rr * det < 6000:
                            acc += w * np.sin(2 * np.pi * f * rr * det * tt + rng.random() * 6)
            acc *= 1 + 0.05 * np.sin(2 * np.pi * 5.6 * tt)
            acc = norm(spectral(acc, lp(2600, 1))) * ar(m_, 0.5, 1.2, 1.2)
            mix.put(acc, c * seg - 0.2, o["gain"], send_of("organ"))

    # BRAAMs ---------------------------------------------------------------------------------
    if "braam" in L:
        o = L["braam"]
        for b in range(o.get("offset", 0), bars, o["every"]):
            at = b * meter + o.get("at", 0)
            d = chord_at(at)
            m = deg(d) - 12
            while m > 43:
                m -= 12
            while m < 31:
                m += 12
            x = braam(m, o.get("dur", 4) * beat, rng, tuple(o.get("voicing", (0, 12, 19))), o.get("bright", 1.0))
            mix.put(x, at * beat - min(0.6, 0.15 * o.get("dur", 4) * beat), o["gain"], send_of("braam"))

    # vozes ----------------------------------------------------------------------------------
    for name in ("voice", "voice2", "duduk"):
        if name not in L:
            continue
        o = L[name]
        bars_list = o.get("at") or list(range(o.get("offset", 0), bars, o.get("every", 4)))
        for b in bars_list:
            start = b * meter
            nb = o.get("len", 2) * meter
            ev = phrase_events(rng, ctx, start, nb, o.get("lo", 14), o.get("hi", 21), o.get("ornate", 0.5))
            if name == "duduk":
                x = sing(ev, ctx, rng, table="reed", seq=("a", "o"), vib=0.14, glide=0.08, tilt=0.6,
                         odd=0.5, breath=0.06, fmax=4500)
            else:
                x = sing(ev, ctx, rng, table=o.get("table", "sop"), seq=tuple(o.get("vowels", ("a", "o", "a", "e"))),
                         vib=o.get("vib", 0.32))
            mix.put(x, start * beat, o["gain"], send_of(name))

    # cordas pinçadas (oud/kanun) -------------------------------------------------------------
    if "pluck" in L:
        o = L["pluck"]
        step = o.get("step", 0.5)
        pat = o["pattern"]
        k = 0
        pos = 0.0
        while pos < total_beats - 1e-6:
            p = pat[k % len(pat)]
            if p is not None and rng.random() > o.get("skip", 0.0):
                d = p + (chord_at(pos) if o.get("follow", True) else 0)
                acc = 1.0 if (k % len(pat)) in o.get("accents", (0,)) else 0.7
                x = pluck(deg(d, o.get("octave", 1)), o.get("ring", 1.4), o.get("bright", 0.6))
                mix.put(x, pos * beat + rng.uniform(-0.004, 0.004), o["gain"] * acc, send_of("pluck"))
            pos += step
            k += 1

    # sinos ----------------------------------------------------------------------------------
    if "bells" in L:
        o = L["bells"]
        for b in range(o.get("offset", 0), bars, o.get("every", 1)):
            for bb in o.get("beats", [0]):
                at = b * meter + bb
                d = chord_at(at)
                if o.get("kind", "glass") == "church":
                    x = church_bell(deg(d + int(rng.choice(o.get("degs", [0, 4]))), o.get("octave", 2)))
                else:
                    x = glass(deg(d + int(rng.choice([0, 2, 4, 7])), o.get("octave", 3)))
                mix.put(x, at * beat, o["gain"] * rng.uniform(0.8, 1.0), send_of("bells"))

    if "shimmer" in L:
        o = L["shimmer"]
        pos = 0.0
        while pos < total_beats - 1e-6:
            if rng.random() < o.get("density", 0.25):
                d = chord_at(pos) + int(rng.choice([0, 2, 4, 6, 7, 9, 11]))
                x = glass(deg(d, 4), 2.5) if rng.random() < 0.5 else pluck(deg(d, 3), 2.0, 0.3)
                mix.put(x, pos * beat, o["gain"] * rng.uniform(0.5, 1.0), send_of("shimmer"))
            pos += o.get("step", 0.5)

    if "scrape" in L:
        o = L["scrape"]
        cnt = o.get("count", 3)
        for i in range(cnt):
            dur = rng.uniform(3, 6)
            at = (i + rng.uniform(0, 0.6)) * n / SR / cnt
            x = scrape(dur, rng, rng.uniform(*o.get("freq", (180, 420))))
            mix.put(x, at, o["gain"] * rng.uniform(0.7, 1.0), send_of("scrape"))

    # percussão ------------------------------------------------------------------------------
    variants = {}
    for kind, (pats, gain) in r.get("drums", {}).items():
        if kind not in variants:
            variants[kind] = [drum(kind, rng) for _ in range(3)]
        for bar in range(bars):
            pat = pats[bar % len(pats)]
            steps = len(pat)
            for s, ch in enumerate(pat):
                vel = {"X": 1.0, "x": 0.8, "o": 0.5, "?": 0.45}.get(ch, 0)
                if ch == "?" and rng.random() < 0.5:
                    vel = 0
                if not vel:
                    continue
                at = (bar * meter + s * meter / steps) * beat + rng.uniform(-0.006, 0.006)
                x = variants[kind][int(rng.integers(0, 3))]
                mix.put(x, at, gain * vel * rng.uniform(0.9, 1.05), DRUM_SEND[kind])

    # mixagem final --------------------------------------------------------------------------
    ir = reverb_ir(r.get("rt", 4.0), rng)
    irp = np.zeros(n)
    irp[:min(len(ir), n)] = ir[:n]
    wet = np.fft.irfft(np.fft.rfft(mix.send) * np.fft.rfft(irp), n)
    y = mix.dry + wet * r.get("rev", 0.7)
    # graves abaixo de ~50 Hz um pouco contidos: o peso fica, o limitador não engasga
    lo = r.get("shelf", 0.55)
    shelf = lambda f: lo + (1 - lo) * hp(60, 2)(f)
    y = spectral(y, chain(hp(30, 3), shelf, lp(r.get("master_lp", 9000), 2)))
    y -= y.mean()
    return master(y, r.get("loud", -16.0))


def loudness_db(x):
    """Sonoridade aproximada (ponderação parecida com K): graves pesam menos."""
    f = lambda fr: hp(110, 1)(fr) * (1 + 0.6 * (1 - lp(1800, 2)(fr)))
    w = spectral(x, f)
    return 10 * np.log10(np.mean(w ** 2) + 1e-12)


def master(y, target_db):
    y = y * 10 ** ((target_db - loudness_db(y)) / 20)
    # limitador: envelope de pico por blocos, suavizado (circular, sem emenda)
    blk = 256
    n = len(y)
    m = int(math.ceil(n / blk))
    pad = np.concatenate([np.abs(y), np.zeros(m * blk - n)])
    pk = pad.reshape(m, blk).max(1)
    pk = np.maximum.reduce([np.roll(pk, s) for s in (-2, -1, 0, 1, 2)])
    pk = np.convolve(np.concatenate([pk[-3:], pk, pk[:3]]), np.ones(7) / 7, "same")[3:-3]
    ceiling = 0.8
    g = np.minimum(1.0, ceiling / np.maximum(pk, 1e-9))
    g = np.interp(np.arange(n), np.arange(m) * blk + blk / 2, g, period=n)
    y = y * g
    th = 0.85
    a = np.abs(y)
    y = np.where(a > th, np.sign(y) * (th + (1 - th) * np.tanh((a - th) / (1 - th))), y)
    return y * 0.94


def save(name, x):
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


# --- as faixas ---------------------------------------------------------------------------
# padrões de percussão: um caractere por passo; X forte, x normal, o fraco, ? talvez.
# Vários compassos na lista = variação (o padrão gira compasso a compasso).

TRACKS = {
    # Título: o mais épico. Drone de Ré, canto gutural, BRAAMs a cada 4 compassos,
    # a voz entra por cima; taiko raro e enorme.
    "titulo": dict(
        seed=101, bpm=66, key="D", scale="minor", bars=16, prog=[0, 5, 3, 4], chord_bars=4,
        rt=5.5, rev=0.75, loud=-14.0,
        layers={"sub": dict(gain=0.55, swells=4), "throat": dict(gain=0.32),
                "braam": dict(gain=0.85, every=4, dur=6, voicing=(0, 12, 19, 24)),
                "voice": dict(gain=0.55, every=4, offset=1, len=3, lo=14, hi=22, ornate=0.65),
                "choir": dict(gain=0.16, table="alto", octave=2, vowels=["a", "o"], voicing=(0, 4, 7)),
                "scrape": dict(gain=0.18, count=4), "wind": dict(gain=0.08, center=420)},
        drums={"T": (["X...............", "................", "x.........o.....", "................",
                      "X...............", "........o.......", "x.....o...x...o.", "X..............."], 0.8),
               "B": (["X...............", "", "", "", "", "", "", ""], 0.75),
               "f": (["................", "..........?...?.", "................", "....?.......o..."], 0.25)},
    ),
    # Passagem: respiro. Fá lídio, drone macio, voz grave em "u/o", vidro e vento.
    "passagem": dict(
        seed=102, bpm=60, key="F", scale="lydian", bars=12, prog=[0, 1, 0, 4], chord_bars=3,
        rt=6.5, rev=0.85, loud=-17.0,
        layers={"sub": dict(gain=0.4, swells=3), "reed": dict(gain=0.12, table="reed"),
                "voice": dict(gain=0.4, every=6, offset=1, len=4, lo=12, hi=19, ornate=0.4, vowels=("o", "u", "a")),
                "shimmer": dict(gain=0.18, density=0.12, step=1), "wind": dict(gain=0.14, center=650),
                "scrape": dict(gain=0.1, count=2, freq=(300, 600))},
        drums={"T": (["X...............", "................", "................", "................",
                      "................", "........o......."], 0.45)},
    ),
    # Mar de Cinzas: o deserto. Ré frígio, bordão de gaita, duduk e voz em
    # pergunta-e-resposta, bendir e darbuka em 3+3+2, tempestade de areia.
    "mar_de_cinzas": dict(
        seed=103, bpm=96, key="D", scale="phrygian", bars=20, prog=[0, 1, 0, 6], chord_bars=2,
        rt=3.6, rev=0.6, loud=-14.5,
        layers={"sub": dict(gain=0.45, swells=5), "reed": dict(gain=0.2),
                "braam": dict(gain=0.6, every=8, offset=0, dur=6, voicing=(0, 12, 19)),
                "duduk": dict(gain=0.5, every=4, offset=2, len=2, lo=7, hi=14, ornate=0.55),
                "voice": dict(gain=0.45, every=4, offset=0, len=2, lo=14, hi=21, ornate=0.6),
                "wind": dict(gain=0.16, center=520), "scrape": dict(gain=0.14, count=3)},
        drums={"f": (["X..x..x.X..x.o..", "X..x..x.X.....o.", "X..x..x.X..x.x.o", "X.....x.X..x...."], 0.42),
               "d": (["x.....x...x.....", "x.....x.........", "x.....x...x...x.", "x..........x...."], 0.4),
               "k": (["..o...o...o.?.o.", "..o.?.o...o...o.", "..o...o.?.o.o.o.", "..o...o...o....."], 0.2),
               "T": (["X...............", "................", "................", "x.......x......."], 0.6)},
    ),
    # Salões do Último Inverno: frio. Mi menor, gutural baixinho, sinos de vidro,
    # voz distante em "u", vento forte, taiko quase nunca.
    "saloes": dict(
        seed=104, bpm=72, key="E", scale="minor", bars=14, prog=[0, 5, 2, 6], chord_bars=2,
        rt=6.0, rev=0.8, loud=-16.0,
        layers={"sub": dict(gain=0.45, swells=3), "throat": dict(gain=0.18, overtones=(10, 12, 15, 12, 10, 9)),
                "voice": dict(gain=0.4, every=4, offset=1, len=3, lo=14, hi=21, ornate=0.45, vowels=("u", "o", "a")),
                "bells": dict(gain=0.22, kind="glass", every=1, beats=[0, 2.5], octave=3),
                "wind": dict(gain=0.24, center=800), "scrape": dict(gain=0.12, count=3, freq=(500, 900))},
        drums={"T": (["X...............", "................", "................", "........o.......",
                      "................", "................", "x..............."], 0.55)},
    ),
    # Forja Rubra: trabalho. Dó menor harmônica, conjunto de taikos martelando
    # em grupos irregulares, bigorna, BRAAM a cada 2 compassos, gutural rosnando.
    "forja_rubra": dict(
        seed=105, shelf=0.32, bpm=132, key="C", scale="harmonic", bars=28, prog=[0, 0, 5, 4], chord_bars=2,
        rt=3.0, rev=0.5, loud=-13.0,
        layers={"sub": dict(gain=0.34, swells=7), "throat": dict(gain=0.3, growl=0.5),
                "braam": dict(gain=0.6, every=2, dur=3, voicing=(0, 12, 19)),
                "voice": dict(gain=0.4, every=8, offset=4, len=2, lo=14, hi=21, ornate=0.7),
                "scrape": dict(gain=0.15, count=5, freq=(250, 500))},
        drums={"T": (["X..x..X.....x...", "X..x..X...x.x...", "X..x..X.....x..o", "X..x..X.x.x.x.x."], 0.42),
               "t": (["....x.......x..x", "....x...o...x...", "....x.......x.o.", "..o.x.o.o.x.x.x."], 0.45),
               "a": (["x.......x...x...", "x.......x.......", "x.......x...x.x.", "x...x...x...x..."], 0.28),
               "f": (["?.o.?.o.?.o.?.o.", "o.?.o.?.o.?.o.?."], 0.18),
               "B": (["X...............", "", "", "", "", "", "", ""], 0.6)},
    ),
    # Torre de Babel: todas as línguas. Lá dórico, duas vozes e um duduk que se
    # sobrepõem (cada uma em outra vogal), cordas em tercinas contra o 4/4.
    "torre_babel": dict(
        seed=106, bpm=110, key="A", scale="dorian", bars=24, prog=[0, 3, 6, 4], chord_bars=2,
        rt=4.5, rev=0.65, loud=-14.5,
        layers={"sub": dict(gain=0.42, swells=6), "reed": dict(gain=0.12, table="reed"),
                "pluck": dict(gain=0.24, step=1 / 3, pattern=[0, 2, 4, 7, 4, 2], accents=(0, 3), octave=1),
                "voice": dict(gain=0.42, every=4, offset=0, len=3, lo=14, hi=21, ornate=0.55, vowels=("a", "e")),
                "voice2": dict(gain=0.32, every=4, offset=2, len=3, lo=11, hi=17, ornate=0.5,
                               table="alto", vowels=("o", "u"), vib=0.25),
                "duduk": dict(gain=0.35, every=8, offset=5, len=3, lo=7, hi=14, ornate=0.5),
                "scrape": dict(gain=0.1, count=3)},
        drums={"f": (["X.....x.....x...", "X.....x...o.x...", "X.....x.....x.o.", "X..o..x.....x..."], 0.4),
               "c": (["..x...x...x...x.", "..x...x.?.x...x."], 0.12),
               "T": (["X...............", "................", "........x.......", "................"], 0.55)},
    ),
    # Jardim Primordial: vida. Sol lídio, bordão de duduk, cordas leves, chocalhos
    # irregulares, voz clara.
    "jardim_primordial": dict(
        seed=107, bpm=88, key="G", scale="lydian", bars=18, prog=[0, 1, 4, 3], chord_bars=2,
        rt=4.0, rev=0.65, loud=-15.0,
        layers={"sub": dict(gain=0.38, swells=4), "reed": dict(gain=0.16, table="reed"),
                "pluck": dict(gain=0.2, step=0.5, pattern=[0, None, 4, 2, None, 7, 4, None], skip=0.15, bright=0.5),
                "voice": dict(gain=0.45, every=4, offset=1, len=3, lo=14, hi=22, ornate=0.5, vowels=("a", "o", "e")),
                "shimmer": dict(gain=0.12, density=0.15), "wind": dict(gain=0.08, center=900)},
        drums={"r": (["x.xx.x.xx.x.x.xx", "x.x?.x.xx.x?x.x.", "x.xx.x.x?.x.xxx."], 0.22),
               "f": (["X.......x..o....", "X.......x.....o.", "X..o....x..o....", "X.......x......."], 0.32),
               "T": (["X...............", "................", "................", "........o......."], 0.45)},
    ),
    # Carcosa: a máscara. Si bemol lócrio, trítono e segunda menor no grave,
    # BRAAM em cacho dissonante, voz que escorrega, muitas raspagens, gongo.
    "carcosa": dict(
        seed=108, bpm=80, key="Bb", scale="locrian", bars=16, prog=[0, 1, 4, 1], chord_bars=4,
        rt=6.5, rev=0.8, loud=-15.5,
        layers={"sub": dict(gain=0.45, swells=4, cluster=0.25), "throat": dict(gain=0.24, shift=6, growl=0.45),
                "braam": dict(gain=0.6, every=4, offset=2, dur=6, voicing=(0, 1, 6, 12)),
                "voice": dict(gain=0.4, every=8, offset=1, len=5, lo=13, hi=20, ornate=0.35, vowels=("o", "u", "a"),
                              vib=0.55),
                "scrape": dict(gain=0.22, count=7, freq=(120, 380))},
        drums={"T": (["X..........x....", "................", "......x.........", "X...............",
                      "................", "..........x..x..", "................", "X.....o........."], 0.6),
               "m": (["................", "........x.......", "................", "................"], 0.3)},
    ),
    # Observatório Celeste: as estrelas. Fá sustenido lídio, arpejo rápido de
    # cordas, vidro, relógio de baquetas, voz bem aguda.
    "observatorio": dict(
        seed=109, bpm=100, key="F#", scale="lydian", bars=20, prog=[0, 4, 5, 1], chord_bars=2,
        rt=5.0, rev=0.7, loud=-15.0,
        layers={"sub": dict(gain=0.4, swells=5), "throat": dict(gain=0.12, overtones=(12, 15, 16, 18, 16, 15)),
                "pluck": dict(gain=0.2, step=0.25, pattern=[0, 2, 4, 7, 9, 7, 4, 2], accents=(0, 4), octave=2, bright=0.4),
                "bells": dict(gain=0.2, kind="glass", every=2, beats=[0, 3], octave=3),
                "voice": dict(gain=0.4, every=4, offset=2, len=2, lo=16, hi=23, ornate=0.5, vowels=("i", "e", "a")),
                "shimmer": dict(gain=0.14, density=0.2)},
        drums={"c": (["x...x...x...x...", "x...x...x...x.?."], 0.12),
               "T": (["X.........x.....", "................", "X...............", "......o........."], 0.5)},
    ),
    # Guardiões: a luta. Ré menor harmônica, taikos em grupos de 3, BRAAM a cada
    # 2 compassos, gutural, gritos da voz.
    "chefe": dict(
        seed=110, shelf=0.32, bpm=150, key="D", scale="harmonic", bars=32, prog=[0, 5, 6, 4], chord_bars=2,
        rt=2.8, rev=0.45, loud=-12.0,
        layers={"sub": dict(gain=0.32, swells=8), "throat": dict(gain=0.28, growl=0.5),
                "braam": dict(gain=0.6, every=2, dur=2.5, voicing=(0, 12, 19)),
                "voice": dict(gain=0.4, every=8, offset=4, len=3, lo=15, hi=22, ornate=0.7),
                "scrape": dict(gain=0.14, count=6)},
        drums={"T": (["X..x..x...X..x..", "X..x..x...X.x.x.", "X..x..x...X..x..", "X..x..x.x.x.x.x."], 0.42),
               "t": (["....x.......x...", "....x..o....x..o", "....x.......x.x.", "o.o.x.o.o.x.xxxx"], 0.45),
               "f": (["x.o.x.o?x.o.x.o?", "x.o?x.o.x.o?x.oo"], 0.22),
               "m": (["X...............", "", "", ""], 0.25),
               "B": (["X...............", "", "", "", "", "", "", ""], 0.65)},
    ),
    # O Trono: tudo de uma vez. Mi frígio dominante, coro, voz, BRAAMs, golpes.
    "chefe_final": dict(
        seed=111, shelf=0.32, bpm=140, key="E", scale="phrygdom", bars=32, prog=[0, 1, 0, 6], chord_bars=2,
        rt=3.4, rev=0.5, loud=-11.5,
        layers={"sub": dict(gain=0.32, swells=8, fifth=0.3), "throat": dict(gain=0.28, growl=0.55),
                "braam": dict(gain=0.62, every=2, dur=3, voicing=(0, 12, 19, 24), bright=1.2),
                "choir": dict(gain=0.22, table="bass", octave=1, vowels=["a", "o"], voicing=(0, 2, 4, 7)),
                "voice": dict(gain=0.42, every=4, offset=2, len=2, lo=15, hi=23, ornate=0.75),
                "scrape": dict(gain=0.14, count=6)},
        drums={"T": (["X..x..x.X..x..x.", "X..x..x.X..x.x.x", "X..x..x.X..x..x.", "X.x.x..xX.x.x.xx"], 0.42),
               "t": (["....x.......x...", "....x..o....x..o", "....x.......x.x.", "o.o.x.o.x.x.xxxx"], 0.45),
               "f": (["x.ox.ox.x.ox.ox.", "x.ox.ox.x.o?x.ox"], 0.2),
               "B": (["X...............", "", "", ""], 0.6),
               "m": (["................", "........X.......", "", ""], 0.2)},
    ),

    # --- domínios novos ------------------------------------------------------------------
    # Necrópole: o deus que lembrava os mortos. Dó menor, 60 bpm, coro grave em
    # "o/u", sino de igreja dobrando, drone.
    "necropole": dict(
        seed=112, bpm=60, key="C", scale="minor", bars=12, prog=[0, 5, 3, 4], chord_bars=3,
        rt=6.5, rev=0.8, loud=-16.0,
        layers={"sub": dict(gain=0.5, swells=3, fifth=0.25),
                "choir": dict(gain=0.42, table="bass", octave=1, vowels=["o", "u", "o"], voicing=(0, 2, 4, 7)),
                "bells": dict(gain=0.32, kind="church", every=2, beats=[0], octave=1, degs=[0]),
                "voice": dict(gain=0.28, at=[7], len=4, lo=12, hi=18, ornate=0.4, vowels=("u", "o"), table="alto"),
                "wind": dict(gain=0.08, center=380), "scrape": dict(gain=0.08, count=2, freq=(150, 260))},
        drums={"T": (["X...............", "................", "........o.......", "................"], 0.45)},
    ),
    # Catedral Submersa: o deus que ouvia as preces. Sol dórico, 70 bpm, órgão
    # e voz, tudo "debaixo d'água" (agudos abafados), sala enorme.
    "catedral": dict(
        seed=113, bpm=70, key="G", scale="dorian", bars=14, prog=[0, 3, 0, 6], chord_bars=2,
        rt=7.5, rev=0.85, loud=-16.0, master_lp=4200,
        layers={"sub": dict(gain=0.42, swells=3), "organ": dict(gain=0.45),
                "voice": dict(gain=0.45, every=4, offset=1, len=3, lo=14, hi=21, ornate=0.45, vowels=("a", "o", "u")),
                "bells": dict(gain=0.2, kind="church", every=4, offset=2, beats=[0], octave=2, degs=[0, 4]),
                "scrape": dict(gain=0.07, count=2, freq=(200, 320))},
        drums={"T": (["X...............", "................", "................", "........o......."], 0.35)},
    ),
    # O Ventre: o deus que devorava. Dó sustenido frígio, 90 bpm, coração
    # batendo, segunda menor no grave, BRAAM em cacho, gutural rosnando.
    "ventre": dict(
        seed=114, shelf=0.32, bpm=90, key="C#", scale="phrygian", bars=18, prog=[0, 1, 0, 4], chord_bars=2,
        rt=2.6, rev=0.6, loud=-14.0, master_lp=6000,
        layers={"sub": dict(gain=0.4, swells=6, cluster=0.35), "throat": dict(gain=0.32, growl=0.7, shift=1),
                "braam": dict(gain=0.55, every=4, offset=1, dur=5, voicing=(0, 1, 12, 13), bright=0.7),
                "voice": dict(gain=0.28, every=6, offset=3, len=3, lo=10, hi=16, ornate=0.3, vowels=("u", "o"),
                              table="alto", vib=0.6),
                "scrape": dict(gain=0.16, count=5, freq=(90, 200))},
        drums={"h": (["X...x...X...x...", "X...x...X...x...", "X...x...X...x.x.", "X...x...X...x..."], 0.5),
               "T": (["................", "......x.........", "...........x....", "X...........o..."], 0.5),
               "d": (["..o.......o.....", "..........o...o.", "..o.............", "......o...o....."], 0.3)},
    ),
    # Penhascos do Sonho: o deus que sonhava. Lá lídio, 84 bpm, voz bem aguda,
    # brilho de vidro, harpa lenta, vento alto.
    "penhascos": dict(
        seed=115, bpm=84, key="A", scale="lydian", bars=16, prog=[0, 1, 4, 1], chord_bars=2,
        rt=6.0, rev=0.85, loud=-16.0,
        layers={"sub": dict(gain=0.35, swells=4), "reed": dict(gain=0.08, table="reed", octave=1),
                "voice": dict(gain=0.45, every=4, offset=0, len=3, lo=16, hi=23, ornate=0.55, vowels=("a", "i", "e")),
                "pluck": dict(gain=0.16, step=0.5, pattern=[0, 4, 7, 11, 9, 7, 4, 2], octave=2, bright=0.35, ring=2.2),
                "shimmer": dict(gain=0.18, density=0.3), "wind": dict(gain=0.14, center=1400)},
        drums={"f": (["X...............", "........o.......", "X...............", "......o...o....."], 0.25)},
    ),
    # Cavernas Fundas: o deus que se escondia. Si lócrio, 76 bpm, gotas e
    # metal pingando, drone fundo, gutural escuro.
    "cavernas": dict(
        seed=116, bpm=76, key="B", scale="locrian", bars=16, prog=[0, 1, 0, 4], chord_bars=4,
        rt=5.5, rev=0.85, loud=-16.0,
        layers={"sub": dict(gain=0.4, swells=4, cluster=0.15), "throat": dict(gain=0.2, growl=0.4),
                "braam": dict(gain=0.45, every=8, offset=4, dur=6, voicing=(0, 6, 12), bright=0.7),
                "voice": dict(gain=0.28, every=8, offset=2, len=3, lo=12, hi=18, ornate=0.4, vowels=("u", "o"),
                              table="alto"),
                "scrape": dict(gain=0.15, count=4, freq=(250, 600))},
        drums={"w": (["x.....?.....?...", "...?....x.....?.", "?.......?...x...", "......x....?...?"], 0.35),
               "c": (["........?.......", "..?...........?."], 0.15),
               "m": (["................", "", "x...............", ""], 0.18),
               "T": (["X...............", "................", "................", "..........o....."], 0.5)},
    ),
    # Bosque Errante: o deus que caminhava. Sol Hijaz, 104 bpm em 7/8
    # (2+2+3), cordas em ostinato de viagem, bordão de gaita, duduk, voz.
    "bosque": dict(
        seed=117, bpm=104, key="G", scale="hijaz", meter=3.5, bars=26, prog=[0, 0, 6, 1], chord_bars=2,
        rt=3.0, rev=0.55, loud=-14.5,
        layers={"sub": dict(gain=0.38, swells=6), "reed": dict(gain=0.2),
                "pluck": dict(gain=0.26, step=0.5, pattern=[0, 1, 2, 1, 4, 2, 1], accents=(0, 2, 4), follow=True),
                "duduk": dict(gain=0.48, every=4, offset=1, len=2, lo=7, hi=14, ornate=0.6),
                "voice": dict(gain=0.38, every=8, offset=5, len=2, lo=14, hi=21, ornate=0.65),
                "wind": dict(gain=0.06, center=700)},
        drums={"d": (["X...x.........", "X...x...x.....", "X...x.........", "X...x...x...o."], 0.45),
               "k": (["..o...o.o.o.o.", "..o.?.o.o.o...", "..o...o.o?o.o.", "..o...o.oooo.o"], 0.22),
               "f": (["X...X...X.....", "X...X...X...o."], 0.3),
               "r": (["x.x.x.x.x.x.x.", "x.?.x.x.x.?.x."], 0.12),
               "T": (["X.............", "..............", "..............", "........o....."], 0.45)},
    ),
}

if __name__ == "__main__":
    only = sys.argv[1:]
    for name, recipe in TRACKS.items():
        if only and name not in only:
            continue
        x = render(recipe)
        save(name, x)
        print("%-18s %5.1f s  %3d bpm  %s %s" % (name, len(x) / SR, recipe["bpm"], recipe["key"], recipe["scale"]),
              flush=True)
