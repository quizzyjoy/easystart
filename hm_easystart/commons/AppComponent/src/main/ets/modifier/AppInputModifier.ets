import { AppFontSize, AppRadius, AppSize, AppSpacing } from '@quizzyjoy/foundation';

/**
 * 应用级输入框 AttributeModifier（v3.21，续 AppButton/AppText modifier 族）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「BODY 字号 + fill_subtle 底 + caret 品牌色 + XXL 圆角 + 48vp 高」是**本应用的
 * 输入框样式决策**——换一个 app 输入框配色与尺寸策略就变 → 应用级。与
 * AppFormField 的关系：AppFormField 是「带标签 + 校验态的完整表单域」，本 modifier
 * 提供「裸 TextInput 的基础样式」（不含动态描边，描边由调用方按态覆盖）。
 *
 * 【用法】TextInput({ text: this.q, placeholder: '搜索' })
 *   .attributeModifier(new AppInputModifier())
 *
 * 【@kit 纪律】AttributeModifier / TextInputAttribute 为全局类型，零 @kit。
 */
export class AppInputModifier implements AttributeModifier<TextInputAttribute> {
  applyNormalAttribute(instance: TextInputAttribute): void {
    instance.fontSize(AppFontSize.BODY)
      .fontColor($r('app.color.app_text_primary'))
      .placeholderColor($r('app.color.app_text_tertiary'))
      .backgroundColor($r('app.color.app_fill_subtle'))
      .caretColor($r('app.color.qj_brand'))
      .height(AppSize.TOUCH_STANDARD)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .borderRadius(AppRadius.XXL)
  }
}
