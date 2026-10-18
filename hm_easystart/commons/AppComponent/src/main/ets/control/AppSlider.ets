import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppSlider —— 主题化滑杆。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Slider 是系统结构原语，其已选轨道色（selectedColor）与滑块手柄色（blockColor）需跟随
 * 运行时强调色才换肤彻底；未选轨道统一收口到应用填充令牌 → 应用级。
 *
 * 【V2 受控】value 由父持有，onChange 上抛父回写（拖动连续回调，父直接 setState 即可）。
 * 注意：@Event onChange 必须在构造参数对象内传，不能像原生 Slider 那样链式 .onChange()。
 *
 * 【用法】AppSlider({ value: this.gain, min: 0, max: 100, step: 1,
 *   onChange: (v: number): void => { this.gain = v } })
 *
 * 【@kit 纪律】Slider / SliderChangeMode 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppSlider {
  /** 当前值（父持有，经 onChange 回写）。 */
  @Param value: number = 0;
  /** 最小值。 */
  @Param min: number = 0;
  /** 最大值。 */
  @Param max: number = 100;
  /** 步长（默认 1）。 */
  @Param step: number = 1;
  /** 轨道厚度（vp，默认 4，统一应用规范；需要更粗可覆盖，如频率条传 6）。 */
  @Param trackThickness: number = 4;
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 值变化回调（携带变化模式：拖动中 / 点击跳转 / 释放）。 */
  @Event onChange: (value: number, mode: SliderChangeMode) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.accentColor.length > 0 ? this.theme.accentColor : $r('app.color.qj_brand');
  }

  build() {
    Slider({ value: this.value, min: this.min, max: this.max, step: this.step })
      .selectedColor(this.brandColor())
      .trackColor($r('app.color.app_fill_medium'))
      .blockColor(this.brandColor())
      .trackThickness(this.trackThickness)
      .enabled(this.isEnabled)
      .onChange((value: number, mode: SliderChangeMode): void => {
        this.onChange(value, mode);
      })
  }
}
