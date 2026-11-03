"""Trilhas do jogo, sintetizadas (nada gravado, nada de terceiros).

    python tools/gen_music.py            -> assets/music/<faixa>.wav

Cada faixa é composta a partir de uma receita: tempo, tônica, escala,
progressão de acordes e quais instrumentos tocam. A melodia sai de um
passeio aleatório (com semente fixa) que cai em nota do acorde nos tempos
fortes. O fim da faixa é dobrado sobre o começo, então o loop não estala.

Instrumentos: baixo triangular, pulso (melodia), pluck (arpejo), sino (FM),
pad (dente-de-serra desafinada e filtrada), coro (senos com vibrato),
percussão (bumbo, caixa, chimbal, tambor grave, bigorna).
"""
import math
import os
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
    "phrygdom": [0, 1, 4, 5, 7, 8, 10],
    "locrian": [0, 1, 3, 5, 6, 8, 10],
}
NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "Bb": 10, "B": 11}


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def env(n, a=0.005, d=0.1, s=0.6, r=0.1, hold=None):
    """ADSR em amostras; hold = duração do sustain (s)."""
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    h_n = max(0, n - a_n - d_n - r_n) if hold is None else int(hold * SR)
    e = np.concatenate([
        np.linspace(0, 1, max(a_n, 1), endpoint=False),
        np.linspace(1, s, max(d_n, 1), endpoint=False),
        np.full(h_n, s),
        np.linspace(s, 0, max(r_n, 1)),
    ])
    if len(e) < n:
        e = np.pad(e, (0, n - len(e)))
    return e[:n]


def lowpass(x, cutoff):
    a = math.exp(-2 * math.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def lowpass_fast(x, cutoff, passes=2):
    # filtro de média móvel (rápido em numpy) aproximando um passa-baixa
    k = max(1, int(SR / cutoff / 2))
    kernel = np.ones(k) / k
    for _ in range(passes):
        x = np.convolve(x, kernel, mode="same")
    return x


# --- vozes ----------------------------------------------------------------------------

def tri(f, n):
    t = np.arange(n) / SR
    return 2 * np.abs(2 * ((t * f) % 1) - 1) - 1


def pulse(f, n, duty=0.5, vib=0.0):
    t = np.arange(n) / SR
    phase = t * f + (vib * np.sin(2 * np.pi * 5.5 * t) * np.minimum(t * 3, 1)) / max(f, 1) * f * 0.01
    x = np.where((phase % 1) < duty, 1.0, -1.0)
    return lowpass_fast(x, 5500, 1)       # tira o chiado da quina da onda


def saw(f, n):
    t = np.arange(n) / SR
    return 2 * ((t * f) % 1) - 1


def sine(f, n, vib=0.0):
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t + vib * np.sin(2 * np.pi * 5 * t))


def bell(f, n):
    # agudo demais, a modulação passa do limite da amostragem e vira chiado
    while f > 1300:
        f /= 2
    t = np.arange(n) / SR
    mod = np.sin(2 * np.pi * f * 2.0 * t) * 1.4 * np.exp(-t * 6)
    return lowpass_fast(np.sin(2 * np.pi * f * t + mod) * np.exp(-t * 2.5), 4500, 1)


def noise(n, rng):
    return rng.uniform(-1, 1, n)


def drum(kind, rng):
    if kind == "kick":
        n = int(0.28 * SR)
        t = np.arange(n) / SR
        f = 110 * np.exp(-t * 18) + 42
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)
    if kind == "snare":
        n = int(0.2 * SR)
        t = np.arange(n) / SR
        return (noise(n, rng) * 0.7 + np.sin(2 * np.pi * 190 * t) * 0.4) * np.exp(-t * 18)
    if kind == "hat":
        n = int(0.05 * SR)
        x = noise(n, rng)
        x = x - lowpass_fast(x, 3000, 1)
        return x * np.exp(-np.arange(n) / SR * 70)
    if kind == "tom":
        n = int(0.35 * SR)
        t = np.arange(n) / SR
        f = 140 * np.exp(-t * 6) + 70
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7)
    if kind == "anvil":
        n = int(0.6 * SR)
        t = np.arange(n) / SR
        x = sum(np.sin(2 * np.pi * f * t) * w for f, w in ((1180, 0.5), (1730, 0.35), (2650, 0.25), (3990, 0.15)))
        return x * np.exp(-t * 7) + noise(n, rng) * np.exp(-t * 60) * 0.4
    if kind == "shaker":
        n = int(0.07 * SR)
        x = noise(n, rng)
        return (x - lowpass_fast(x, 5000, 1)) * env(n, 0.01, 0.03, 0.2, 0.03) * 0.6
    raise ValueError(kind)


