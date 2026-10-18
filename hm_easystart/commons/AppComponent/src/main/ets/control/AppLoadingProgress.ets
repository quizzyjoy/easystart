import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppLoadingProgress —— 主题化加载进度（LoadingProgress 简易封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * LoadingProgress 是系统结构原语，其转圈前景色（color）裸用不随运行时强调色变化，
 * 且加载态视觉需与全应用统一——本封装把前景色统一收口到运行时 accent（空串回退
 * qj_brand），换一个 app 加载色策略就变 → 应用级。与 VitalUI CommonLoading 的分工：
 * CommonLoading 是「自定义三形态加载组件」（业务定制）；本件是「系统 LoadingProgress
 * 的换肤基础封装」，二者边界清晰（VitalUI 保自定义件，应用级保系统件换肤）。
 *
 * 【用法】AppLoadingProgress().width(32).height(32)
 * 尺寸由调用方控制（系统件不自设宽高）。
 *
 * 【@kit 纪律】LoadingProgress 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppLoadingProgress {
  /** 是否显示加载动画（false 仅占位，动画停）。 */
  @Param isEnabled: boolean = true;

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.accentColor.length > 0 ? this.theme.accentColor : $r('app.color.qj_brand');
  }

  build() {
    LoadingProgress()
      .color(this.brandColor())
      .enableLoading(this.isEnabled)
  }
}
