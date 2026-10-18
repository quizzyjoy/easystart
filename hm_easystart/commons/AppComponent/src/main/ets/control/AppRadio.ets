import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppSpacing } from '@quizzyjoy/foundation';

/**
 * AppRadio —— 主题化单选框。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Radio 是系统结构原语，其选中色（radioStyle.checkedBackgroundColor）需跟随运行时强调色
 * 才换肤彻底；「单选项 + 文本标签」排布为应用表单规范 → 应用级。
 *
 * 【V2 受控】checked 由父按「当前选中值 === 本项 value」计算后传入，onChange 上抛由父更新选中值。
 *
 * 【用法】
 * AppRadio({ value: 'a', group: 'pick', checked: this.cur === 'a',
 *   label: '方案 A', onChange: () => { this.cur = 'a' } })
 *
 * 【@kit 纪律】Radio 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppRadio {
  /** 本单选项的值（必填，系统 Radio 的 value）。 */
  @Param @Require value: string;
  /** 单选分组名（同组互斥，必填）。 */
  @Param @Require group: string;
  /** 当前是否选中（父按选中值比较计算）。 */
  @Param checked: boolean = false;
  /** 右侧文本标签（空串只渲染单选框）。 */
  @Param label: string = '';
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 选中回调（父据此把选中值改为本项 value）。 */
  @Event onChange: (isChecked: boolean) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.accentColor.length > 0 ? this.theme.accentColor : $r('app.color.qj_brand');
  }

  build() {
    Row() {
      Radio({ value: this.value, group: this.group })
        .checked(this.checked)
        .radioStyle({ checkedBackgroundColor: this.brandColor() })
        .enabled(this.isEnabled)
        .onChange((isChecked: boolean): void => {
          this.onChange(isChecked);
        })

      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(AppFontSize.BODY)
          .fontColor($r('app.color.app_text_primary'))
          .margin({ left: AppSpacing.XS })
          .enabled(this.isEnabled)
      }
    }
    .alignItems(VerticalAlign.Center)
  }
}
