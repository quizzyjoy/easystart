/**
 * 运行时主题管理器（页面级 @ObservedV2 单例）。
 *
 * 双机制主题：
 * 1. 静态主题（颜色模式 base/dark）由 AppScope 资源覆盖契约承担，组件用 $r 令牌自动跟随；
 * 2. 运行时主题（品牌强调色）由本类承担，页面注入到 VitalUI 组件的 accentColor @Param
 *    （空串 = 回退 $r 令牌），VitalUI 组件不持有本单例。
 *
 * 颜色来源：CommonColorPickerSheet 自由取色（HdsColorPicker 的 API 23 复刻），
 * 任意 '#RRGGBB' 均可，不再限于预设枚举。
 *
 * 用法：页面 @Local theme: UiThemeManager = UiThemeManager.getInstance();
 *      CommonButton({ accentColor: theme.accentColor })
 */
@ObservedV2
export class UiThemeManager {
  private static instance: UiThemeManager | undefined = undefined;

  /** 当前强调色（'#RRGGBB'，空串 = 使用 qj_brand 令牌） */
  @Trace accentColor: string = '';

  private constructor() {
  }

  static getInstance(): UiThemeManager {
    if (UiThemeManager.instance === undefined) {
      UiThemeManager.instance = new UiThemeManager();
    }
    return UiThemeManager.instance;
  }

  /** 设置强调色（仅接受 '#RRGGBB' 格式，非法输入忽略）。 */
  setAccentColor(color: string): void {
    const lower: string = color.toLowerCase();
    if (lower.length === 7 && lower.startsWith('#')) {
      this.accentColor = lower;
    }
  }

  /** 回退到令牌主题。 */
  reset(): void {
    this.accentColor = '';
  }
}
