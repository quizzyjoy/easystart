import {
  AppFontSize,
  AppFontWeight,
  AppRadius,
  AppSpacing,
  AppStroke
} from '@quizzyjoy/foundation';
import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppTextArea —— 带标签与校验态的多行文本域（应用级表单交互规范，续 AppFormField）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 多行输入的「标签在上 + 危险态红线 + 校验/辅助说明行」排布与 AppFormField 同律，
 * 属本应用表单交互规范 → 应用级（判据见指南 §17）。输入原语为系统 TextArea
 * （全局类型），本文件零 @kit。
 *
 * 【V2 单向绑定】value 由父持有回写（onValueChange 上抛），不用 $$。
 *
 * 【用法】AppTextArea({ label: '备注', value: this.remark,
 *   onValueChange: (v: string): void => { this.remark = v } })
 */
@ComponentV2
export struct AppTextArea {
  /** 输入域标签（CAPTION + Medium + 次要色；空串不渲染标签行）。 */
  @Param label: string = '';
  /** 受控值（父持有，经 onValueChange 回写）。 */
  @Param value: string = '';
  /** 占位提示文案。 */
  @Param placeholder: string = '';
  /** 校验错误文案（非空时输入框描边/文字转危险色并显示错误行）。 */
  @Param errorText: string = '';
  /** 辅助说明文案（errorText 为空时显示）。 */
  @Param supportingText: string = '';
  /** 最大输入长度。 */
  @Param maxLength: number = 500;
  /** 输入区最小高度（vp，默认 120）。 */
  @Param minHeight: number = 120;
  /** 输入变化回调（父回写 value 实现受控）。 */
  @Event onValueChange: (value: string) => void = () => {
  };

  /** 聚焦态（聚焦描边转强调色；V2 局部状态）。 */
  @Local focused: boolean = false;
  /** 运行时强调色单例（聚焦描边 / 光标随强调色换肤）。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.brandColor();
  }

  private strokeColor(): ResourceColor {
    if (this.errorText.length > 0) {
      return $r('app.color.app_danger');
    }
    if (this.focused) {
      return this.brandColor();
    }
    return $r('app.color.app_divider');
  }

  build() {
    Column({ space: AppSpacing.XS }) {
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(AppFontSize.CAPTION)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
      }
      TextArea({ text: this.value, placeholder: this.placeholder })
        .fontSize(AppFontSize.BODY)
        .fontColor($r('app.color.app_text_primary'))
        .placeholderColor($r('app.color.app_text_tertiary'))
        .backgroundColor($r('app.color.app_fill_subtle'))
        .caretColor(this.brandColor())
        .constraintSize({ minHeight: this.minHeight })
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.XL)
        .border({ width: AppStroke.THIN, color: this.strokeColor() })
        .maxLength(this.maxLength)
        .onChange((val: string) => {
          this.onValueChange(val);
        })
        .onFocus(() => {
          this.focused = true;
        })
        .onBlur(() => {
          this.focused = false;
        })
      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_danger'))
          .width('100%')
      } else if (this.supportingText.length > 0) {
        Text(this.supportingText)
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
