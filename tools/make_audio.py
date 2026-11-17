"""Procedural audio for LIAR'S LEVEL. Everything is synthesized from scratch (no samples).
Run:  python tools/make_audio.py   -> writes ../audio/*.wav
"""
import os, wave, random
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
os.makedirs(OUT, exist_ok=True)


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def save(name, x, peak=0.8):
    x = np.asarray(x, dtype=np.float64)
    x = x - x.mean()  # remove DC offset (avoids clicks)
    m = np.max(np.abs(x)) if len(x) else 1.0
    if m > 0:
        x = x / m * peak
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def T(dur):
    return np.arange(int(dur * SR)) / SR


def osc(kind, f, dur, duty=0.5):
    """f: scalar or array of per-sample Hz."""
    n = int(dur * SR)
    f = np.full(n, f, dtype=np.float64) if np.isscalar(f) else np.asarray(f, dtype=np.float64)[:n]
    ph = np.cumsum(f) / SR
    fr = ph % 1.0
    if kind == "square":
        return np.where(fr < duty, 1.0, -1.0)
    if kind == "saw":
        return 2 * fr - 1
    if kind == "tri":
        return 4 * np.abs(fr - 0.5) - 1
    if kind == "sine":
        return np.sin(2 * np.pi * ph)
    raise ValueError(kind)


def noise(dur, seed=1):
    return np.random.RandomState(seed).uniform(-1, 1, int(dur * SR))


def adsr(n, a=0.005, d=0.05, s=0.6, r=0.05):
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    e = np.ones(n)
    a = min(a, n)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    d = min(d, max(0, n - a))
    if d > 0:
        e[a:a + d] = np.linspace(1, s, d)
    e[a + d:] = s
    r = min(r, n)
    if r > 0:
        e[n - r:] *= np.linspace(1, 0, r)
    return e


def decay(n, k):
    return np.exp(-np.arange(n) / SR * k)


def lowpass(x, a):
    """one-pole lowpass, a in (0,1]; smaller = darker. a can be array."""
    out = np.zeros_like(x)
    y = 0.0
    if np.isscalar(a):
        for i in range(len(x)):
            y += a * (x[i] - y)
            out[i] = y
    else:
        for i in range(len(x)):
            y += a[i] * (x[i] - y)
            out[i] = y
    return out


def sweep(f0, f1, dur, curve=1.0):
    t = np.linspace(0, 1, int(dur * SR)) ** curve
    return f0 + (f1 - f0) * t


def cat(*xs):
    return np.concatenate(xs)


def pad(x, n):
    return np.pad(x, (0, max(0, n - len(x))))[:n] if n >= len(x) else x


def silence(d):
    return np.zeros(int(d * SR))


# ------------------------------------------------------------------ SFX
def sfx_jump():
    f = sweep(280, 760, 0.16, 0.7)
    x = osc("square", f, 0.16, 0.35) * 0.6 + osc("tri", f * 0.5, 0.16) * 0.4
    return x * adsr(len(x), 0.002, 0.05, 0.5, 0.06)


def sfx_land():
    n = noise(0.07, 2)
    n = lowpass(n, 0.18) * decay(len(n), 45)
    s = osc("sine", sweep(140, 60, 0.07), 0.07) * decay(int(0.07 * SR), 25)
    return n * 1.4 + s


def sfx_die():
    # comedic "bonk + falling wah"
    pop = lowpass(noise(0.06, 3), 0.5) * decay(int(0.06 * SR), 60)
    f = sweep(520, 70, 0.42, 1.3) * (1 + 0.04 * np.sin(2 * np.pi * 18 * T(0.42)))
    w = osc("square", f, 0.42, 0.5) * 0.5 + osc("saw", f * 0.5, 0.42) * 0.3
    w = w * adsr(len(w), 0.003, 0.1, 0.7, 0.12)
    return cat(pop * 1.2, w)


def sfx_win():
    notes = [72, 76, 79, 84, 88]
    out = []
    for i, m in enumerate(notes):
        d = 0.09 if i < 4 else 0.35
        x = osc("square", mtof(m), d, 0.25) * 0.5 + osc("tri", mtof(m - 12), d) * 0.5
        out.append(x * adsr(len(x), 0.003, 0.04, 0.7, 0.05))
    return cat(*out)


def sfx_coin():
    a = osc("square", mtof(83), 0.07, 0.3)
    b = osc("square", mtof(88), 0.22, 0.3)
    return cat(a * adsr(len(a), 0.002, 0.03, 0.8, 0.01), b * adsr(len(b), 0.002, 0.06, 0.5, 0.12))


