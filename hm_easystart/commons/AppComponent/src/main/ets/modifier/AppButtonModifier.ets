import { AppFontWeight, AppFontSize, AppRadius, AppStroke, AppSpacing } from '@quizzyjoy/foundation';

/**
 * 应用级按钮 AttributeModifier 族（v3.4，参考 EasyMath ButtonModifier 模式并分文件）。
 *
 * 【落位注释：为什么 modifier 在 AppComponent 而不是 VitalUI？】
 * modifier 的价值在「**本应用的样式决策**」——哪几档按钮语义、圆角用 XXL(20)、
 * 字重用 Medium，这是应用规范不是结构原语（结构原语 = CommonButton 组件本身，在
 * VitalUI）。换一个 app 档位与配色策略就变 → 应用级。
 *
 * 【用法】`.attributeModifier(new AppButtonPrimaryModifier())`；
 * 与 CommonButton 结构体并存：需要组件级封装用 CommonButton，
 * 需要在原生 Button 上套应用样式用本 modifier 族。
 *
 * 【@kit 纪律】AttributeModifier/ButtonAttribute 为全局类型，零 @kit。
 */

/** 主操作：品牌底 + 品牌上前景。 */
export class AppButtonPrimaryModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor($r('app.color.qj_brand'))
      .fontColor($r('app.color.qj_on_brand'))
      .fontSize(AppFontSize.BODY_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .borderRadius(AppRadius.XXL)
      .padding({ left: AppSpacing.XL, right: AppSpacing.XL, top: AppSpacing.MD, bottom: AppSpacing.MD })
  }
}

/** 次操作：中填充底 + 主文本。 */
export class AppButtonSecondaryModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor($r('app.color.app_fill_medium'))
      .fontColor($r('app.color.app_text_primary'))
      .fontSize(AppFontSize.BODY_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .borderRadius(AppRadius.XXL)
      .padding({ left: AppSpacing.XL, right: AppSpacing.XL, top: AppSpacing.MD, bottom: AppSpacing.MD })
  }
}

/** 幽灵操作：透明底 + 品牌文本 + 品牌描边。 */
export class AppButtonGhostModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(Color.Transparent)
      .fontColor($r('app.color.qj_brand'))
      .fontSize(AppFontSize.BODY_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .borderRadius(AppRadius.XXL)
      .border({ width: AppStroke.THIN, color: $r('app.color.qj_brand') })
      .padding({ left: AppSpacing.XL, right: AppSpacing.XL, top: AppSpacing.MD, bottom: AppSpacing.MD })
  }
}

/** 危险操作：危险底 + 反白。 */
export class AppButtonDangerModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance: ButtonAttribute): void {
    instance      .backgroundColor($r('app.color.app_danger'))
      .fontColor($r('app.color.qj_on_brand'))
      .fontSize(AppFontSize.BODY_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .borderRadius(AppRadius.XXL)
      .padding({ left: AppSpacing.XL, right: AppSpacing.XL, top: AppSpacing.MD, bottom: AppSpacing.MD })
  }
}
