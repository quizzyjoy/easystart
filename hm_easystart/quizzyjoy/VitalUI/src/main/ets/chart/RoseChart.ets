import { ChartEntry, ChartSeries, ChartPalette, ChartStyle } from './ChartData';
import { MotionSpec } from '../motion/MotionSpec';

/**
 * RoseChart —— 玫瑰图（南丁格尔玫瑰：等角扇区，半径编码权重）。
 *
 * 移植自 EasyRandom VitalUI 并修复底本缺陷：
 * 1. showAxis / showText 声明失效（永远绘制）→ 真正生效；
 * 2. 标签锚点 radius*2 超出画布不可见 → 收敛到画布内自适应；
 * 3. 权重归一化硬编码 min=1/max=3 → 按数据动态归一到 [0.35, 1.0] 半径区间。
 *
 * 增强：入场生长动画（setInterval 驱动逐帧重绘，零 @kit）；
 * 点击扇区选中（高亮 + 外描边）并回调 onSelect。
 */
@ComponentV2
export struct RoseChart {
  @Param data: ChartSeries = new ChartSeries('示例', []);
  /** 绘制主体占 Canvas 尺寸的比例。 */
  @Param rate: number = 0.8;
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
    const center: number = w / 2;
    const radius: number = center * this.rate;
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
    const sector: number = 360 / n;

    if (this.showAxis) {
      for (let j = 1; j <= 5; j++) {
        ctx.beginPath();
        ctx.arc(center, center, radius / 5 * j, 0, Math.PI * 2);
        ctx.strokeStyle = ChartStyle.gridColor(this.isDark);
        ctx.lineWidth = 1;
        ctx.stroke();
      }
      for (let i = 0; i < n; i++) {
        const angle: number = ChartStyle.degToRad(i * sector - 90);
        ctx.beginPath();
        ctx.moveTo(center, center);
        ctx.lineTo(center + Math.cos(angle) * radius, center + Math.sin(angle) * radius);
        ctx.strokeStyle = ChartStyle.gridColor(this.isDark);
        ctx.lineWidth = 1;
        ctx.stroke();
      }
    }

    for (let i = 0; i < n; i++) {
      const norm: number = span > 0 ? (entries[i].weight - minW) / span : 1;
      let value: number = (radius * 0.35 + norm * radius * 0.65) * this.progress;
      if (i === this.selected) {
        value = Math.min(value * 1.06, radius * 1.08);
      }
      const startAngle: number = i * sector - 90;
      const endAngle: number = startAngle + sector;
      ctx.beginPath();
      ctx.moveTo(center, center);
      ctx.arc(center, center, value,
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
      ctx.font = ChartStyle.fontPx(center * 0.09);
      ctx.fillStyle = ChartStyle.textColor(this.isDark);
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const labelR: number = radius * 1.12;
      for (let i = 0; i < n; i++) {
        const centerAngle: number = ChartStyle.degToRad((i + 0.5) * sector - 90);
        const textX: number = Math.min(w - 14, Math.max(14, center + Math.cos(centerAngle) * labelR));
        const textY: number = Math.min(w - 10, Math.max(10, center + Math.sin(centerAngle) * labelR));
        ctx.fillText(entries[i].text, textX, textY);
      }
    }
  }

  private hitIndex(xPx: number, yPx: number): number {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = ctx.width;
    const center: number = w / 2;
    const radius: number = center * this.rate;
    const dx: number = xPx - center;
    const dy: number = yPx - center;
    const r: number = Math.hypot(dx, dy);
    if (r > radius * 1.08) {
      return -1;
    }
    const n: number = this.data.entries.length;
    if (n === 0) {
      return -1;
    }
    const sector: number = 360 / n;
    let deg: number = Math.atan2(dy, dx) * 180 / Math.PI + 90;
    deg = ((deg % 360) + 360) % 360;
    return Math.min(n - 1, Math.floor(deg / sector));
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
