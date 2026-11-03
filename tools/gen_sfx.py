"""Gera os efeitos sonoros provisórios (assets/sfx/*.wav) por síntese.

Cada som é uma receita curta: onda (quadrada, triângulo, ruído), varredura de
frequência e envelope. Quando houver sons de verdade, é só pôr .wav com os
mesmos nomes em assets/sfx/ e apagar este script.

    python tools/gen_sfx.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")
random.seed(7)


def osc(kind, phase):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "pulse":
        return 1.0 if p < 0.25 else -1.0
    if kind == "tri":
        return 4.0 * abs(p - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    return math.sin(2 * math.pi * p)


def tone(dur, f0, f1, kind="square", vol=0.5, attack=0.005, curve=1.0, vibrato=0.0):
    n = int(dur * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * (t ** curve)
        if vibrato:
            f *= 1.0 + vibrato * math.sin(i / RATE * 2 * math.pi * 9)
        phase += f / RATE
        env = min(1.0, i / max(1, attack * RATE)) * (1.0 - t) ** 1.6
        out.append(osc(kind, phase) * env * vol)
    return out


def noise(dur, vol=0.5, smooth=0.0, decay=1.6, attack=0.002):
    n = int(dur * RATE)
    out, last = [], 0.0
    for i in range(n):
        t = i / n
        raw = random.uniform(-1, 1)
        last = last * smooth + raw * (1 - smooth)
        env = min(1.0, i / max(1, attack * RATE)) * (1.0 - t) ** decay
        out.append(last * env * vol)
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * RATE) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * length
    for t, o in zip(tracks, offsets):
        start = int(o * RATE)
        for i, v in enumerate(t):
            out[start + i] += v
    return out


def seq(*parts):
    out = []
    for p in parts:
        out += p
    return out


def save(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = min(1.0, 0.95 / peak)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32000)) for s in samples))


SOUNDS = {
    "jump": lambda: tone(0.12, 220, 520, "square", 0.25, curve=0.6),
    "land": lambda: noise(0.08, 0.5, smooth=0.85),
    "roll": lambda: noise(0.22, 0.35, smooth=0.7, decay=1.0),
    "swing": lambda: noise(0.1, 0.45, smooth=0.4, decay=2.2),
    "swing_heavy": lambda: mix(noise(0.18, 0.5, smooth=0.75, decay=1.5), tone(0.18, 140, 70, "tri", 0.3)),
    "hit": lambda: mix(noise(0.07, 0.6, smooth=0.3), tone(0.07, 300, 120, "square", 0.3)),
    "crit": lambda: mix(noise(0.12, 0.6, smooth=0.2), tone(0.14, 880, 330, "square", 0.35), tone(0.1, 1320, 660, "pulse", 0.2)),
    "hurt": lambda: mix(tone(0.2, 400, 90, "saw", 0.4), noise(0.15, 0.4, smooth=0.5)),
    "death": lambda: seq(tone(0.25, 330, 110, "square", 0.4), tone(0.5, 110, 40, "tri", 0.5)),
    "enemy_die": lambda: mix(noise(0.25, 0.5, smooth=0.6), tone(0.2, 260, 60, "square", 0.3)),
    "bow": lambda: mix(tone(0.08, 900, 300, "tri", 0.3), noise(0.06, 0.2, smooth=0.2)),
    "throw": lambda: noise(0.12, 0.3, smooth=0.5, decay=1.2),
    "boom": lambda: mix(noise(0.6, 0.9, smooth=0.9, decay=1.8), tone(0.4, 90, 30, "tri", 0.6)),
    "block": lambda: mix(tone(0.08, 1200, 1100, "square", 0.3), noise(0.05, 0.3, smooth=0.1)),
    "parry": lambda: mix(tone(0.25, 1600, 1500, "tri", 0.4, vibrato=0.01), tone(0.25, 2400, 2300, "sine", 0.25), noise(0.06, 0.4)),
    "shield_up": lambda: tone(0.06, 500, 700, "square", 0.2),
    "drink": lambda: seq(tone(0.08, 400, 600, "sine", 0.3), tone(0.08, 500, 750, "sine", 0.3), tone(0.12, 600, 900, "sine", 0.3)),
    "pickup": lambda: seq(tone(0.07, 520, 520, "square", 0.25), tone(0.12, 780, 780, "square", 0.25)),
    "essence": lambda: tone(0.06, 1400, 1900, "sine", 0.3),
    "fragment": lambda: seq(tone(0.1, 392, 392, "tri", 0.35), tone(0.1, 523, 523, "tri", 0.35), tone(0.25, 784, 784, "tri", 0.35)),
    "unlock": lambda: seq(tone(0.08, 523, 523, "pulse", 0.25), tone(0.08, 659, 659, "pulse", 0.25), tone(0.2, 1046, 1046, "pulse", 0.25)),
    "secret": lambda: seq(tone(0.12, 330, 330, "tri", 0.3), tone(0.12, 415, 415, "tri", 0.3), tone(0.3, 494, 494, "tri", 0.3)),
    "page": lambda: noise(0.15, 0.25, smooth=0.3, decay=0.8),
    "portal": lambda: tone(0.6, 200, 900, "tri", 0.4, curve=0.5, vibrato=0.03),
    "slam": lambda: mix(noise(0.3, 0.8, smooth=0.85), tone(0.25, 120, 40, "square", 0.4)),
    "fuse": lambda: noise(0.6, 0.25, smooth=0.1, decay=0.3),
    "burrow": lambda: noise(0.3, 0.4, smooth=0.92, decay=1.0),
    "crack": lambda: mix(tone(0.15, 2200, 1800, "pulse", 0.15), noise(0.15, 0.2, smooth=0.05, decay=0.8)),
    "spike": lambda: mix(tone(0.2, 1800, 600, "saw", 0.3), noise(0.15, 0.4, smooth=0.1)),
    "omen": lambda: tone(0.5, 600, 620, "sine", 0.3, attack=0.1, vibrato=0.02),
    "pillar": lambda: mix(tone(0.4, 880, 220, "tri", 0.4), noise(0.3, 0.4, smooth=0.6)),
    "roar": lambda: mix(tone(0.9, 90, 60, "saw", 0.5, vibrato=0.05), noise(0.9, 0.4, smooth=0.9, decay=1.0)),
    "boss_die": lambda: mix(noise(1.6, 0.8, smooth=0.9, decay=1.2), tone(1.6, 200, 30, "tri", 0.5), tone(1.2, 900, 1800, "sine", 0.2)),
    "wind": lambda: noise(2.5, 0.35, smooth=0.97, decay=0.6, attack=0.6),
    "ui_open": lambda: tone(0.06, 440, 660, "pulse", 0.15),
    "ui_ok": lambda: seq(tone(0.05, 660, 660, "pulse", 0.2), tone(0.08, 990, 990, "pulse", 0.2)),
    "ui_move": lambda: tone(0.03, 880, 880, "pulse", 0.12),
    # habilidades
    "trap_set": lambda: seq(tone(0.04, 1800, 1700, "pulse", 0.2), tone(0.05, 1400, 1300, "pulse", 0.2), noise(0.06, 0.2, smooth=0.1)),
    "trap_cut": lambda: mix(tone(0.06, 2400, 1200, "saw", 0.18), noise(0.05, 0.2, smooth=0.05)),
    "turret_shot": lambda: mix(tone(0.08, 2200, 1600, "sine", 0.3), tone(0.05, 3300, 2400, "tri", 0.15)),
    "spirit_call": lambda: mix(tone(0.5, 300, 900, "sine", 0.3, attack=0.1, vibrato=0.03), noise(0.4, 0.15, smooth=0.95, decay=0.8)),
    "chain_throw": lambda: seq(*[tone(0.025, 1500 + 200 * (i % 2), 1400, "pulse", 0.15) for i in range(6)]),
    "chain_pull": lambda: mix(tone(0.15, 300, 120, "square", 0.3), noise(0.12, 0.35, smooth=0.3)),
    # inimigos novos
    "wolf_bite": lambda: mix(tone(0.12, 180, 90, "saw", 0.35, vibrato=0.08), noise(0.06, 0.5, smooth=0.2)),
    "howl": lambda: tone(1.2, 300, 520, "sine", 0.4, attack=0.2, curve=0.5, vibrato=0.04),
    "hammer_slam": lambda: mix(tone(0.5, 1180, 1150, "sine", 0.25), tone(0.5, 1730, 1700, "sine", 0.15), noise(0.4, 0.8, smooth=0.85), tone(0.3, 90, 35, "tri", 0.5)),
    "slag_hop": lambda: mix(tone(0.12, 120, 220, "sine", 0.35), noise(0.1, 0.25, smooth=0.9)),
    "glyph": lambda: seq(tone(0.07, 1320, 1320, "tri", 0.2), tone(0.07, 1760, 1760, "tri", 0.2), tone(0.12, 1480, 1480, "sine", 0.2)),
    "gargoyle_screech": lambda: tone(0.35, 1400, 700, "saw", 0.25, vibrato=0.06),
    "thorn_shoot": lambda: mix(noise(0.08, 0.35, smooth=0.3, decay=2.0), tone(0.08, 700, 300, "tri", 0.2)),
    "moss_charge": lambda: mix(noise(0.6, 0.5, smooth=0.95, decay=0.8), tone(0.5, 70, 50, "saw", 0.3)),
    "teleport": lambda: tone(0.25, 1800, 200, "sine", 0.3, curve=0.4, vibrato=0.05),
    "bell": lambda: mix(tone(1.4, 330, 330, "sine", 0.35), tone(1.2, 830, 830, "sine", 0.15), tone(0.8, 1650, 1650, "sine", 0.06)),
    "laser_charge": lambda: tone(0.7, 200, 1600, "pulse", 0.2, attack=0.2, curve=1.6),
    "laser_fire": lambda: mix(tone(0.35, 1600, 1500, "saw", 0.3), noise(0.35, 0.4, smooth=0.4)),
    "star_pop": lambda: mix(tone(0.2, 2000, 400, "sine", 0.35), noise(0.25, 0.5, smooth=0.5)),
    # chefes
    "boss_intro": lambda: seq(tone(0.3, 110, 110, "saw", 0.4), tone(0.3, 104, 104, "saw", 0.4), tone(0.9, 82, 70, "saw", 0.5, vibrato=0.02)),
    "boss_phase": lambda: mix(tone(0.9, 140, 60, "saw", 0.5, vibrato=0.06), noise(0.9, 0.5, smooth=0.9, decay=1.0), tone(0.6, 600, 1200, "sine", 0.15)),
    # mundo
    "coin": lambda: seq(tone(0.04, 1568, 1568, "pulse", 0.18), tone(0.08, 2093, 2093, "pulse", 0.18)),
    "blueprint": lambda: seq(noise(0.08, 0.2, smooth=0.3), tone(0.1, 660, 660, "tri", 0.3), tone(0.18, 990, 990, "tri", 0.3)),
    "rune": lambda: mix(tone(1.4, 220, 220, "sine", 0.3), tone(1.4, 330, 332, "sine", 0.25), tone(1.4, 440, 444, "sine", 0.2), tone(1.0, 880, 1760, "sine", 0.1, curve=0.5)),
    "mutation": lambda: mix(tone(0.5, 200, 400, "saw", 0.2, vibrato=0.05), tone(0.5, 300, 600, "sine", 0.2)),
    "merchant_buy": lambda: seq(tone(0.04, 1318, 1318, "pulse", 0.15), tone(0.04, 1568, 1568, "pulse", 0.15), tone(0.04, 1760, 1760, "pulse", 0.15), noise(0.08, 0.2, smooth=0.1)),
    "curse": lambda: mix(tone(0.9, 220, 110, "saw", 0.3, vibrato=0.04), tone(0.9, 233, 117, "saw", 0.25)),
    "door_close": lambda: seq(tone(0.1, 200, 180, "square", 0.3), noise(0.3, 0.5, smooth=0.9)),
    "wall_break": lambda: mix(noise(0.5, 0.9, smooth=0.7, decay=1.4), tone(0.3, 160, 50, "square", 0.4)),
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, make in SOUNDS.items():
        save(name, make())
    print(len(SOUNDS), "sons em", os.path.normpath(OUT))
