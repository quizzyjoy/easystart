/**
 * 图表家族统一数据模型与绘制常量。
 *
 * 为什么颜色用常量而不用 $r 令牌：CanvasRenderingContext2D 的
 * fillStyle / strokeStyle 只接受 string | number | CanvasGradient | CanvasPattern，
 * 不支持 Resource（$r），故图表内色值与 AppScope 令牌保持同值、以常量表达。
 * 数值尺寸（间距/圆角等组件层）仍走 Foundation 令牌。
 *
 * v3.0（2026-09-30）色板升级：6 色单套 → 8 色深浅双套（Okabe-Ito 色盲安全原则：
 * 色相间隔 >60° 且相邻明度差 >15%）。C1-C6 与资源表语义色逐字同值（同值对齐纪律：
 * 改 AppScope/resources/{base,dark}/element/color.json 必须同步改本文件，反之亦然）。
 * 深色模式经 ChartPalette.forMode(true) 取提亮版；图表组件注入 @Param isDark。
 * 2026-10-12 色卡扩至 20 色深浅双套（现代化数据可视化色卡，chart_c01~c20）：
 * C01-C06 语义锚点 + C07-C08 补位不变，C09-C20 新增 12 色；同值对齐纪律延续。
 */

/** 图表数据项：text 为标签，weight 为权重（各图自适应当一化），color 空串 = 默认色板按序取色。 */
export class ChartEntry {
  text: string = '';
  weight: number = 1;
  color: string = '';

  constructor(text: string, weight: number, color: string = '') {
    this.text = text;
    this.weight = weight;
    this.color = color;
  }
}

/** 图表数据集。 */
export class ChartSeries {
  name: string = '';
  entries: ChartEntry[] = [];

  constructor(name: string, entries: ChartEntry[]) {
    this.name = name;
    this.entries = entries;
  }
}

/** 默认分类色板（20 色深浅双套，现代化数据可视化色卡）。
 *  命名对齐 AppScope resources 的 chart_c01~c20（同值对齐纪律：改一处须同步另一处）。
 *  场景：图表 item 染色、取色器预设、折线图图例、数据系列按序取色。
 *  设计原则：Okabe-Ito 色盲安全（相邻色相 >25°、相邻明度差 >12%）；深色套为浅色套提亮降饱和版。 */
export class ChartPalette {
  /** 浅色模式（AppScope base 套同值）：C01-C06 语义锚点（brand/success/warning/pink/purple/teal）
   *  + C07 棕 / C08 藏青补位 + C09-C20 现代化补充（橙/珊瑚/洋红/亮紫/天蓝/青绿/橄榄/金黄/梅紫/石板/豆沙/松石）。 */
  private static readonly COLORS_LIGHT: string[] = [
    '#0A59F7', '#0C8040', '#B27C06', '#C4365E',
    '#6E4EE9', '#0A7C8C', '#7A5C3E', '#3D5A80',
    '#E06C1F', '#D84A2A', '#C23B8F', '#8B5CF6',
    '#2E86E0', '#12A5A0', '#7A9E2E', '#C9A227',
    '#A0528C', '#5C7C99', '#B3596B', '#4E8D7C'
  ];

  /** 深色模式（对照 AppScope dark 套提亮版，逐位对应 COLORS_LIGHT）。 */
  private static readonly COLORS_DARK: string[] = [
    '#5C8DFA', '#4CC98A', '#D9A93E', '#E57FA0',
    '#9B87F0', '#57B4C0', '#A87B55', '#6C8EBF',
    '#F09554', '#EF7A5B', '#E06AB0', '#AB8AFA',
    '#6BA8F0', '#4EC6C0', '#9DBE52', '#E0BD52',
    '#C77FB0', '#7F9DB8', '#D1838F', '#74B09F'
  ];

  /** 按模式取色板数组。 */
  static forMode(isDark: boolean): string[] {
    return isDark ? ChartPalette.COLORS_DARK : ChartPalette.COLORS_LIGHT;
  }

  static pick(index: number, isDark: boolean = false): string {
    const colors: string[] = ChartPalette.forMode(isDark);
    return colors[((index % colors.length) + colors.length) % colors.length];
  }

  /** 取数据项颜色：显式色优先（用户自有色值两模式共用），空串回退色板。 */
  static colorOf(entry: ChartEntry, index: number, isDark: boolean = false): string {
    if (entry.color.length > 0) {
      return entry.color;
    }
    return ChartPalette.pick(index, isDark);
  }
}

/** 图表绘制共享常量与工具（模式感知）。 */
export class ChartStyle {
  /** 网格 / 辐射线颜色（浅色：50% 灰；深色：25% 白）。 */
  static gridColor(isDark: boolean = false): string {
    return isDark ? '#40FFFFFF' : '#80666666';
  }

  /** 标签文字颜色（同 app_text_secondary 两模式不透明等价）。 */
  static textColor(isDark: boolean = false): string {
    return isDark ? '#9BA0A6' : '#66707A';
  }

  /** 选中扇区描边色（两模式共用高对比白）。 */
  static readonly SELECTED_STROKE: string = '#FFFFFF';

  static readonly FONT_FAMILY: string = 'sans-serif';

  /** 构造 Canvas font 字符串。 */
  static fontPx(sizePx: number): string {
    const clamped: number = Math.max(9, Math.round(sizePx));
    return `${clamped}px ${ChartStyle.FONT_FAMILY}`;
  }

  /** ease-out cubic 缓动。 */
  static easeOutCubic(t: number): number {
    return 1 - Math.pow(1 - t, 3);
  }

  static degToRad(deg: number): number {
    return deg * Math.PI / 180;
  }
}
