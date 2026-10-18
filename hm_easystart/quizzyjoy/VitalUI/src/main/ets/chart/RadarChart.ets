import { ChartEntry, ChartSeries, ChartPalette, ChartStyle } from './ChartData';
import { MotionSpec } from '../motion/MotionSpec';

/**
 * RadarChart —— 雷达图（能力五维图）。
 *
 * 移植自 EasyRandom VitalUI 并修复底本缺陷：
 * 1. 节点绘制循环复用未复位的 i，导致全部节点落在同一角度 → 独立索引；
 * 2. 权重归一化硬编码 /2.5 → 按数据动态归一；
 * 3. 标签字号按文本长度反比（长文本更小）→ 固定自适应字号。
 *
 * 增强：入场缩放动画；点击最近顶点选中 + onSelect。
 */
@ComponentV2
export struct RadarChart {
  @Param data: ChartSeries = new ChartSeries('示例', []);
  @Param rate: number = 0.8;
  @Param showAxis: boolean = true;
  @Param showText: boolean = true;
  /** 深色模式（色板/网格/文字取提亮版；由调用方注入 ColorModeManager 状态）。 */
  @Param isDark: boolean = false;
  /** 数据多边形填充色（空串 = 按模式取默认：浅色品牌蓝半透明 / 深色提亮版）。 */
  @Param fillColor: string = '';
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

  /** 数据多边形填充色：显式注入优先，否则按模式取默认（同 C1 品牌蓝族）。 */
  private resolvedFill(): string {
    if (this.fillColor.length > 0) {
      return this.fillColor;
    }
    return this.isDark ? 'rgba(92,141,250,0.32)' : 'rgba(10,89,247,0.30)';
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

  private maxWeight(): number {
    let maxW: number = 0;
    this.data.entries.forEach((entry: ChartEntry): void => {
      maxW = Math.max(maxW, entry.weight);
    });
    return maxW;
  }

  private vertex(center: number, radius: number, index: number, n: number, scale: number): [number, number] {
    const angle: number = Math.PI * 2 * index / n - Math.PI / 2;
    return [center + Math.cos(angle) * radius * scale, center + Math.sin(angle) * radius * scale];
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
    if (n < 3) {
      return;
    }
    const maxW: number = this.maxWeight();

    if (this.showAxis) {
      for (let j = 1; j <= 4; j++) {
        ctx.beginPath();
        for (let i = 0; i <= n; i++) {
          const point: [number, number] = this.vertex(center, radius, i % n, n, j / 4);
          if (i === 0) {
            ctx.moveTo(point[0], point[1]);
          } else {
            ctx.lineTo(point[0], point[1]);
          }
        }
        ctx.strokeStyle = ChartStyle.gridColor(this.isDark);
        ctx.lineWidth = 1;
        ctx.stroke();
      }
      for (let i = 0; i < n; i++) {
        const point: [number, number] = this.vertex(center, radius, i, n, 1);
        ctx.beginPath();
        ctx.moveTo(center, center);
        ctx.lineTo(point[0], point[1]);
        ctx.strokeStyle = ChartStyle.gridColor(this.isDark);
        ctx.lineWidth = 1;
        ctx.stroke();
      }
    }

    ctx.beginPath();
    for (let i = 0; i <= n; i++) {
      const entry: ChartEntry = entries[i % n];
      const scale: number = maxW > 0 ? entry.weight / maxW : 0;
      const point: [number, number] = this.vertex(center, radius, i % n, n, scale * this.progress);
      if (i === 0) {
        ctx.moveTo(point[0], point[1]);
      } else {
        ctx.lineTo(point[0], point[1]);
      }
    }
    ctx.fillStyle = this.resolvedFill();
    ctx.fill();

    for (let i = 0; i < n; i++) {
      const entry: ChartEntry = entries[i];
      const scale: number = maxW > 0 ? entry.weight / maxW : 0;
      const point: [number, number] = this.vertex(center, radius, i, n, scale * this.progress);
      const isSelected: boolean = i === this.selected;
      const dotRadius: number = isSelected ? 6 : 4;
      ctx.beginPath();
      ctx.arc(point[0], point[1], dotRadius, 0, Math.PI * 2);
      ctx.fillStyle = ChartPalette.colorOf(entry, i, this.isDark);
      ctx.fill();
      ctx.strokeStyle = ChartStyle.SELECTED_STROKE;
      ctx.lineWidth = isSelected ? 2 : 1;
      ctx.stroke();
    }

    if (this.showText) {
      ctx.font = ChartStyle.fontPx(center * 0.09);
      ctx.fillStyle = ChartStyle.textColor(this.isDark);
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const labelR: number = radius * 1.14;
      for (let i = 0; i < n; i++) {
        const point: [number, number] = this.vertex(center, labelR, i, n, 1);
        const textX: number = Math.min(w - 14, Math.max(14, point[0]));
        const textY: number = Math.min(w - 10, Math.max(10, point[1]));
        ctx.fillText(entries[i].text, textX, textY);
      }
    }
  }

  private hitIndex(xPx: number, yPx: number): number {
    const ctx: CanvasRenderingContext2D = this.context;
    const w: number = ctx.width;
    if (w <= 0) {
      return -1;
    }
    const center: number = w / 2;
    const radius: number = center * this.rate;
    const entries: ChartEntry[] = this.data.entries;
    const n: number = entries.length;
    if (n < 3) {
      return -1;
    }
    const maxW: number = this.maxWeight();
    const threshold: number = center * 0.18;
    let best: number = -1;
    let bestDist: number = threshold;
    for (let i = 0; i < n; i++) {
      const scale: number = maxW > 0 ? entries[i].weight / maxW : 0;
      const point: [number, number] = this.vertex(center, radius, i, n, scale);
      const dist: number = Math.hypot(xPx - point[0], yPx - point[1]);
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
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
