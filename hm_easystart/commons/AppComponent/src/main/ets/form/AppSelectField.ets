import {
  AppFontSize,
  AppFontWeight,
  AppRadius,
  AppSize,
  AppSpacing,
  AppStroke
} from '@quizzyjoy/foundation';

/**
 * AppSelectField —— 带标签的下拉选择域（只读显示 + 点按上抛，父弹选择器）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「标签在上 + 只读框 + 右侧下箭头 + 错误/辅助说明」的选择域排布是本应用
 * 表单交互规范 → 应用级（判据见指南 §17）。组件只负责展示与点按上抛
 * （onClick），具体选项弹层（SuffixSelect / Sheet / 自绘菜单）由父装配，
 * 避免把选择器实现绑死进组件。输入原语为系统 Row/Text/SymbolGlyph，零 @kit。
 *
 * 【用法】AppSelectField({ label: '性别', value: this.genderLabel,
 *   onSelect: (): void => { this.showGenderSheet = true } })
 */
@ComponentV2
export struct AppSelectField {
  /** 输入域标签（CAPTION + Medium + 次要色；空串不渲染标签行）。 */
  @Param label: string = '';
  /** 当前选中项展示文本（空串显示占位）。 */
  @Param value: string = '';
  /** 占位提示文案（value 为空时显示）。 */
  @Param placeholder: string = '';
  /** 校验错误文案（非空时描边转危险色并显示错误行）。 */
  @Param errorText: string = '';
  /** 辅助说明文案（errorText 为空时显示）。 */
  @Param supportingText: string = '';
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 点按回调（父弹选择器）。 */
  @Event onSelect: () => void = () => {
  };

  private strokeColor(): ResourceColor {
    return this.errorText.length > 0 ? $r('app.color.app_danger') : $r('app.color.app_divider');
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
      Row() {
        Text(this.value.length > 0 ? this.value : this.placeholder)
          .fontSize(AppFontSize.BODY)
          .fontColor(this.value.length > 0 ? $r('app.color.app_text_primary') : $r('app.color.app_text_tertiary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(AppSize.ICON_SM)
          .fontColor([$r('app.color.app_text_tertiary')])
      }
      .width('100%')
      .height(AppSize.TOUCH_STANDARD)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .backgroundColor($r('app.color.app_fill_subtle'))
      .borderRadius(AppRadius.XXL)
      .border({ width: AppStroke.THIN, color: this.strokeColor() })
      .enabled(this.isEnabled)
      .onClick((): void => {
        if (this.isEnabled) {
          this.onSelect();
        }
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
