"""Camel Claus chiptune generator (numpy). Writes 16-bit mono WAVs into assets/audio/.

Music: "Jingle Bells" (James Lord Pierpont, 1857 - public domain melody), our own 8-bit
arrangement in two stems that play in sync: `music_base` (lead + bass + soft sleigh bells) and
`music_drive` (arpeggio + drums + more bells) that fades in for the final stretch.
Jingles: short rising/falling motifs for level-up, chest, win, lose, boss, and the Jingle Pulse bell.

Run: python art_src/tools/make_audio.py
"""
import os
import wave

import numpy as np

PROJ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SR = 22050
BPM = 140
BEAT = 60.0 / BPM
NOTE = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}


def freq(name):
    """'E5' -> Hz."""
    return 440.0 * 2 ** ((NOTE[name[:-1]] + 12 * (int(name[-1]) + 1) - 69) / 12)


def square(f, n, duty=0.5):
    phase = (np.arange(n) * f / SR) % 1.0
    return np.where(phase < duty, 1.0, -1.0)


def triangle(f, n):
    phase = (np.arange(n) * f / SR) % 1.0
    return 4.0 * np.abs(phase - 0.5) - 1.0


def env(n, attack=0.005, release=0.06, sustain=0.7):
    e = np.full(n, sustain)
    a, r = int(attack * SR), min(int(release * SR), n)
    e[:a] = np.linspace(0, 1, a) if a else e[:a]
    e[a:a + int(0.04 * SR)] = np.linspace(1, sustain, len(e[a:a + int(0.04 * SR)]))
    e[n - r:] *= np.linspace(1, 0, r)
    return e


def bell(n, rng, bright=1.0):
    """Sleigh-bell hit: high noise with a fast jingle tremolo and a quick decay."""
    t = np.arange(n) / SR
    noise = rng.uniform(-1, 1, n)
    noise = noise - np.concatenate([[0], noise[:-1]]) * 0.9  # crude high-pass
    trem = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 28 * t))
    return noise * trem * np.exp(-t * 14) * bright


def place(buf, start_s, sig):
    i = int(start_s * SR)
    if i >= len(buf):
        return
    sig = sig[:len(buf) - i]
    buf[i:i + len(sig)] += sig


# Chorus, 16 bars (note, beats). "R" = rest.
CHORUS_A = [("E5", 1), ("E5", 1), ("E5", 2), ("E5", 1), ("E5", 1), ("E5", 2),
            ("E5", 1), ("G5", 1), ("C5", 1.5), ("D5", 0.5), ("E5", 4),
            ("F5", 1), ("F5", 1), ("F5", 1.5), ("F5", 0.5), ("F5", 1), ("E5", 1), ("E5", 1), ("E5", 0.5), ("E5", 0.5),
            ("E5", 1), ("D5", 1), ("D5", 1), ("E5", 1), ("D5", 2), ("G5", 2)]
CHORUS_B = CHORUS_A[:11] + [
    ("F5", 1), ("F5", 1), ("F5", 1), ("F5", 1), ("F5", 1), ("E5", 1), ("E5", 1), ("E5", 0.5), ("E5", 0.5),
    ("G5", 1), ("G5", 1), ("F5", 1), ("D5", 1), ("C5", 4)]
MELODY = CHORUS_A + CHORUS_B  # 16 bars
CHORDS = ["C", "C", "C", "C", "F", "C", "G", "G", "C", "C", "C", "C", "F", "C", "G", "C"]
CHORD_TONES = {"C": ["C", "E", "G"], "F": ["F", "A", "C"], "G": ["G", "B", "D"]}
BARS = 32  # melody twice; second pass up an octave


