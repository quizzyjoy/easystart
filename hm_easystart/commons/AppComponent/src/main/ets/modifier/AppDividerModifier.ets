import { AppStroke } from '@quizzyjoy/foundation';

/**
 * 应用级分隔线 AttributeModifier（v3.21，简单换色封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Divider 是系统结构原语，其颜色 / 粗细是应用样式决策——本 modifier 提供
 * 「可传色的简单封装」（默认 app_divider 令牌 + HAIR 细线），方便调用方按语义
 * 换色（如强调色分隔、品牌色描边）。换一个 app 分隔线配色策略就变 → 应用级。
 *
 * 【用法】Divider().attributeModifier(new AppDividerModifier())
 *         Divider().attributeModifier(new AppDividerModifier($r('app.color.qj_brand'), AppStroke.THIN))
 *
 * 【@kit 纪律】AttributeModifier / DividerAttribute 为全局类型，零 @kit。
 */
export class AppDividerModifier implements AttributeModifier<DividerAttribute> {
  /** 分隔线颜色（默认 app_divider 令牌）。 */
  color: ResourceColor;
  /** 分隔线粗细（vp，默认 HAIR 细线）。 */
  strokeWidth: number;

  constructor(color: ResourceColor = $r('app.color.app_divider'), strokeWidth: number = AppStroke.HAIR) {
    this.color = color;
    this.strokeWidth = strokeWidth;
  }

  applyNormalAttribute(instance: DividerAttribute): void {
    instance.color(this.color)
      .strokeWidth(this.strokeWidth);
  }
}
