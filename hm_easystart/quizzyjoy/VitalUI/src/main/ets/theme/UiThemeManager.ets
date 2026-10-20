import { DEFAULT_THEME_PRESET, resolveThemePreset } from '@quizzyjoy/foundation';

/**
 * 运行时主题管理器（页面级 @ObservedV2 单例，v3.43 扩展为「主题包 + 强调色」双层）。
 *
 * 三层颜色体系里的 **L3**：
 * 1. **L1 静态令牌**（`$r('app.color.qj_*')` + `resources/dark` 限定词）——深浅色由资源限定词管；
 * 2. **L3 本类**（运行时主题）—— 主题包给基线品牌色，强调色给单点覆盖；
 * 3. **L4 系统组件默认色**（`AppThemeController` → `ThemeControl.setDefaultTheme`）——
 *    由 `AppBootstrap.applyTheme` 在改色时同步调用，覆盖对话框/开关/填充按钮等系统组件。
 *
 * 读取约定（组件侧）：
 * - VitalUI 原语：走 `@Param accentColor: string`（空串回退令牌），页面传 `theme.effectiveAccent()`；
 * - AppComponent 控件工厂：内部 `@Local theme = UiThemeManager.getInstance()`，调 `theme.brandColor()`。
 *
 * 组件**不要**写 `accentColor.length > 0 ? … : $r(...)` 这类三元——那会把「主题包」漏掉。
 */
@ObservedV2
export class UiThemeManager {
  private static instance: UiThemeManager | undefined = undefined;

  /** 当前强调色（'#RRGGBB'，空串 = 使用**主题包**的基准色） */
  @Trace accentColor: string = '';

  /** 当前主题包 id（AppThemePreset.id） */
  @Trace presetId: string = DEFAULT_THEME_PRESET;

  private constructor() {
  }

  static getInstance(): UiThemeManager {
    if (UiThemeManager.instance === undefined) {
      UiThemeManager.instance = new UiThemeManager();
    }
    return UiThemeManager.instance;
  }

  /** 生效的品牌色（'#RRGGBB'）：强调色优先，否则取主题包基准色。 */
  effectiveAccent(): string {
    if (this.accentColor.length > 0) {
      return this.accentColor;
    }
    return resolveThemePreset(this.presetId).baseHex;
  }

  /** 组件侧取色：有强调色用强调色；默认主题包回退静态令牌（深浅色仍由资源限定词处理）。 */
  brandColor(): ResourceColor {
    if (this.accentColor.length > 0) {
      return this.accentColor;
    }
    // 非默认主题包必须给具体色，否则换包对这类组件完全无效
    if (this.presetId === DEFAULT_THEME_PRESET) {
      return $r('app.color.qj_brand');
    }
    return resolveThemePreset(this.presetId).baseHex;
  }

  /**
   * 品牌色上的前景色（文字/图标压品牌底时用）。
   *
   * 默认主题包直接用令牌 `qj_on_brand`（随深浅色）；自定义主题包按品牌色感知亮度自动选
   * 深/浅前景，保证任意取色下都有对比度（否则「青碧底 + 白字」这类组合会发糊）。
   */
  onBrandColor(): ResourceColor {
    if (this.presetId === DEFAULT_THEME_PRESET && this.accentColor.length === 0) {
      return $r('app.color.qj_on_brand');
    }
    const hex: string = this.effectiveAccent().replace('#', '');
    if (hex.length !== 6) {
      return $r('app.color.qj_on_brand');
    }
    const r: number = parseInt(hex.substring(0, 2), 16) / 255;
    const g: number = parseInt(hex.substring(2, 4), 16) / 255;
    const b: number = parseInt(hex.substring(4, 6), 16) / 255;
    // 感知亮度（sRGB 加权）：亮底配深字，暗底配白字
    const luminance: number = 0.299 * r + 0.587 * g + 0.114 * b;
    return luminance > 0.62 ? '#0A0A0A' : '#FFFFFF';
  }

  /** 品牌色的柔和层（chip 底 / 选中底），默认主题包回退 `qj_brand_light` 令牌。 */
  brandSoftColor(): ResourceColor {
    if (this.presetId === DEFAULT_THEME_PRESET && this.accentColor.length === 0) {
      return $r('app.color.qj_brand_light');
    }
    // 非默认主题包：给「品牌色的柔和层」而不是满强度色（满强度会把 chip 底压成实心色块，
    // 与 qj_brand_light 的观感不一致）。用 15% 透明度叠加在卡片底色上，深浅色都成立。
    const hex: string = this.effectiveAccent();
    return hex.length === 7 ? `#26${hex.substring(1)}` : hex;
  }

  /**
   * 设置强调色。
   *
   * - `''`（空串）= **清除强调色覆盖**，回退到当前主题包基准色（v3.43 新增语义：
   *   切换主题包时必须能清空，否则上一套的强调色优先级更高，切包看起来"没反应"）；
   * - 合法 `'#RRGGBB'` 生效；其它输入忽略（保持原值）。
   */
  setAccentColor(color: string): void {
    const lower: string = color.trim().toLowerCase();
    if (lower.length === 0) {
      this.accentColor = '';
      return;
    }
    if (lower.length === 7 && lower.startsWith('#')) {
      this.accentColor = lower;
    }
  }

  /** 设置主题包（空串回退默认）。 */
  setPresetId(id: string): void {
    this.presetId = id.length > 0 ? id : DEFAULT_THEME_PRESET;
  }

  /** 回退到「默认主题包 + 无强调色」。 */
  reset(): void {
    this.accentColor = '';
    this.presetId = DEFAULT_THEME_PRESET;
  }
}
