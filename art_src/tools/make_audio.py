"""Camel Claus music + jingle generator (numpy). Writes 16-bit mono WAVs into assets/audio/.

Style (Quentin, 2026-11-11): modern, warm, cozy music with retro *flavour* - not harsh 8-bit.
Soft timbres only: music-box pluck, flute-like lead (sines, gentle vibrato), detuned pads, round bass,
soft kick/brush, filtered sleigh bells. Everything is low-passed and gets a light reverb. Rendered as a
circular buffer so the loop point is seamless (tails and reverb wrap to the start).

Melody: "Jingle Bells" verse + chorus (James Lord Pierpont, 1857 - public domain); arrangement ours.
Stems play in sync: `music_base` (whole song) and `music_drive` (soft drums, bells, arpeggio) that fades
in for the final stretch.

Run: python art_src/tools/make_audio.py
"""
import os
import wave

import numpy as np

PROJ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SR = 22050
BPM = 112
BEAT = 60.0 / BPM
BAR = 4 * BEAT
NOTE = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}
RNG = np.random.default_rng(7)


def freq(name):
    """'E5' -> Hz."""
    return 440.0 * 2 ** ((NOTE[name[:-1]] + 12 * (int(name[-1]) + 1) - 69) / 12)


def up(name, octaves=1):
    return name[:-1] + str(int(name[-1]) + octaves)


# --- Instruments (all return float arrays of n samples) ----------------------------------------
def sines(f, n, partials, detune=0.0):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k, amp in partials:
        out += amp * np.sin(2 * np.pi * f * k * (1 + detune) * t)
    return out


def pluck(f, n, decay=0.45):
    """Music box / celesta: sine-ish with a soft bright tick, exponential decay."""
    t = np.arange(n) / SR
    tone = sines(f, n, [(1, 1.0), (2, 0.25), (3, 0.06), (4.2, 0.05)])
    env = np.minimum(t / 0.004, 1.0) * np.exp(-t / decay)
    return tone * env


def lead(f, n):
    """Warm flute-like lead: odd harmonics rolled off fast, delayed gentle vibrato."""
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(np.maximum(t - 0.15, 0) / 0.2, 1)
    phase = 2 * np.pi * f * np.cumsum(vib) / SR
    tone = np.sin(phase) + 0.12 * np.sin(3 * phase) + 0.03 * np.sin(5 * phase)
    env = np.minimum(t / 0.03, 1.0) * (0.85 + 0.15 * np.exp(-t / 0.15))
    rel = min(int(0.09 * SR), n)
    env[n - rel:] *= np.linspace(1, 0, rel)
    return tone * env


def pad(names, n):
    """Soft detuned chord with slow attack/release."""
    t = np.arange(n) / SR
    out = np.zeros(n)
    for name in names:
        f = freq(name)
        for d in (-0.003, 0.0, 0.003):
            out += sines(f, n, [(1, 1.0), (2, 0.15)], detune=d)
    env = np.minimum(t / 0.35, 1.0)
    rel = min(int(0.5 * SR), n)
    env[n - rel:] *= np.linspace(1, 0, rel)
    return out * env / (3 * len(names))


def bass(f, n):
    t = np.arange(n) / SR
    tone = sines(f, n, [(1, 1.0), (2, 0.22), (3, 0.05)])
    env = np.minimum(t / 0.008, 1.0) * np.exp(-t / 0.55)
    rel = min(int(0.05 * SR), n)
    env[n - rel:] *= np.linspace(1, 0, rel)
    return tone * env


def kick(n=int(0.25 * SR)):
    t = np.arange(n) / SR
    f = 42 + 50 * np.exp(-t * 35)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 14)


def smooth_noise(n, width):
    """Noise low-passed by a moving average of `width` samples (softens hiss)."""
    noise = RNG.uniform(-1, 1, n + width)
    return np.convolve(noise, np.ones(width) / width, mode="valid")[:n]


def brush(n=int(0.16 * SR)):
    t = np.arange(n) / SR
    noise = smooth_noise(n, 3) - smooth_noise(n, 12)  # band-pass-ish
    return noise * np.exp(-t * 22)


def sleigh(n=int(0.22 * SR)):
    """Sleigh bell: band-limited shimmer with a jingle tremolo (no piercing top end)."""
    t = np.arange(n) / SR
    noise = smooth_noise(n, 2) - smooth_noise(n, 6)
    trem = 0.65 + 0.35 * np.sin(2 * np.pi * 26 * t)
    return noise * trem * np.exp(-t * 16)


# --- Song --------------------------------------------------------------------------------------
CHORD = {"C": ["C4", "E4", "G4"], "Am": ["A3", "C4", "E4"], "F": ["F3", "A3", "C4"],
         "G": ["G3", "B3", "D4"], "Dm": ["D4", "F4", "A4"]}
