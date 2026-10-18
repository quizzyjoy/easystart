import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppProgress —— 主题化进度条。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Progress 是系统结构原语，其进度色（color）需跟随运行时强调色才换肤彻底；
 * 轨道底色统一收口到应用填充令牌 → 应用级。
 *
 * 【用法】
 * 线性：AppProgress({ value: this.percent })
 * 环形：AppProgress({ value: this.percent, type: ProgressType.Ring, strokeWidth: 8 })
 *
 * 【@kit 纪律】Progress / ProgressType 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppProgress {
  /** 当前进度值。 */
  @Param value: number = 0;
  /** 进度总量（默认 100）。 */
  @Param total: number = 100;
  /** 进度条形态（默认线性 Linear；可传 Ring / Eclipse / Capsule）。 */
  @Param type: ProgressType = ProgressType.Linear;
  /** 描边宽度（vp，线性条/环的粗细，默认 4；环形可按需覆盖）。 */
  @Param strokeWidth: number = 4;
  /** 是否可交互（进度条一般仅展示，保留以便个别场景置灰）。 */
  @Param isEnabled: boolean = true;

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.accentColor.length > 0 ? this.theme.accentColor : $r('app.color.qj_brand');
  }

  build() {
    Progress({ value: this.value, total: this.total, type: this.type })
      .color(this.brandColor())
      .backgroundColor($r('app.color.app_fill_medium'))
      .style({ strokeWidth: this.strokeWidth })
      .enabled(this.isEnabled)
  }
}
