import { ChartEntry, ChartSeries, ChartPalette, ChartStyle } from './ChartData';
import { MotionSpec } from '../motion/MotionSpec';

/**
 * QuarterRoseChart —— 季度玫瑰图（90° 扫角的南丁格尔玫瑰）。
 *
 * 形态移植自 EasyRandom VitalUI：扇区只占右上象限（270°→360°），
 * 圆心移到画布左下角、半径放大以增强透视感。
 * 修复底本缺陷：标签锚点越界 / showAxis / showText 失效。
 * 增强：入场生长动画；点击扇区选中 + onSelect。
 */
@ComponentV2
export struct QuarterRoseChart {
  @Param data: ChartSeries = new ChartSeries('示例', []);
  /** 90° 弧半径占画布宽的比例。 */
  @Param rate: number = 0.9;
  @Param showAxis: boolean = true;
  @Param showText: boolean = true;
  /** 深色模式（色板/网格/文字取提亮版；由调用方注入 ColorModeManager 状态）。 */
  @Param isDark: boolean = false;
  @Event onSelect: (entry: ChartEntry, index: number) => void = () => {
  };

  @Local progress: number = 0;
  @Local selected: number = -1;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private areaW: number = 0;
  private entryTimer: number = -1;

  aboutToDisappear(): void {
    if (this.entryTimer >= 0) {
      clearInterval(this.entryTimer);
      this.entryTimer = -1;
    }
  }

  @Monitor('isDark')
  onModeChange(): void {
    this.draw();
  }

  private startEntry(): void {
    const start: number = Date.now();
    this.entryTimer = setInterval(() => {
      const t: number = Math.min(1, (Date.now() - start) / MotionSpec.DURATION_SLOW);
      this.progress = ChartStyle.easeOutCubic(t);
      this.draw();
      if (t >= 1) {
        clearInterval(this.entryTimer);
        this.entryTimer = -1;
      }
    }, 16);
  }

  private draw(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = ctx.width;
    if (w <= 0) {
      return;
    }
    ctx.clearRect(0, 0, w, w);
    const radius: number = w * this.rate;
    const originX: number = 2;
    const originY: number = w - 2;
    const entries: ChartEntry[] = this.data.entries;
    const n: number = entries.length;
    if (n === 0) {
      return;
    }

    let minW: number = entries[0].weight;
    let maxW: number = entries[0].weight;
    entries.forEach((entry: ChartEntry): void => {
      minW = Math.min(minW, entry.weight);
      maxW = Math.max(maxW, entry.weight);
    });
    const span: number = maxW - minW;
    const sector: number = 90 / n;

    if (this.showAxis) {
      for (let j = 1; j <= 4; j++) {
        ctx.beginPath();
        ctx.arc(originX, originY, radius / 4 * j, Math.PI * 1.5, Math.PI * 2);
        ctx.strokeStyle = ChartStyle.gridColor(this.isDark);
        ctx.lineWidth = 1;
        ctx.stroke();
      }
      for (let i = 0; i <= n; i++) {
        const angle: number = ChartStyle.degToRad(270 + sector * i);
        ctx.beginPath();
        ctx.moveTo(originX, originY);
        ctx.lineTo(originX + Math.cos(angle) * radius, originY + Math.sin(angle) * radius);
        ctx.strokeStyle = ChartStyle.gridColor(this.isDark);
        ctx.lineWidth = 1;
        ctx.stroke();
      }
    }

    for (let i = 0; i < n; i++) {
      const norm: number = span > 0 ? (entries[i].weight - minW) / span : 1;
      let value: number = (radius * 0.35 + norm * radius * 0.65) * this.progress;
      if (i === this.selected) {
        value = Math.min(value * 1.06, radius * 1.06);
      }
      const startAngle: number = 270 + i * sector;
      const endAngle: number = startAngle + sector;
      ctx.beginPath();
      ctx.moveTo(originX, originY);
      ctx.arc(originX, originY, value,
        ChartStyle.degToRad(startAngle), ChartStyle.degToRad(endAngle), false);
      ctx.closePath();
      ctx.fillStyle = ChartPalette.colorOf(entries[i], i, this.isDark);
      ctx.fill();
      if (i === this.selected) {
        ctx.strokeStyle = ChartStyle.SELECTED_STROKE;
        ctx.lineWidth = 2;
        ctx.stroke();
      }
    }

    if (this.showText) {
      ctx.font = ChartStyle.fontPx(radius * 0.075);
      ctx.fillStyle = ChartStyle.textColor(this.isDark);
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const labelR: number = radius * 1.06;
      for (let i = 0; i < n; i++) {
        const centerAngle: number = ChartStyle.degToRad(270 + (i + 0.5) * sector);
        const textX: number = Math.min(w - 14, Math.max(14, originX + Math.cos(centerAngle) * labelR));
        const textY: number = Math.min(w - 10, Math.max(10, originY + Math.sin(centerAngle) * labelR));
        ctx.fillText(entries[i].text, textX, textY);
      }
    }
  }

  private hitIndex(xPx: number, yPx: number): number {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = ctx.width;
    const radius: number = w * this.rate;
    const originX: number = 2;
    const originY: number = w - 2;
    const dx: number = xPx - originX;
    const dy: number = yPx - originY;
    const r: number = Math.hypot(dx, dy);
    if (r > radius * 1.08) {
      return -1;
    }
    const n: number = this.data.entries.length;
    if (n === 0) {
      return -1;
    }
    let deg: number = Math.atan2(dy, dx) * 180 / Math.PI;
    deg = ((deg % 360) + 360) % 360;
    if (deg < 270) {
      return -1;
    }
    const sector: number = 90 / n;
    return Math.min(n - 1, Math.floor((deg - 270) / sector));
  }

  build() {
    Canvas(this.context)
      .onReady(() => {
        this.progress = 0;
        this.draw();
        this.startEntry();
      })
      .onAreaChange((_: Area, newArea: Area) => {
        this.areaW = Number(newArea.width);
      })
      .onClick((event: ClickEvent) => {
        if (this.areaW <= 0 || this.context.width <= 0) {
          return;
        }
        const scale: number = this.context.width / this.areaW;
        const index: number = this.hitIndex(event.x * scale, event.y * scale);
        this.selected = index;
        this.draw();
        if (index >= 0) {
          this.onSelect(this.data.entries[index], index);
        }
      })
      .width('100%')
      .aspectRatio(1)
  }
}
