import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppRadius } from '@quizzyjoy/foundation';

/**
 * AppSearch —— 主题化搜索框（Search 简易封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Search 是系统结构原语，其光标 / 占位 / 输入底色需与全应用统一——本封装把光标色
 * 收口到运行时 accent、占位与底色收口到应用令牌，换一个 app 搜索框配色就变 → 应用级。
 * 与 VitalUI CommonSearchBar 的分工：CommonSearchBar 是「自定义搜索栏组件」（业务定制，
 * 含防抖 / 取消钮）；本件是「系统 Search 的换肤基础封装」，边界同 CommonLoading。
 *
 * 【V2 受控】value 由父持有，onChange / onSubmit 上抛父回写。
 *
 * 【用法】AppSearch({ value: this.q, placeholder: '搜索',
 *   onChange: (v: string): void => { this.q = v }, onSubmit: (v: string): void => { ... } })
 *
 * 【@kit 纪律】Search 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppSearch {
  /** 受控值（父持有，经 onChange 回写）。 */
  @Param value: string = '';
  /** 占位提示文案。 */
  @Param placeholder: string = '';
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 输入变化回调。 */
  @Event onChange: (value: string) => void = () => {
  };
  /** 提交（回车 / 搜索键）回调。 */
  @Event onSubmit: (value: string) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.brandColor();
  }

  build() {
    Search({ value: this.value, placeholder: this.placeholder })
      .caretStyle({ width: 2, color: this.brandColor() })
      .placeholderColor($r('app.color.app_text_tertiary'))
      .placeholderFont({ size: AppFontSize.BODY })
      .textFont({ size: AppFontSize.BODY })
      .backgroundColor($r('app.color.app_fill_subtle'))
      .borderRadius(AppRadius.XXL)
      .enabled(this.isEnabled)
      .onChange((value: string): void => {
        this.onChange(value);
      })
      .onSubmit((value: string): void => {
        this.onSubmit(value);
      })
  }
}