def sfx_spring():
    t = T(0.38)
    f = 190 + 700 * (1 - np.exp(-t * 9)) + 35 * np.sin(2 * np.pi * 22 * t)
    x = osc("sine", f, 0.38) * 0.7 + osc("tri", f * 2, 0.38) * 0.2
    return x * adsr(len(x), 0.004, 0.06, 0.6, 0.15)


def sfx_crumble():
    n = noise(0.45, 4)
    a = np.linspace(0.5, 0.08, len(n))
    n = lowpass(n, a) * decay(len(n), 5) * (0.6 + 0.4 * np.sin(2 * np.pi * 31 * T(0.45)))
    r = osc("sine", 55, 0.45) * decay(len(n), 4) * 0.5
    return n * 1.6 + r


def sfx_pop():  # hidden spike popping
    f = sweep(1500, 380, 0.09, 0.6)
    x = osc("saw", f, 0.09) * adsr(int(0.09 * SR), 0.001, 0.03, 0.5, 0.03)
    t = noise(0.03, 5) * decay(int(0.03 * SR), 80)
    return pad(x, len(x)) + pad(t, len(x)) * 0.8


def sfx_whoosh():
    n = noise(0.34, 6)
    a = 0.04 + 0.5 * np.sin(np.linspace(0, np.pi, len(n))) ** 2
    x = lowpass(n, a)
    return x * np.sin(np.linspace(0, np.pi, len(n))) * 1.5


def sfx_sting():
    # sad trombone: wah wah wah waaah
    seq = [(58, 0.2), (57, 0.2), (56, 0.2), (55, 0.7)]
    out = []
    for i, (m, d) in enumerate(seq):
        t = T(d)
        vib = 1 + (0.025 * np.sin(2 * np.pi * 6 * t) if i == 3 else 0)
        f = mtof(m) * vib * (1 - 0.02 * (t / d))
        x = osc("saw", f, d) * 0.7 + osc("square", f * 0.5, d, 0.4) * 0.3
        bright = 0.06 + 0.25 * np.sin(np.pi * np.minimum(1, t / d * (1.6 if i < 3 else 0.8)))
        x = lowpass(x, bright)
        out.append(x * adsr(len(x), 0.01, 0.05, 0.8, 0.06 if i < 3 else 0.25))
        if i < 3:
            out.append(silence(0.03))
    return cat(*out)


def sfx_button():
    a = osc("square", 520, 0.04, 0.5) * adsr(int(0.04 * SR), 0.001, 0.01, 0.8, 0.01)
    b = osc("square", 880, 0.09, 0.5) * adsr(int(0.09 * SR), 0.001, 0.02, 0.6, 0.05)
    return cat(a, b)


def sfx_fake():  # buzzer
    x = osc("square", 98, 0.34, 0.5) * 0.7 + osc("saw", 103, 0.34) * 0.5
    return x * adsr(len(x), 0.005, 0.05, 0.9, 0.08)


def sfx_click():
    x = osc("square", 760, 0.045, 0.4)
    return x * adsr(len(x), 0.001, 0.015, 0.6, 0.02)


def sfx_back():
    x = osc("square", sweep(600, 380, 0.07), 0.07, 0.4)
    return x * adsr(len(x), 0.001, 0.02, 0.6, 0.03)


def sfx_unlock():
    out = []
    for i, m in enumerate([67, 72, 76, 79, 84]):
        x = osc("tri", mtof(m), 0.08) * 0.8 + osc("square", mtof(m + 12), 0.08, 0.25) * 0.2
        out.append(x * adsr(len(x), 0.002, 0.03, 0.6, 0.03))
    last = osc("tri", mtof(88), 0.3) * adsr(int(0.3 * SR), 0.003, 0.06, 0.6, 0.2)
    return cat(*out, last)


def sfx_thud():
    n = lowpass(noise(0.25, 7), 0.08) * decay(int(0.25 * SR), 14)
    s = osc("sine", sweep(95, 38, 0.25), 0.25) * decay(int(0.25 * SR), 9)
    return n * 1.8 + s * 1.2


def sfx_reverse():
    t = T(0.5)
    f = 300 + 350 * np.sin(2 * np.pi * 3 * t) ** 2 + 200 * t
    x = osc("square", f, 0.5, 0.5) * 0.4 + osc("tri", f * 1.5, 0.5) * 0.4
    return x * adsr(len(x), 0.01, 0.1, 0.7, 0.15)