# --- composição ------------------------------------------------------------------------

def render(r):
    rng = np.random.default_rng(r["seed"])
    beat = 60.0 / r["bpm"]
    bars = r.get("bars", 16)
    total = int(bars * 4 * beat * SR)
    tail = int(2.5 * SR)
    out = np.zeros(total + tail)
    root = 48 + NOTE[r["key"]]
    scale = SCALES[r["scale"]]
    prog = r["prog"]

    def degree(d, octave=0):
        return root + scale[d % 7] + 12 * (d // 7 + octave)

    def put(x, at_beat, gain):
        i = int(at_beat * beat * SR)
        j = min(i + len(x), len(out))
        out[i:j] += x[: j - i] * gain

    chord_len = r.get("chord_beats", 4)
    for bar in range(bars * 4 // chord_len):
        d = prog[bar % len(prog)]
        start = bar * chord_len
        dur = chord_len * beat
        n = int(dur * SR)
        triad = [degree(d), degree(d + 2), degree(d + 4)]
        if "pad" in r["inst"]:
            x = sum(saw(hz(m + 12), n) + saw(hz(m + 12) * 1.006, n) for m in triad) / 6
            x = lowpass_fast(x, r.get("pad_cut", 900)) * env(n, 0.6, 0.3, 0.8, 0.8)
            put(x, start, r["inst"]["pad"])
        if "choir" in r["inst"]:
            x = sum(sine(hz(m + 12), n, 0.6) + 0.4 * sine(hz(m + 24), n, 0.5) for m in triad) / 4
            put(x * env(n, 0.8, 0.2, 0.8, 1.0), start, r["inst"]["choir"])
        if "bass" in r["inst"]:
            for k, step in enumerate(r.get("bass_rhythm", [0, 2])):
                if step >= chord_len:
                    continue
                bn = int(beat * r.get("bass_len", 0.9) * SR)
                note = degree(d, -1) if k % 2 == 0 or not r.get("bass_octave") else degree(d, 0)
                x = tri(hz(note), bn) * env(bn, 0.005, 0.08, 0.7, 0.06)
                put(x, start + step, r["inst"]["bass"])
        if "arp" in r["inst"]:
            step = r.get("arp_step", 0.5)
            pattern = r.get("arp_pattern", [0, 1, 2, 1])
            t = 0.0
            k = 0
            while t < chord_len - 1e-6:
                m = triad[pattern[k % len(pattern)] % 3] + 12 * (1 + pattern[k % len(pattern)] // 3)
                an = int(step * beat * SR * 0.95)
                x = pulse(hz(m), an, 0.25) * env(an, 0.002, 0.08, 0.25, 0.05)
                put(x, start + t, r["inst"]["arp"])
                t += step
                k += 1
        if "bells" in r["inst"]:
            for b in r.get("bell_beats", [0]):
                if b < chord_len:
                    m = triad[int(rng.integers(0, 3))] + 24
                    put(bell(hz(m), int(3 * SR)), start + b, r["inst"]["bells"])

    # melodia: passeio aleatório na escala, cai em nota do acorde no começo do compasso
    if "lead" in r["inst"]:
        pos = 7
        t = 0.0
        rhythm = r.get("lead_rhythm", [1, 1, 0.5, 0.5, 1])
        k = 0
        while t < bars * 4 - 1e-6:
            length = rhythm[k % len(rhythm)]
            k += 1
            chord = prog[int(t // chord_len) % len(prog)]
            if abs(t % chord_len) < 1e-6:
                pos = chord + int(rng.choice([0, 2, 4])) + 7
            else:
                pos += int(rng.choice([-2, -1, -1, 1, 1, 2, 0]))
                pos = max(3, min(pos, 16))
            if rng.random() < r.get("rest", 0.2):
                t += length
                continue
            ln = int(length * beat * SR * 0.92)
            voice = r.get("lead_voice", "pulse")
            if voice == "pulse":
                x = pulse(hz(degree(pos)), ln, 0.33, vib=r.get("vib", 0.0)) * 0.6
            elif voice == "sine":
                x = sine(hz(degree(pos)), ln, vib=0.4)
            else:
                x = bell(hz(degree(pos) + 12), ln)
            x = x * env(ln, 0.01, 0.1, 0.6, min(0.15, length * beat * 0.4))
            put(x, t, r["inst"]["lead"])
            t += length

    # percussão: uma linha por instrumento, "x" = toca, "." = não, 16 passos por compasso
    for kind, (pattern, gain) in r.get("drums", {}).items():
        hit = drum(kind, rng)
        steps = len(pattern)
        for bar in range(bars):
            for s, ch in enumerate(pattern):
                if ch == "x" or (ch == "?" and rng.random() < 0.5):
                    put(hit, bar * 4 + s * 4 / steps, gain * (0.85 + 0.3 * rng.random()))

    # eco simples para dar espaço
    if r.get("echo", 0) > 0:
        d = int(beat * 0.75 * SR)
        wet = np.zeros_like(out)
        wet[d:] = out[:-d] * r["echo"]
        wet[2 * d:] += out[:-2 * d] * r["echo"] * 0.5
        out = out + wet

    # fecha o loop: o rabo (decaimentos) volta para o começo
    loop = out[:total].copy()
    loop[:tail] += out[total:total + tail]
    loop = lowpass_fast(loop, 7000, 1)     # tira o resto de chiado do mix
    loop = np.tanh(loop * 1.2)
    loop /= max(np.max(np.abs(loop)), 1e-6)
    k = 128                               # emenda: o fim encosta no começo
    loop[-k:] = loop[-k:] + (loop[0] - loop[-1]) * np.linspace(0, 1, k)
    return loop * 0.8


def save(name, x):
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


ROCK = {"kick": ("x.......x.......", 0.9), "snare": ("....x.......x...", 0.55), "hat": ("x.x.x.x.x.x.x.x.", 0.18)}

TRACKS = {
    "titulo": dict(seed=1, bpm=66, key="D", scale="minor", prog=[0, 5, 3, 4], bars=12,
                   inst={"pad": 0.5, "bells": 0.35, "bass": 0.35}, bell_beats=[0, 2.5], echo=0.35, pad_cut=700),
    "passagem": dict(seed=2, bpm=60, key="F", scale="lydian", prog=[0, 4, 1, 4], bars=10,
                     inst={"pad": 0.45, "bells": 0.3, "choir": 0.25}, bell_beats=[1], echo=0.4, pad_cut=650),
    "mar_de_cinzas": dict(seed=3, bpm=96, key="D", scale="phrygian", prog=[0, 1, 0, 6], bars=16,
                          inst={"bass": 0.55, "arp": 0.18, "lead": 0.32, "pad": 0.3},
                          bass_rhythm=[0, 1.5, 2, 3], lead_rhythm=[1, 0.5, 0.5, 1, 1], vib=6.0, rest=0.25,
                          drums={"tom": ("x.....x...x.....", 0.6), "shaker": ("..x...x...x...xx", 0.4)}, echo=0.25),
    "saloes": dict(seed=4, bpm=72, key="E", scale="minor", prog=[0, 5, 2, 6], bars=12,
                   inst={"bells": 0.42, "pad": 0.4, "bass": 0.35, "lead": 0.2}, lead_voice="bell",
                   lead_rhythm=[2, 1, 1], bell_beats=[0, 1.5, 3], rest=0.35,
                   drums={"kick": ("x...............", 0.5)}, echo=0.45, pad_cut=600),
    "forja_rubra": dict(seed=5, bpm=132, key="C", scale="harmonic", prog=[0, 0, 5, 4], bars=16,
                        inst={"bass": 0.6, "lead": 0.3, "arp": 0.15}, bass_rhythm=[0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5],
                        bass_len=0.45, lead_rhythm=[0.5, 0.5, 1, 0.5, 0.5, 1], vib=4.0,
                        drums={**ROCK, "anvil": ("x.......x...x...", 0.35)}, echo=0.15),
    "torre_babel": dict(seed=6, bpm=110, key="A", scale="dorian", prog=[0, 3, 6, 4], bars=16,
                        inst={"arp": 0.22, "choir": 0.3, "bass": 0.45, "lead": 0.25},
                        arp_step=1 / 3, arp_pattern=[0, 1, 2, 3, 2, 1], lead_voice="sine",
                        drums={"kick": ("x.....x.....x...", 0.6), "hat": ("..x...x...x...x.", 0.2)}, echo=0.25),
    "jardim_primordial": dict(seed=7, bpm=88, key="G", scale="lydian", prog=[0, 1, 4, 3], bars=16,
                              inst={"arp": 0.25, "pad": 0.35, "bass": 0.4, "lead": 0.25}, lead_voice="sine",
                              arp_pattern=[0, 2, 1, 3], drums={"shaker": ("x.xxx.xxx.xxx.xx", 0.35),
                                                               "tom": ("x.......x..x....", 0.45)}, echo=0.3),
    "carcosa": dict(seed=8, bpm=80, key="Bb", scale="locrian", prog=[0, 1, 4, 1], bars=12,
                    inst={"pad": 0.45, "lead": 0.28, "bass": 0.45, "choir": 0.2}, vib=12.0,
                    lead_rhythm=[1.5, 0.5, 2], rest=0.3, pad_cut=500,
                    drums={"kick": ("x..x............", 0.7)}, echo=0.45),
    "observatorio": dict(seed=9, bpm=100, key="F#", scale="lydian", prog=[0, 4, 5, 1], bars=16,
                         inst={"arp": 0.24, "bells": 0.35, "pad": 0.35, "bass": 0.35},
                         arp_step=0.25, arp_pattern=[0, 1, 2, 3, 4, 3, 2, 1], bell_beats=[0, 2],
                         drums={"hat": ("x...x...x...x...", 0.15), "kick": ("x.........x.....", 0.45)}, echo=0.35),
    "chefe": dict(seed=10, bpm=150, key="D", scale="harmonic", prog=[0, 5, 6, 4], bars=16,
                  inst={"bass": 0.6, "lead": 0.32, "arp": 0.18, "pad": 0.25},
                  bass_rhythm=[0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5], bass_len=0.45, bass_octave=True,
                  lead_rhythm=[0.5, 0.5, 0.5, 0.5, 1, 1], rest=0.1,
                  drums={"kick": ("x...x...x...x...", 0.9), "snare": ("....x.......x..x", 0.6),
                         "hat": ("xxxxxxxxxxxxxxxx", 0.12)}, echo=0.1),
    "chefe_final": dict(seed=11, bpm=140, key="E", scale="phrygdom", prog=[0, 1, 0, 6], bars=16,
                        inst={"bass": 0.6, "choir": 0.35, "lead": 0.3, "pad": 0.25},
                        bass_rhythm=[0, 0.75, 1.5, 2, 2.75, 3.5], bass_len=0.5,
                        lead_rhythm=[1, 0.5, 0.5, 1, 1], vib=5.0, rest=0.15,
                        drums={"kick": ("x..x..x.x..x..x.", 0.9), "snare": ("....x.......x...", 0.65),
                               "tom": ("............xxxx", 0.4)}, echo=0.15),
}

if __name__ == "__main__":
    import sys
    only = sys.argv[1:]
    for name, recipe in TRACKS.items():
        if only and name not in only:
            continue
        x = render(recipe)
        save(name, x)
        print("%-18s %5.1f s" % (name, len(x) / SR))
