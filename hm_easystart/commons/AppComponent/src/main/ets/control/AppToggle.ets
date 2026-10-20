import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppToggle —— 主题化开关（Switch）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Toggle 是系统结构原语，但其「选中色跟随运行时强调色」是应用的换肤契约——
 * 裸用 Toggle 的 selectedColor 不会随 UiThemeManager 换色，导致换肤不彻底。
 * 本封装把 selectedColor 统一收口到运行时 accent（空串回退 qj_brand 令牌），
 * 换一个 app 换肤策略即变 → 应用级（判据见指南 §17「换一个 app 还能用吗」）。
 *
 * 【与 HDS 的分工】设置页开关走 HdsListItemCard 的 SuffixSwitch（HDS 原生范式、系统色）；
 * 自由页面 / 表单里需要随强调色彻底换肤的开关用本组件。
 *
 * 【V2 受控】isOn 由父持有，onChange 上抛，父回写 isOn，不使用 $$。
 *
 * 【用法】AppToggle({ isOn: this.enabled, onChange: (v: boolean): void => { this.enabled = v } })
 *
 * 【@kit 纪律】Toggle / ToggleType 为全局组件类型；UiThemeManager 经 @quizzyjoy/vitalui，零直接 @kit。
 */
@ComponentV2
export struct AppToggle {
  /** 开关状态（父持有，经 onChange 回写）。 */
  @Param isOn: boolean = false;
  /** 是否可交互（置灰禁用）。 */
  @Param isEnabled: boolean = true;
  /** 开关圆点颜色（默认反白；一般无需覆盖）。 */
  @Param pointColor: ResourceColor = $r('app.color.qj_on_brand');
  /** 状态变化回调。 */
  @Event onChange: (isOn: boolean) => void = () => {
  };

  /** 运行时强调色单例：accentColor 非空用自定义色，空串回退品牌令牌；build 期读取即建立换肤响应。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.brandColor();
  }

  build() {
    Toggle({ type: ToggleType.Switch, isOn: this.isOn })
      .selectedColor(this.brandColor())
      .switchPointColor(this.pointColor)
      .enabled(this.isEnabled)
      .onChange((isOn: boolean): void => {
        this.onChange(isOn);
      })
  }
}