def sfx_sign():
    a = osc("square", 660, 0.05, 0.3) * adsr(int(0.05 * SR), 0.001, 0.01, 0.7, 0.02)
    b = osc("square", 990, 0.07, 0.3) * adsr(int(0.07 * SR), 0.001, 0.02, 0.6, 0.04)
    return cat(a, b) * 0.7


def sfx_laugh():
    out = []
    for i, m in enumerate([67, 65, 64, 62]):
        d = 0.085
        f = mtof(m) * (1 + 0.03 * np.sin(2 * np.pi * 30 * T(d)))
        x = lowpass(osc("saw", f, d), 0.22) * adsr(int(d * SR), 0.004, 0.03, 0.7, 0.03)
        out += [x, silence(0.05)]
    return cat(*out)


def sfx_rumble():
    n = noise(1.2, 9)
    a = 0.05 + 0.03 * np.sin(np.linspace(0, 20, len(n)))
    x = lowpass(n, a) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * T(1.2)))
    x = x * np.sin(np.linspace(0, np.pi, len(n))) ** 0.5
    return x * 2.0 + osc("sine", 48, 1.2) * 0.5


def sfx_tick():  # trap warning tick
    x = osc("square", 1100, 0.03, 0.2)
    return x * adsr(len(x), 0.001, 0.01, 0.4, 0.01) * 0.5


# ------------------------------------------------------------------ MUSIC
class Seq:
    def __init__(self, bpm, bars, swing=0.0):
        self.bpm = bpm
        self.sp = 60.0 / bpm / 4.0  # seconds per 16th
        self.steps = bars * 16
        self.swing = swing
        self.n = int(self.steps * self.sp * SR)
        self.buf = np.zeros(self.n + SR * 2)

    def when(self, step):
        s = step * self.sp
        if self.swing and int(step) % 2 == 1:
            s += self.sp * self.swing
        return int(s * SR)

    def add(self, step, x, gain=1.0):
        i = self.when(step)
        end = min(len(self.buf), i + len(x))
        self.buf[i:end] += x[:end - i] * gain

    def finish(self):
        b = self.buf
        out = b[:self.n].copy()
        tail = b[self.n:]
        out[:len(tail)] += tail[:len(out)]
        return out


def voice(wave_, midi, dur_steps, sp, vol=1.0, duty=0.5, vib=0.0, a=0.004, d=0.06, s=0.55, r=0.05, lp=None, detune=0.0):
    d_s = dur_steps * sp
    f = mtof(midi)
    t = T(d_s + r)
    fr = f * (1 + vib * np.sin(2 * np.pi * 5.5 * t))
    x = osc(wave_, fr, d_s + r, duty)
    if detune:
        x = 0.5 * x + 0.5 * osc(wave_, fr * (1 + detune), d_s + r, duty)
    x = x * adsr(len(x), a, d, s, r)
    if lp:
        x = lowpass(x, lp)
    return x * vol


def kick(sp):
    n = int(0.16 * SR)
    f = 130 * np.exp(-np.arange(n) / SR * 22) + 42
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * decay(n, 18)
    return x


def snare():
    n = int(0.12 * SR)
    x = noise(0.12, 11)
    x = np.diff(x, prepend=0) * decay(n, 28)
    x += np.sin(2 * np.pi * 190 * T(0.12)) * decay(n, 30) * 0.5
    return x * 0.8


def hat(open_=False):
    d = 0.16 if open_ else 0.035
    n = int(d * SR)
    x = np.diff(noise(d, 12), prepend=0)
    return x * decay(n, 14 if open_ else 90) * 0.5


def clave():
    d = 0.05
    x = np.sin(2 * np.pi * 1700 * T(d)) * decay(int(d * SR), 70)
    return x * 0.5


SCALES = {
    "min": [0, 2, 3, 5, 7, 8, 10],
    "maj": [0, 2, 4, 5, 7, 9, 11],
    "phr": [0, 1, 3, 5, 7, 8, 10],
    "hmin": [0, 2, 3, 5, 7, 8, 11],
}


def pluck(midi, dur_steps, sp, vol=1.0):
    """marimba / pizzicato: soft attack, fast decay, a little 2nd/3rd harmonic. Darker for higher notes."""
    d = dur_steps * sp + 0.3
    f = mtof(midi)
    t = T(d)
    k = 6.0 + (midi - 40) * 0.12
    x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 18) + 0.12 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t * 28)
    x *= np.exp(-t * k) * np.minimum(1.0, t / 0.004)
    return x * vol


