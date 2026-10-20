import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppGauge —— 主题化仪表盘（Gauge 简易封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Gauge 是系统结构原语，其环色（colors）裸用不随运行时强调色变化，且环厚度需与
 * 全应用统一——本封装把环色统一收口到运行时 accent（空串回退 qj_brand），换一个
 * app 仪表盘配色策略就变 → 应用级。
 *
 * 【用法】AppGauge({ value: 60, min: 0, max: 100 })
 * 尺寸由调用方控制（.width/.height）。
 *
 * 【@kit 纪律】Gauge 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppGauge {
  /** 当前值。 */
  @Param value: number = 0;
  /** 最小值。 */
  @Param min: number = 0;
  /** 最大值。 */
  @Param max: number = 100;
  /** 环厚度（vp，默认 18）。 */
  @Param strokeWidth: number = 18;

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.brandColor();
  }

  build() {
    Gauge({ value: this.value, min: this.min, max: this.max })
      .colors(this.brandColor())
      .strokeWidth(this.strokeWidth)
  }
}
