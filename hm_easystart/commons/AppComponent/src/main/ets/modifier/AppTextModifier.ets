import { AppFontWeight, AppFontSize, AppLineHeight } from '@quizzyjoy/foundation';

/**
 * 应用级文本排版 AttributeModifier 族（v3.4，参考 EasyMath TextModifier 模式并分文件）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 排版档位与字重策略是**本应用的文本规范**——字号刻度本身在 Foundation（组织级
 * 数值令牌），但「本应用正文用 BODY+RELAXED 行高、标题用 TITLE+Bold」的组合
 * 决策是应用级 → modifier 族落 AppComponent。换一个 app 排版组合就变。
 * 字重对齐官方字阶表（v3.6 审计组 2/3）：Title=Bold、Body_M/S=Regular、Caption=Medium。
 *
 * 【用法】Text('x').attributeModifier(new AppTextBodyModifier())
 *
 * 【@kit 纪律】AttributeModifier/TextAttribute 为全局类型，零 @kit。
 */

/** 页面主标题（HEADLINE 30=Title_L + 紧凑行高 + Bold）。 */
export class AppTextHeadlineModifier implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(AppFontSize.HEADLINE)
      .fontWeight(AppFontWeight.BOLD)
      .lineHeight(AppLineHeight.for(AppFontSize.HEADLINE, AppLineHeight.TIGHT))
      .fontColor($r('app.color.app_text_primary'))
  }
}

/** 区块标题（TITLE 20=Title_S + 标准行高 + Bold）。 */
export class AppTextTitleModifier implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(AppFontSize.TITLE)
      .fontWeight(AppFontWeight.BOLD)
      .lineHeight(AppLineHeight.for(AppFontSize.TITLE, AppLineHeight.NORMAL))
      .fontColor($r('app.color.app_text_primary'))
  }
}

/** 正文（BODY 16=Body_L + 宽松行高 + Medium，官方 Body_L=Medium）。 */
export class AppTextBodyModifier implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(AppFontSize.BODY)
      .fontWeight(AppFontWeight.MEDIUM)
      .lineHeight(AppLineHeight.for(AppFontSize.BODY, AppLineHeight.RELAXED))
      .fontColor($r('app.color.app_text_primary'))
  }
}

/** 辅助说明（CAPTION 12=Caption_L + 标准行高 + Medium + 次要色）。 */
export class AppTextCaptionModifier implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(AppFontSize.CAPTION)
      .fontWeight(AppFontWeight.MEDIUM)
      .lineHeight(AppLineHeight.for(AppFontSize.CAPTION, AppLineHeight.NORMAL))
      .fontColor($r('app.color.app_text_secondary'))
  }
}

/** 展示大字（DISPLAY 48=Display_M + 紧凑行高 + Light，官方字阶 Display=Light；v3.9 补 v3.6 指派缺口）。 */
export class AppTextDisplayModifier implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(AppFontSize.DISPLAY)
      .fontWeight(AppFontWeight.LIGHT)
      .lineHeight(AppLineHeight.for(AppFontSize.DISPLAY, AppLineHeight.TIGHT))
      .fontColor($r('app.color.app_text_primary'))
  }
}

/**
 * 文字颜色简单换色（v3.21）：仅改字色、可传色，方便自由页面按语义换色。
 * 与上面固定排版档位的关系：排版档位固定主文本色；需非主文本色（强调 / 危险 /
 * 弱化）时用本 modifier 叠加或单独使用。
 */
export class AppTextColorModifier implements AttributeModifier<TextAttribute> {
  /** 文字颜色（默认主文本色）。 */
  color: ResourceColor;

  constructor(color: ResourceColor = $r('app.color.app_text_primary')) {
    this.color = color;
  }

  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontColor(this.color);
  }
}