def tuba(midi, dur_steps, sp, vol=1.0):
    d = dur_steps * sp + 0.05
    x = 0.7 * osc("tri", mtof(midi), d) + 0.5 * osc("sine", mtof(midi), d)
    x = lowpass(x, 0.16)
    return x * adsr(len(x), 0.012, 0.06, 0.55, 0.05) * vol


def bassoon(midi, dur_steps, sp, vol=1.0, womp=0.0):
    """muted deadpan lead: dark saw, slow vibrato, optional comic slide DOWN at the end (womp = semitones)"""
    d = dur_steps * sp + 0.06
    n = int(d * SR)
    f = mtof(midi) * (1 + 0.005 * np.sin(2 * np.pi * 4.8 * T(d)))
    if womp:
        ramp = np.clip((np.arange(n) / SR - (d - 0.22)) / 0.2, 0, 1)
        f = f[:n] * 2 ** (-(womp * ramp) / 12.0)
    x = 0.8 * osc("saw", f, d) + 0.3 * osc("sine", f, d)
    x = lowpass(x, 0.15)
    return x * adsr(len(x), 0.03, 0.08, 0.7, 0.05) * vol


def woodblock():
    d = 0.07
    t = T(d)
    return (np.sin(2 * np.pi * 540 * t) + 0.6 * np.sin(2 * np.pi * 810 * t)) * np.exp(-t * 55) * 0.5


def brush():
    d = 0.08
    n = int(d * SR)
    x = lowpass(noise(d, 5), 0.5)
    return x * decay(n, 30) * 0.3


def soft_kick():
    n = int(0.2 * SR)
    f = 95 * np.exp(-np.arange(n) / SR * 18) + 45
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * decay(n, 14)


