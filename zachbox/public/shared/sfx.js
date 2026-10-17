// Zachbox Games: tiny synthesised sound effects. No audio files.
// Browsers only allow sound after a click, so call SFX.unlock() from one.

(function () {
  let ctx = null;
  let muted = false;
  try { muted = localStorage.getItem('zb:muted') === '1'; } catch {}

  function ac() {
    if (!ctx) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return null;
      ctx = new AC();
    }
    return ctx;
  }

  function tone(freq, start, dur, { type = 'sine', gain = 0.15, slide = 0 } = {}) {
    const a = ac();
    if (!a || muted) return;
    const t = a.currentTime + start;
    const o = a.createOscillator();
    const g = a.createGain();
    o.type = type;
    o.frequency.setValueAtTime(freq, t);
    if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(20, freq + slide), t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(gain, t + 0.02);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g).connect(a.destination);
    o.start(t);
    o.stop(t + dur + 0.05);
  }

  function noise(start, dur, { gain = 0.12, filter = 800 } = {}) {
    const a = ac();
    if (!a || muted) return;
    const t = a.currentTime + start;
    const buf = a.createBuffer(1, Math.ceil(a.sampleRate * dur), a.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    const src = a.createBufferSource();
    src.buffer = buf;
    const f = a.createBiquadFilter();
    f.type = 'lowpass';
    f.frequency.value = filter;
    const g = a.createGain();
    g.gain.setValueAtTime(gain, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g).connect(a.destination);
    src.start(t);
  }

  const SFX = {
    unlock() { const a = ac(); if (a && a.state === 'suspended') a.resume(); },
    get muted() { return muted; },
    toggle() {
      muted = !muted;
      try { localStorage.setItem('zb:muted', muted ? '1' : '0'); } catch {}
      return muted;
    },
    join() { tone(660, 0, 0.18, { type: 'triangle' }); tone(990, 0.08, 0.25, { type: 'triangle', gain: 0.1 }); },
    submit() { tone(1180, 0, 0.12, { type: 'sine', gain: 0.08 }); },
    tick() { tone(1500, 0, 0.05, { type: 'square', gain: 0.03 }); },
    gong() {
      tone(110, 0, 2.4, { type: 'sine', gain: 0.22 });
      tone(165, 0, 2.0, { type: 'sine', gain: 0.1 });
      tone(277, 0, 1.4, { type: 'triangle', gain: 0.05 });
    },
    thunder() { noise(0, 2.2, { gain: 0.25, filter: 300 }); tone(55, 0, 1.8, { gain: 0.2 }); },
    drumroll(seconds = 3) {
      for (let i = 0; i < seconds * 18; i++) noise(i / 18, 0.07, { gain: 0.05 + (i / (seconds * 18)) * 0.12, filter: 1400 });
    },
    sting() {
      tone(146.8, 0, 2.2, { type: 'sawtooth', gain: 0.07 });
      tone(174.6, 0, 2.2, { type: 'sawtooth', gain: 0.06 });
      tone(207.7, 0, 2.2, { type: 'sawtooth', gain: 0.05 });
      noise(0, 0.6, { gain: 0.2, filter: 600 });
    },
    good() { [523, 659, 784, 1047].forEach((f, i) => tone(f, i * 0.09, 0.4, { type: 'triangle', gain: 0.1 })); },
    bad() { tone(300, 0, 0.5, { type: 'sawtooth', gain: 0.06, slide: -140 }); tone(220, 0.25, 0.7, { type: 'sawtooth', gain: 0.06, slide: -100 }); },
  };

  window.SFX = SFX;
})();
