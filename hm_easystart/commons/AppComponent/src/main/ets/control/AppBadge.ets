import { AppFontSize } from '@quizzyjoy/foundation';

/**
 * AppBadge —— 应用级徽标（Badge 组件封装，适配设计令牌）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Badge 是系统结构原语，但其颜色在构造参数 style（badgeColor / color）里、无法用
 * AttributeModifier 换色——本封装把标记色 / 文本色 / 字号 / 大小统一收口到应用
 * 令牌（默认 app_danger 标记 + qj_on_brand 反白 + CAPTION_XS 字号），换一个 app
 * 徽标配色与尺寸策略就变 → 应用级。
 *
 * 【用法】数字标记：AppBadge({ count: 5 }) { 被标记组件 }
 *         字符串标记：AppBadge({ value: 'New' }) { 被标记组件 }
 *         品牌色徽标：AppBadge({ count: 5, badgeColor: $r('app.color.qj_brand') }) { ... }
 * 注意：带尾随闭包的自定义组件不能再链式属性，被标记组件需自行设宽高。
 *
 * 【@kit 纪律】Badge / BadgePosition 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppBadge {
  /** 数字标记数（≤0 且无 value 时不显示）。 */
  @Param count: number = 0;
  /** 字符串标记文本（非空优先于 count；空串且 count>0 时按数字标记）。 */
  @Param value: string = '';
  /** 数字标记最大显示值（超过显示 maxCount+）。 */
  @Param maxCount: number = 99;
  /** 标记显示位置。 */
  @Param badgePosition: BadgePosition = BadgePosition.RightTop;
  /** 标记底色（默认 app_danger 令牌；可按语义换色如品牌/成功）。 */
  @Param badgeColor: ResourceColor = $r('app.color.app_danger');
  /** 标记文本色（默认反白令牌）。 */
  @Param textColor: ResourceColor = $r('app.color.qj_on_brand');
  /** 标记大小（vp，默认 16）。 */
  @Param badgeSize: number = 16;
  /** 标记字号（默认 CAPTION_XS）。 */
  @Param fontSize: number = AppFontSize.CAPTION_XS;
  /** 被标记组件（尾随闭包注入）。 */
  @BuilderParam contentBuilder: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  build() {
    if (this.value.length > 0) {
      Badge({
        value: this.value,
        position: this.badgePosition,
        style: {
          badgeColor: this.badgeColor,
          color: this.textColor,
          badgeSize: this.badgeSize,
          fontSize: this.fontSize
        } as BadgeStyle
      }) {
        this.contentBuilder()
      }
    } else {
      Badge({
        count: this.count,
        maxCount: this.maxCount,
        position: this.badgePosition,
        style: {
          badgeColor: this.badgeColor,
          color: this.textColor,
          badgeSize: this.badgeSize,
          fontSize: this.fontSize
        } as BadgeStyle
      }) {
        this.contentBuilder()
      }
    }
  }
}
