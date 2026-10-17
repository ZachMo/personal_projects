// A square drawing pad for phones: touch and mouse, 6 colours, 3 brush
// sizes, undo, clear. Exports a PNG of about 400 x 400, kept under 100 KB.

(function () {
  const SIZE = 400;
  const COLORS = ['#111111', '#d62828', '#1d4ed8', '#2a9d3a', '#f4b400', '#8b5a2b'];
  const BRUSHES = [4, 10, 22];
  const MAX_BYTES = 100 * 1024;

  class DrawPad {
    constructor() {
      this.ops = []; // strokes and clears, in order, so undo can step back over a clear
      this.base = null; // an earlier submitted drawing to keep editing
      this.color = COLORS[0];
      this.brush = BRUSHES[1];
      this.dirty = false;
      this.canvas = null;
      this.ctx = null;
    }

    reset() {
      this.ops = [];
      this.base = null;
      this.dirty = false;
    }

    hasInk() {
      let ink = !!this.base;
      for (const op of this.ops) ink = op.clear ? false : true;
      return ink;
    }

    setBase(png) {
      if (!png) return;
      const img = new Image();
      img.onload = () => { this.base = img; this.redraw(); };
      img.src = png;
    }

    mount(container) {
      container.innerHTML = `
        <div class="pad-wrap"><canvas width="${SIZE}" height="${SIZE}" class="pad" aria-label="Drawing canvas"></canvas></div>
        <div class="pad-tools">
          <div class="swatches">${COLORS.map((c) => `<button type="button" class="swatch ${c === this.color ? 'on' : ''}" data-color="${c}" style="--c:${c}" aria-label="Colour"></button>`).join('')}</div>
          <div class="brushes">
            ${BRUSHES.map((b) => `<button type="button" class="brush ${b === this.brush ? 'on' : ''}" data-brush="${b}" aria-label="Brush size ${b}"><i style="width:${Math.max(6, b * 0.9)}px;height:${Math.max(6, b * 0.9)}px"></i></button>`).join('')}
            <button type="button" class="tool" data-tool="undo">Undo</button>
            <button type="button" class="tool" data-tool="clear">Clear</button>
          </div>
        </div>`;
      this.canvas = container.querySelector('canvas');
      this.ctx = this.canvas.getContext('2d');
      this.redraw();

      container.querySelector('.pad-tools').addEventListener('click', (e) => {
        const b = e.target.closest('button');
        if (!b) return;
        if (b.dataset.color) {
          this.color = b.dataset.color;
          container.querySelectorAll('.swatch').forEach((s) => s.classList.toggle('on', s === b));
        } else if (b.dataset.brush) {
          this.brush = Number(b.dataset.brush);
          container.querySelectorAll('.brush').forEach((s) => s.classList.toggle('on', s === b));
        } else if (b.dataset.tool === 'undo') {
          this.ops.pop();
          this.dirty = true;
          this.redraw();
        } else if (b.dataset.tool === 'clear') {
          if (this.hasInk()) { this.ops.push({ clear: true }); this.dirty = true; this.redraw(); }
        }
      });

      const c = this.canvas;
      let current = null;
      const point = (e) => {
        const r = c.getBoundingClientRect();
        return [((e.clientX - r.left) / r.width) * SIZE, ((e.clientY - r.top) / r.height) * SIZE];
      };
      c.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        c.setPointerCapture(e.pointerId);
        current = { color: this.color, size: this.brush, pts: [point(e)] };
        this.ops.push(current);
        this.dirty = true;
        this.drawStroke(current);
      });
      c.addEventListener('pointermove', (e) => {
        if (!current) return;
        e.preventDefault();
        const events = e.getCoalescedEvents ? e.getCoalescedEvents() : [e];
        for (const ev of events) current.pts.push(point(ev));
        this.drawStroke(current, Math.max(0, current.pts.length - events.length - 1));
      });
      const end = () => { current = null; };
      c.addEventListener('pointerup', end);
      c.addEventListener('pointercancel', end);
      // Stop the page scrolling or pull-to-refresh while drawing.
      c.addEventListener('touchstart', (e) => e.preventDefault(), { passive: false });
      c.addEventListener('touchmove', (e) => e.preventDefault(), { passive: false });
    }

    drawStroke(s, from = 0) {
      const ctx = this.ctx;
      if (!ctx) return;
      ctx.strokeStyle = s.color;
      ctx.fillStyle = s.color;
      ctx.lineWidth = s.size;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      const pts = s.pts;
      if (pts.length === 1) {
        ctx.beginPath();
        ctx.arc(pts[0][0], pts[0][1], s.size / 2, 0, Math.PI * 2);
        ctx.fill();
        return;
      }
      ctx.beginPath();
      ctx.moveTo(pts[from][0], pts[from][1]);
      for (let i = from + 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
      ctx.stroke();
    }

    redraw() {
      const ctx = this.ctx;
      if (!ctx) return;
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0, 0, SIZE, SIZE);
      let start = 0;
      this.ops.forEach((op, i) => { if (op.clear) start = i + 1; });
      if (start === 0 && this.base) ctx.drawImage(this.base, 0, 0, SIZE, SIZE);
      for (let i = start; i < this.ops.length; i++) this.drawStroke(this.ops[i]);
    }

    toPNG() {
      if (!this.canvas) return null;
      let url = this.canvas.toDataURL('image/png');
      // A busy drawing can run large; shrink it until it fits.
      for (const size of [320, 260, 200]) {
        if (url.length * 0.75 <= MAX_BYTES) break;
        const c = document.createElement('canvas');
        c.width = size;
        c.height = size;
        c.getContext('2d').drawImage(this.canvas, 0, 0, size, size);
        url = c.toDataURL('image/png');
      }
      return url;
    }
  }

  window.DrawPad = DrawPad;
})();