ROOT = {"C": "C3", "Am": "A2", "F": "F2", "G": "G2", "Dm": "D3"}

VERSE = [("G4", 1), ("E5", 1), ("D5", 1), ("C5", 1), ("G4", 3), ("G4", 0.5), ("G4", 0.5),
         ("G4", 1), ("E5", 1), ("D5", 1), ("C5", 1), ("A4", 4),
         ("A4", 1), ("F5", 1), ("E5", 1), ("D5", 1), ("B4", 4),
         ("G5", 1), ("G5", 1), ("F5", 1), ("D5", 1), ("E5", 4),
         ("G4", 1), ("E5", 1), ("D5", 1), ("C5", 1), ("G4", 4),
         ("G4", 1), ("E5", 1), ("D5", 1), ("C5", 1), ("A4", 3), ("A4", 1),
         ("A4", 1), ("F5", 1), ("E5", 1), ("D5", 1), ("G5", 1), ("G5", 1), ("G5", 1), ("G5", 1),
         ("A5", 1), ("G5", 1), ("F5", 1), ("D5", 1), ("C5", 2), ("G5", 2)]
VERSE_CHORDS = ["C", "C", "C", "F", "Dm", "G", "G", "C", "C", "C", "Am", "F", "F", "C", "G", "C"]
CHORUS = [("E5", 1), ("E5", 1), ("E5", 2), ("E5", 1), ("E5", 1), ("E5", 2),
          ("E5", 1), ("G5", 1), ("C5", 1.5), ("D5", 0.5), ("E5", 4),
          ("F5", 1), ("F5", 1), ("F5", 1.5), ("F5", 0.5), ("F5", 1), ("E5", 1), ("E5", 1), ("E5", 0.5), ("E5", 0.5),
          ("E5", 1), ("D5", 1), ("D5", 1), ("E5", 1), ("D5", 2), ("G5", 2),
          ("E5", 1), ("E5", 1), ("E5", 2), ("E5", 1), ("E5", 1), ("E5", 2),
          ("E5", 1), ("G5", 1), ("C5", 1.5), ("D5", 0.5), ("E5", 4),
          ("F5", 1), ("F5", 1), ("F5", 1), ("F5", 1), ("F5", 1), ("E5", 1), ("E5", 1), ("E5", 0.5), ("E5", 0.5),
          ("G5", 1), ("G5", 1), ("F5", 1), ("D5", 1), ("C5", 4)]
CHORUS_CHORDS = ["C", "C", "C", "C", "F", "C", "G", "G", "C", "C", "C", "Am", "F", "C", "G", "C"]
INTRO_CHORDS = ["C", "Am", "F", "G"]
INTERLUDE_CHORDS = ["C", "Am", "F", "G", "C", "Am", "Dm", "G"]


class Song:
    def __init__(self, bars):
        self.n = int(round(bars * BAR * SR))
        self.base = np.zeros(self.n)
        self.drive = np.zeros(self.n)

    def put(self, buf, start_s, sig):
        """Add `sig` at `start_s`, wrapping past the end to the start (seamless loop)."""
        i = int(start_s * SR) % self.n
        first = min(len(sig), self.n - i)
        buf[i:i + first] += sig[:first]
        if first < len(sig):
            rest = sig[first:]
            buf[:len(rest)] += rest

    def melody(self, buf, t0, notes, voice, vol, octave=0):
        t = t0
        for name, beats in notes:
            dur = beats * BEAT
            n = int(dur * SR * (0.95 if voice is lead else 1.0)) + (int(0.6 * SR) if voice is pluck else 0)
            self.put(buf, t, voice(freq(up(name, octave) if octave else name), n) * vol)
            t += dur

    def chords(self, t0, chords, pad_vol=0.12, bass_vol=0.32, walking=False, arp_vol=0.0):
        for b, ch in enumerate(chords):
            t = t0 + b * BAR
            self.put(self.base, t, pad(CHORD[ch], int(BAR * SR) + int(0.4 * SR)) * pad_vol)
            root = freq(ROOT[ch])
            beats = [0, 2] if not walking else [0, 1, 2, 3]
            for k in beats:
                f = root if k % 2 == 0 else root * 1.5
                self.put(self.base, t + k * BEAT, bass(f, int(BEAT * SR * (1.9 if not walking else 0.95))) * bass_vol)
            if arp_vol:
                tones = CHORD[ch] + [up(CHORD[ch][0])]
                for s in range(8):
                    self.put(self.base, t + s * BEAT / 2, pluck(freq(up(tones[s % 4])), int(0.7 * SR), 0.3) * arp_vol)

    def drive_layer(self, bars):
        for bar in range(bars):
            t = bar * BAR
            for b in range(4):
                if b in (0, 2):
                    self.put(self.drive, t + b * BEAT, kick() * 0.55)
                else:
                    self.put(self.drive, t + b * BEAT, brush() * 0.22)
                for h in range(2):
                    self.put(self.drive, t + (b + h * 0.5) * BEAT, sleigh() * (0.09 if h == 0 else 0.06))


