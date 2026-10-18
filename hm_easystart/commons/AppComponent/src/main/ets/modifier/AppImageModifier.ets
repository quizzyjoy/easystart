import { AppRadius } from '@quizzyjoy/foundation';

/**
 * 应用级图片 AttributeModifier（v3.21，简单样式封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Image 是系统结构原语，其圆角是应用图片规范——本 modifier 提供「可传圆角的
 * 简单封装」（默认 AppRadius.MD），方便调用方统一头像 / 缩略图 / 卡图圆角。
 * 换一个 app 图片圆角策略就变 → 应用级。
 *
 * 【用法】Image($r('app.media.xxx')).attributeModifier(new AppImageModifier())
 *         Image($r('app.media.xxx')).attributeModifier(new AppImageModifier(AppRadius.FULL))
 *
 * 【@kit 纪律】AttributeModifier / ImageAttribute 为全局类型，零 @kit。
 */
export class AppImageModifier implements AttributeModifier<ImageAttribute> {
  /** 图片圆角（vp，默认 MD）。 */
  borderRadius: number;

  constructor(borderRadius: number = AppRadius.MD) {
    this.borderRadius = borderRadius;
  }

  applyNormalAttribute(instance: ImageAttribute): void {
    instance.borderRadius(this.borderRadius);
  }
}
