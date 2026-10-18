import { ChartEntry, ChartSeries, ChartPalette, ChartStyle } from './ChartData';
import { MotionSpec } from '../motion/MotionSpec';

/**
 * PieChart —— 权重饼图（合并 EasyRandom PieChart / PieChart_V3 两版差异）。
 *
 * 移植修复：
 * 1. V3 标签锚点硬编码 160px → 按半径比例（0.62R）自适应；
 * 2. V1 竖排单字标签 → 横排居中；
 * 3. V3 的 showDot 声明未实现 → 实现（标签前圆点）；
 * 4. 弃用 V3 内置 demoData 预设（数据由调用方提供）。
 *
 * 增强：入场扫角动画（终角 × progress）；点击扇区选中 + onSelect。
 */
@ComponentV2
export struct PieChart {
  @Param data: ChartSeries = new ChartSeries('示例', []);
  /** 扇区标签前是否绘制圆点（PieChart_V3 能力）。 */
  @Param showDot: boolean = false;
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

  private totalWeight(): number {
    let total: number = 0;
    this.data.entries.forEach((entry: ChartEntry): void => {
      total += entry.weight;
    });
    return total;
  }

  private draw(): void {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = ctx.width;
    if (w <= 0) {
      return;
    }
    ctx.clearRect(0, 0, w, w);
    const center: number = w / 2;
    const radius: number = center * 0.92;
    const entries: ChartEntry[] = this.data.entries;
    const n: number = entries.length;
    if (n === 0) {
      return;
    }
    const total: number = this.totalWeight();
    if (total <= 0) {
      return;
    }

    const sweep: number = 360 * this.progress;
    let startAngle: number = -90;
    for (let i = 0; i < n; i++) {
      const full: number = entries[i].weight / total * 360;
      let endAngle: number = startAngle + full;
      if (startAngle >= -90 + sweep) {
        break;
      }
      if (endAngle > -90 + sweep) {
        endAngle = -90 + sweep;
      }
      const grow: number = i === this.selected ? 1.03 : 1;
      ctx.beginPath();
      ctx.moveTo(center, center);
      ctx.arc(center, center, radius * grow,
        ChartStyle.degToRad(startAngle), ChartStyle.degToRad(endAngle), false);
      ctx.closePath();
      ctx.fillStyle = ChartPalette.colorOf(entries[i], i, this.isDark);
      ctx.fill();
      if (i === this.selected) {
        ctx.strokeStyle = ChartStyle.SELECTED_STROKE;
        ctx.lineWidth = 2;
        ctx.stroke();
      }
      startAngle += full;
    }

    if (this.showText && this.progress >= 1) {
      ctx.font = ChartStyle.fontPx(center * 0.085);
      ctx.fillStyle = '#FFFFFF';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      let angle: number = -90;
      for (let i = 0; i < n; i++) {
        const full: number = entries[i].weight / total * 360;
        if (full >= 14) {
          const centerAngle: number = ChartStyle.degToRad(angle + full / 2);
          const textX: number = center + Math.cos(centerAngle) * radius * 0.62;
          const textY: number = center + Math.sin(centerAngle) * radius * 0.62;
          if (this.showDot) {
            ctx.beginPath();
            ctx.arc(textX - entries[i].text.length * center * 0.045 - 5, textY, 3, 0, Math.PI * 2);
            ctx.fillStyle = '#FFFFFF';
            ctx.fill();
            ctx.fillStyle = '#FFFFFF';
          }
          ctx.fillText(entries[i].text, textX, textY);
        }
        angle += full;
      }
    }
  }

  private hitIndex(xPx: number, yPx: number): number {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = ctx.width;
    const center: number = w / 2;
    const radius: number = center * 0.92;
    const dx: number = xPx - center;
    const dy: number = yPx - center;
    const r: number = Math.hypot(dx, dy);
    if (r > radius * 1.06) {
      return -1;
    }
    const entries: ChartEntry[] = this.data.entries;
    const n: number = entries.length;
    const total: number = this.totalWeight();
    if (n === 0 || total <= 0) {
      return -1;
    }
    let deg: number = Math.atan2(dy, dx) * 180 / Math.PI + 90;
    deg = ((deg % 360) + 360) % 360;
    let acc: number = 0;
    for (let i = 0; i < n; i++) {
      acc += entries[i].weight / total * 360;
      if (deg < acc) {
        return i;
      }
    }
    return n - 1;
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