def lowpass_and_reverb(buf, cutoff=7000.0, wet=0.16, decay_s=1.6):
    """Circular FFT processing: gentle low-pass + convolution reverb, so the loop stays seamless."""
    n = len(buf)
    spec = np.fft.rfft(buf)
    f = np.fft.rfftfreq(n, 1 / SR)
    spec *= 1.0 / np.sqrt(1.0 + (f / cutoff) ** 4)  # 2nd-order-ish roll-off, no harsh highs
    ir_n = int(decay_s * SR)
    t = np.arange(ir_n) / SR
    ir = smooth_noise(ir_n, 4) * np.exp(-t * 4.0 / decay_s)
    ir[: int(0.012 * SR)] = 0.0  # small pre-delay
    ir /= np.sqrt(np.sum(ir ** 2))
    ir_full = np.zeros(n)
    ir_full[:ir_n] = ir
    dry = np.fft.irfft(spec, n)
    wet_sig = np.fft.irfft(spec * np.fft.rfft(ir_full), n)
    return dry + wet * wet_sig


def render_music():
    bars = 4 + 16 + 16 + 8 + 16
    song = Song(bars)
    t = 0.0
    # Intro: pads + music-box arpeggio.
    song.chords(t, INTRO_CHORDS, pad_vol=0.14, arp_vol=0.05)
    t += 4 * BAR
    # Verse: flute lead, sparse music box.
    song.melody(song.base, t, VERSE, lead, 0.16)
    song.chords(t, VERSE_CHORDS, arp_vol=0.025)
    t += 16 * BAR
    # Chorus: music box lead doubled softly by the flute an octave down, walking bass, bells.
    song.melody(song.base, t, CHORUS, pluck, 0.22)
    song.melody(song.base, t, CHORUS, lead, 0.06, octave=-1)
    song.chords(t, CHORUS_CHORDS, walking=True)
    for bar in range(16):
        for b in (1, 3):
            song.put(song.base, t + bar * BAR + b * BEAT, sleigh() * 0.05)
    t += 16 * BAR
    # Interlude: calm pads and broken chords.
    song.chords(t, INTERLUDE_CHORDS, pad_vol=0.15, bass_vol=0.22, arp_vol=0.06)
    t += 8 * BAR
    # Chorus 2: flute lead + music-box harmony a third below.
    song.melody(song.base, t, CHORUS, lead, 0.15)
    harmony = [(n if n[:-1] not in NOTE else _third_below(n), d) for n, d in CHORUS]
    song.melody(song.base, t, harmony, pluck, 0.10)
    song.chords(t, CHORUS_CHORDS, walking=True, arp_vol=0.02)
    song.drive_layer(bars)
    # Drive also carries a soft 8th-note music-box arpeggio over the song's chords.
    all_chords = INTRO_CHORDS + VERSE_CHORDS + CHORUS_CHORDS + INTERLUDE_CHORDS + CHORUS_CHORDS
    for bar, ch in enumerate(all_chords):
        tones = CHORD[ch] + [up(CHORD[ch][1])]
        for s in range(8):
            song.put(song.drive, bar * BAR + s * BEAT / 2, pluck(freq(up(tones[s % 4])), int(0.5 * SR), 0.22) * 0.05)
    return lowpass_and_reverb(song.base), lowpass_and_reverb(song.drive, cutoff=4800.0, wet=0.12)


SCALE = ["C", "D", "E", "F", "G", "A", "B"]


def _third_below(name):
    i = SCALE.index(name[:-1])
    octave = int(name[-1]) - (1 if i < 2 else 0)
    return SCALE[(i - 2) % 7] + str(octave)


# --- Jingles: same soft palette -------------------------------------------------------------
def jingle(notes, step=0.09, hold=1.2, chord=None, bells=True, vol=0.5, voice=pluck):
    total = step * len(notes) + hold + 0.6
    buf = np.zeros(int(total * SR))
    for i, name in enumerate(notes):
        n = int((hold if i == len(notes) - 1 else 0.6) * SR)
        sig = voice(freq(name), n) * vol
        j = int(i * step * SR)
        buf[j:j + len(sig)] += sig[:len(buf) - j]
    if chord:
        sig = pad(chord, int((total - 0.2) * SR)) * vol * 0.6
        buf[:len(sig)] += sig
    if bells:
        for i in range(0, len(notes), 2):
            sig = sleigh() * 0.12
            j = int(i * step * SR)
            buf[j:j + len(sig)] += sig[:len(buf) - j]
    return buf


