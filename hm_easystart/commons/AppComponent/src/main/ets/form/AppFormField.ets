import {
  AppFontSize,
  AppFontWeight,
  AppRadius,
  AppSize,
  AppSpacing,
  AppStroke
} from '@quizzyjoy/foundation';
import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppFormField —— 带标签与校验态的输入域（v3.9，应用级表单交互规范）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「标签在输入框上方 + 危险态红线 + 校验/辅助说明行」的表单排布与错误语义是
 * 本应用的交互规范——换一个 app 标签位置与错误色策略就变 → 应用级
 * （判据见指南 §17「换一个 app 还能用吗」）。输入原语为系统 TextInput
 * （全局类型），本文件零 @kit。
 *
 * 【V2 单向绑定】value 由父持有回写（onValueChange 上抛），不用 $$。
 *
 * 【用法】AppFormField({ label: '名称', value: this.name, errorText: this.nameError,
 * onValueChange: (v: string) => { this.name = v; } })
 */
@ComponentV2
export struct AppFormField {
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
  @Param maxLength: number = 64;
  /** 输入变化回调（父回写 value 实现受控）。 */
  @Event onValueChange: (value: string) => void = () => {
  };

  /** 聚焦态（聚焦描边转强调色；V2 局部状态）。 */
  @Local focused: boolean = false;
  /** 运行时强调色单例（聚焦描边 / 光标随强调色换肤）。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.accentColor.length > 0 ? this.theme.accentColor : $r('app.color.qj_brand');
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
      TextInput({ text: this.value, placeholder: this.placeholder })
        .fontSize(AppFontSize.BODY)
        .fontColor($r('app.color.app_text_primary'))
        .placeholderColor($r('app.color.app_text_tertiary'))
        .backgroundColor($r('app.color.app_fill_subtle'))
        .caretColor(this.brandColor())
        .height(AppSize.TOUCH_STANDARD)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .borderRadius(AppRadius.XXL)
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
