import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppSelect —— 主题化下拉选择（Select 简易封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Select 是系统结构原语，其选中项高亮（selectedOptionBgColor/FontColor）裸用不随
 * 运行时强调色变化——本封装把选中项背景 / 文字统一收口到 accent（选中底品牌色 +
 * 反白字），换一个 app 选中态配色就变 → 应用级。与 AppSelectField 的分工：
 * AppSelectField 是「只读框 + 点按上抛」的表单域；本件是「原生下拉」的简易换肤封装。
 *
 * 【V2 受控】selectedIndex 由父持有，onSelect 上抛父回写。
 *
 * 【用法】AppSelect({ options: ['A', 'B', 'C'], selectedIndex: this.idx,
 *   onSelect: (i: number): void => { this.idx = i } })
 *
 * 【@kit 纪律】Select 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppSelect {
  /** 选项文本集合。 */
  @Param options: string[] = [];
  /** 当前选中下标（父持有）。 */
  @Param selectedIndex: number = 0;
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 选中回调（index 为选中下标，value 为选中文本）。 */
  @Event onSelect: (index: number, value: string) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.accentColor.length > 0 ? this.theme.accentColor : $r('app.color.qj_brand');
  }

  private currentValue(): string {
    return this.selectedIndex >= 0 && this.selectedIndex < this.options.length
      ? this.options[this.selectedIndex] : '';
  }

  build() {
    Select(this.options.map((v: string) => ({ value: v }) as SelectOption))
      .selected(this.selectedIndex)
      .value(this.currentValue())
      .selectedOptionBgColor(this.brandColor())
      .selectedOptionFontColor($r('app.color.qj_on_brand'))
      .fontColor($r('app.color.app_text_primary'))
      .onSelect((index: number, value: string): void => {
        this.onSelect(index, value);
      })
      .enabled(this.isEnabled)
  }
}