def write(path, data, peak_db=-3.0):
    data = np.asarray(data, dtype=float)
    peak = np.max(np.abs(data))
    if peak > 0:
        data = data * (10 ** (peak_db / 20) / peak)
    data = np.tanh(data * 1.1) / np.tanh(1.1)  # gentle soft clip safety
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(data, -1, 1) * 32767).astype("<i2").tobytes())
    rms = np.sqrt(np.mean(data ** 2))
    spec = np.abs(np.fft.rfft(data)) ** 2
    f = np.fft.rfftfreq(len(data), 1 / SR)
    high = spec[f > 4000].sum() / spec.sum()
    print(f"{os.path.relpath(path, PROJ)}: {len(data) / SR:.1f}s  rms {20 * np.log10(rms + 1e-9):.1f} dBFS  "
          f"energy >4 kHz {high * 100:.2f}%")


if __name__ == "__main__":
    base, drive = render_music()
    music = os.path.join(PROJ, "assets", "audio", "music")
    write(os.path.join(music, "music_base.wav"), base, peak_db=-4.0)
    write(os.path.join(music, "music_drive.wav"), drive, peak_db=-8.0)
    sfx = os.path.join(PROJ, "assets", "audio", "sfx")
    write(os.path.join(sfx, "jingle_levelup.wav"), jingle(["C5", "E5", "G5", "C6"], step=0.07, hold=0.9))
    write(os.path.join(sfx, "jingle_chest.wav"), jingle(["G5", "C6", "E6", "G6"], step=0.06, hold=1.0))
    write(os.path.join(sfx, "jingle_evolve.wav"),
          jingle(["C5", "E5", "G5", "C6", "E6", "G6", "C7"], step=0.07, hold=1.6, chord=CHORD["C"]))
    write(os.path.join(sfx, "jingle_win.wav"),
          jingle(["E5", "E5", "E5", "G5", "C5", "D5", "E5"], step=0.14, hold=2.0, chord=CHORD["C"], voice=lead, vol=0.35))
    write(os.path.join(sfx, "jingle_lose.wav"),
          jingle(["G4", "E4", "D4", "C4"], step=0.22, hold=1.8, chord=CHORD["Am"], bells=False))
    write(os.path.join(sfx, "jingle_boss.wav"),
          jingle(["A2", "C3", "E3", "D#3"], step=0.2, hold=1.6, chord=["A2", "C3", "E3"], bells=False, voice=bass, vol=0.8))
    write(os.path.join(sfx, "sfx_jingle_pulse.wav"), sleigh(int(0.35 * SR)) * 0.8 + pluck(freq("E6"), int(0.35 * SR), 0.12) * 0.3)
    # Phase 6.1 SFX (appended after the RNG users above so the existing renders stay identical).
    t = np.arange(int(0.3 * SR)) / SR
    thump = np.sin(2 * np.pi * (90 + 120 * np.exp(-t * 30)) * t) * np.exp(-t * 20)
    write(os.path.join(sfx, "sfx_splash.wav"), smooth_noise(len(t), 10) * np.exp(-t * 16) * 1.6 + thump * 0.6, peak_db=-6.0)
    write(os.path.join(sfx, "sfx_mine.wav"), pluck(freq("A6"), int(0.2 * SR), 0.05) + 0.5 * pluck(freq("E6"), int(0.2 * SR), 0.04), peak_db=-8.0)
    write(os.path.join(sfx, "sfx_magnet.wav"), jingle(["C5", "E5", "G5", "C6", "E6", "G6"], step=0.045, hold=0.6, vol=0.45))
    write(os.path.join(sfx, "sfx_heal.wav"), jingle(["G5", "C6"], step=0.12, hold=0.8, chord=["C4", "E4", "G4"], bells=False, voice=lead, vol=0.4))
    t = np.arange(int(0.32 * SR)) / SR
    write(os.path.join(sfx, "sfx_lob.wav"), (smooth_noise(len(t), 6) - smooth_noise(len(t), 30)) * np.sin(np.pi * t / t[-1]) ** 2, peak_db=-8.0)
    # Phase 6.2: Santa's Sleigh fly-by (bells + the public-domain "Jingle Bells" motif) and meter-ready chime.
    flyby = jingle(["E5", "E5", "E5", "E5", "E5", "E5", "E5", "G5", "C5", "D5", "E5"], step=0.12, hold=0.9, vol=0.4)
    for i in range(14):
        j = int(i * 0.1 * SR)
        sig = sleigh() * 0.25
        flyby[j:j + len(sig)] += sig[:len(flyby) - j]
    write(os.path.join(sfx, "sfx_sleigh.wav"), flyby)
    write(os.path.join(sfx, "sfx_santa_ready.wav"), jingle(["G5", "C6", "E6"], step=0.08, hold=0.7, vol=0.45), peak_db=-5.0)
