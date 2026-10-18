import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppSpacing } from '@quizzyjoy/foundation';

/**
 * AppCheckbox —— 主题化复选框。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Checkbox 是系统结构原语，但其选中色（selectedColor）需跟随运行时强调色才换肤彻底；
 * 同时「复选框 + 文本标签」的排布是应用表单规范 → 应用级。
 *
 * 【V2 受控】isChecked 由父持有，onChange 上抛回写。
 *
 * 【用法】
 * 纯框：AppCheckbox({ isChecked: this.agree, onChange: (v) => { this.agree = v } })
 * 带标签：AppCheckbox({ label: '记住选择', isChecked: this.agree, onChange: ... })
 * 多选分组：传同一 group（配合系统 CheckboxGroup 语义）。
 *
 * 【@kit 纪律】Checkbox 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppCheckbox {
  /** 选中态（父持有，经 onChange 回写）。 */
  @Param isChecked: boolean = false;
  /** 多选分组名（同组 Checkbox 联动，透传系统 Checkbox 的 group）。 */
  @Param group: string = '';
  /** 复选框名称（系统 name，参与分组勾选集合）。 */
  @Param name: string = '';
  /** 右侧文本标签（空串只渲染复选框）。 */
  @Param label: string = '';
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 勾选状态变化回调。 */
  @Event onChange: (isChecked: boolean) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.accentColor.length > 0 ? this.theme.accentColor : $r('app.color.qj_brand');
  }

  build() {
    Row() {
      Checkbox({ name: this.name, group: this.group.length > 0 ? this.group : undefined })
        .select(this.isChecked)
        .selectedColor(this.brandColor())
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