def build_troll(name, bpm, root, scale, chords, bass="pizz", lead="bassoon", swing=0.0, seed=1, bars=8,
                drums="tiptoe", density=0.65, lead_oct=0, lead_vol=0.9):
    """Trolling music: deadpan low instruments, sneaky chromatic bass, comic slides, stop-time gaps. No bright leads."""
    rnd = random.Random(seed)
    q = Seq(bpm, bars, swing)
    sp = q.sp
    sc = SCALES[scale]

    def scale_note(deg, octave=0):
        return root + sc[deg % 7] + 12 * (deg // 7) + 12 * octave

    per_bar = []
    for c in chords:
        per_bar += [c] * (bars // len(chords))
    # ---- bass
    for b in range(bars):
        base = root + per_bar[b] - 24
        nxt = root + per_bar[(b + 1) % bars] - 24
        stop = (b == bars - 1)          # stop-time: the last bar goes quiet for its last beat, then the loop restarts
        if bass == "pizz":              # tiptoe walk, last note creeps in from a semitone below the next chord
            notes = [(0, 2, base), (4, 2, base + 7), (8, 2, base + 12 if b % 2 else base + 5), (12, 2, nxt - 1)]
        elif bass == "tick":            # nervous staccato with a wrong note
            notes = [(i, 1, base + (1 if (i == 14 and b % 2) else 0)) for i in (0, 2, 4, 6, 8, 10, 12, 14) if not (i == 6 and b % 4 == 3)]
        else:                           # tuba oompah
            notes = [(0, 3, base), (8, 3, base + 7)]
        for st, dur, m in notes:
            if stop and st >= 12:
                continue
            x = tuba(m, dur, sp, 0.32) if bass == "tuba" else pluck(m, dur, sp, 0.34)
            q.add(b * 16 + st, x)
        if bass == "tuba":              # off-beat chord stabs (low marimba chord)
            for st in (4, 12):
                if stop and st >= 12:
                    continue
                for iv in (0, 3 if scale != "maj" else 4, 7):
                    q.add(b * 16 + st, pluck(base + 24 + iv, 2, sp, 0.3))

    # ---- lead
    def motif():
        steps = []
        pos = 0
        deg = rnd.choice([0, 2])
        while pos < 32:
            dur = rnd.choice([1, 2, 2, 3, 4])
            if rnd.random() > density and pos % 4 == 0:
                pos += dur
                continue
            deg += rnd.choice([-2, -1, -1, 0, 1, 1, 2])
            deg = max(-3, min(4, deg))       # stays low
            steps.append((pos, dur, deg))
            pos += dur
        return steps

    mA, mB = motif(), motif()
    phrases = [mA, mA, mB, mA]
    for p in range(bars // 2):
        ph = phrases[p % 4]
        last = len(ph) - 1
        for i, (st, dur, deg) in enumerate(ph):
            if p == bars // 2 - 1 and st >= 24:
                continue                     # stop-time gap at the end of the loop
            m = scale_note(deg, lead_oct)
            if lead == "bassoon":
                womp = 3.0 if (i == last and p % 2 == 1) else 0.0
                x = bassoon(m, dur, sp, lead_vol, womp)
            else:
                x = pluck(m + 12, dur, sp, lead_vol * 1.1)
            q.add(p * 32 + st, x)
    # ---- percussion (soft, no snare crack)
    kk, wb, br = soft_kick(), woodblock(), brush()
    for b in range(bars):
        for i in range(16):
            s = b * 16 + i
            if b == bars - 1 and i >= 12:
                continue
            if drums == "tiptoe":
                if i in (0, 10):
                    q.add(s, kk, 0.55)
                if i in (4, 12):
                    q.add(s, wb, 0.7)
                if i % 2 == 0:
                    q.add(s, br, 0.5)
            elif drums == "march":
                if i in (0, 8):
                    q.add(s, kk, 0.6)
                if i in (4, 12):
                    q.add(s, wb, 0.8)
                if i % 4 == 2:
                    q.add(s, br, 0.5)
            else:                            # "tick": nervous clock
                if i % 4 == 0:
                    q.add(s, wb, 0.55)
                if i in (0, 8):
                    q.add(s, kk, 0.45)
                if i % 2 == 1:
                    q.add(s, br, 0.4)
    return q.finish()


def echo(x, delay=0.19, fb=0.32, mix=0.28):
    """simple feedback delay for warmth; wraps around so loops stay seamless"""
    d = int(delay * SR)
    y = x.copy()
    for k in range(1, 5):
        y += mix * (fb ** (k - 1)) * np.roll(x, d * k)
    return y


def master(x, peak=0.7):
    x = echo(x)
    x = np.tanh(x * 1.1)
    return x


def make_music():
    T_ = {}
    # menu: tiptoeing, innocent-looking (A minor, muted bassoon over pizzicato)
    T_["music_menu"] = build_troll("menu", 96, 57, "min", [0, 0, -4, -5], bass="pizz", lead="bassoon", seed=7, drums="tiptoe", density=0.55)
    # world 1: "totally safe" lounge in F major, marimba
    T_["music_w1"] = build_troll("w1", 108, 53, "maj", [0, -5, -3, -7], bass="pizz", lead="marimba", seed=21, swing=0.18, drums="tiptoe", density=0.6)
    # world 2: nervous clock in D minor
    T_["music_w2"] = build_troll("w2", 118, 50, "min", [0, -4, -7, -2], bass="tick", lead="bassoon", seed=33, drums="tick", density=0.6)
    # world 3: slippery swing (E phrygian)
    T_["music_w3"] = build_troll("w3", 100, 52, "phr", [0, -4, -7, -5], bass="pizz", lead="bassoon", seed=45, swing=0.34, drums="tiptoe", density=0.65)
    # world 4: clumsy chaos march (F# harmonic minor), tuba oompah
    T_["music_w4"] = build_troll("w4", 128, 54, "hmin", [0, -4, -7, -2], bass="tuba", lead="marimba", seed=58, drums="march", density=0.7)
    # world 5: dark comedy (slow, creeping)
    T_["music_w5"] = build_troll("w5", 90, 53, "phr", [0, -1, -5, -7], bass="tick", lead="bassoon", seed=88, drums="tick", density=0.5)
    # finale: the Liar's circus march
    T_["music_boss"] = build_troll("boss", 118, 48, "hmin", [0, -2, -4, -5], bass="tuba", lead="bassoon", seed=71, drums="march", density=0.75, lead_vol=1.0)
    for k, v in T_.items():
        save(k, master(v), peak=0.62)


def main():
    sfx = {
        "jump": sfx_jump, "land": sfx_land, "die": sfx_die, "win": sfx_win, "coin": sfx_coin, "spring": sfx_spring,
        "crumble": sfx_crumble, "pop": sfx_pop, "whoosh": sfx_whoosh, "sting": sfx_sting, "button": sfx_button,
        "fake": sfx_fake, "click": sfx_click, "back": sfx_back, "unlock": sfx_unlock, "thud": sfx_thud,
        "reverse": sfx_reverse, "sign": sfx_sign, "laugh": sfx_laugh, "tick": sfx_tick, "rumble": sfx_rumble,
    }
    for k, fn in sfx.items():
        save("sfx_" + k, fn(), peak=0.8)
        print("sfx", k)
    make_music()
    print("music done")


if __name__ == "__main__":
    main()