def render_music():
    total = BARS * 4 * BEAT
    n = int((total + 2 * 4 * BEAT) * SR)  # one spare bar for tails, wrapped to the start
    base, drive = np.zeros(n), np.zeros(n)
    rng = np.random.default_rng(7)
    for rep in range(2):
        t = rep * 16 * 4 * BEAT
        for name, beats in MELODY:
            dur = beats * BEAT
            m = int(dur * SR * 0.92)
            note = name if rep == 0 else name[:-1] + str(int(name[-1]) + 1)
            duty = 0.25 if rep == 0 else 0.125
            place(base, t, square(freq(note), m, duty) * env(m) * 0.16)
            if rep == 1:  # soft harmony a third below on the second pass
                place(base, t, square(freq(name) * 2 ** (-4 / 12), m, 0.5) * env(m) * 0.05)
            t += dur
    for bar in range(BARS):
        chord = CHORDS[bar % 16]
        root, third, fifth = CHORD_TONES[chord]
        t0 = bar * 4 * BEAT
        for b in range(4):  # bass: root / fifth quarters
            m = int(BEAT * SR * 0.85)
            note = (root if b % 2 == 0 else fifth) + "3"
            place(base, t0 + b * BEAT, triangle(freq(note), m) * env(m, release=0.03) * 0.30)
            if b in (1, 3):
                place(base, t0 + b * BEAT, bell(int(0.3 * SR), rng, 0.10))
        for s in range(16):  # drive: 16th arpeggio + drums + 8th bells
            m = int(BEAT / 4 * SR * 0.8)
            note = [root, third, fifth, third][s % 4] + ("5" if s % 8 < 4 else "6")
            place(drive, t0 + s * BEAT / 4, square(freq(note), m, 0.125) * env(m, release=0.02) * 0.06)
        for b in range(4):
            if b in (0, 2):
                k = int(0.18 * SR)
                kt = np.arange(k) / SR
                kick = np.sin(2 * np.pi * np.cumsum(120 * np.exp(-kt * 30) + 45) / SR) * np.exp(-kt * 18)
                place(drive, t0 + b * BEAT, kick * 0.45)
            else:
                snare = rng.uniform(-1, 1, int(0.12 * SR)) * np.exp(-np.arange(int(0.12 * SR)) / SR * 30)
                place(drive, t0 + b * BEAT, snare * 0.16)
            for h in range(2):
                place(drive, t0 + (b + h * 0.5) * BEAT, bell(int(0.12 * SR), rng, 0.08))
    loop_n = int(total * SR)
    out = []
    for buf in (base, drive):
        tail = buf[loop_n:]
        buf = buf[:loop_n].copy()
        buf[:len(tail)] += tail  # wrap tails so the loop point is seamless
        out.append(buf)
    return out


def jingle(notes, step=0.09, duty=0.25, last_hold=3.0, bells=True, vol=0.3):
    rng = np.random.default_rng(3)
    total = step * (len(notes) + last_hold) + 0.4
    buf = np.zeros(int(total * SR))
    for i, name in enumerate(notes):
        hold = step * (last_hold if i == len(notes) - 1 else 1.0)
        m = int(hold * SR)
        place(buf, i * step, square(freq(name), m, duty) * env(m, release=min(0.08, hold / 2)) * vol)
    if bells:
        for i in range(0, len(notes), 2):
            place(buf, i * step, bell(int(0.25 * SR), rng, 0.15))
    return buf


def write(path, data):
    data = np.clip(data, -1, 1)
    peak = np.max(np.abs(data))
    if peak > 0.89:  # keep ~1 dB headroom
        data = data * 0.89 / peak
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((data * 32767).astype("<i2").tobytes())
    print(f"{os.path.relpath(path, PROJ)}: {len(data) / SR:.2f}s")


if __name__ == "__main__":
    base, drive = render_music()
    write(os.path.join(PROJ, "assets", "audio", "music", "music_base.wav"), base)
    write(os.path.join(PROJ, "assets", "audio", "music", "music_drive.wav"), drive)
    sfx = os.path.join(PROJ, "assets", "audio", "sfx")
    write(os.path.join(sfx, "jingle_levelup.wav"), jingle(["C5", "E5", "G5", "C6"], step=0.07))
    write(os.path.join(sfx, "jingle_chest.wav"), jingle(["G5", "C6", "E6", "G6", "C7"], step=0.06, duty=0.125))
    write(os.path.join(sfx, "jingle_win.wav"), jingle(["E5", "E5", "E5", "G5", "C5", "D5", "E5", "C6"], step=0.12, last_hold=5))
    write(os.path.join(sfx, "jingle_lose.wav"), jingle(["G4", "F4", "E4", "D4", "C4"], step=0.16, duty=0.5, last_hold=4, bells=False))
    write(os.path.join(sfx, "jingle_boss.wav"), jingle(["C3", "C#3", "C3", "G2"], step=0.18, duty=0.5, last_hold=4, bells=False, vol=0.4))
    rng = np.random.default_rng(11)
    write(os.path.join(sfx, "sfx_jingle_pulse.wav"), bell(int(0.35 * SR), rng, 0.7))
