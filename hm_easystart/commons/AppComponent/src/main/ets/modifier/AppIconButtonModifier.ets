import { AppRadius, AppSize } from '@quizzyjoy/foundation';
import { AppThemeApplier } from '../theme/AppThemeApplier';

/**
 * 应用级图标按钮 AttributeModifier（v3.21，续 AppButton/AppText modifier 族）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「fill_subtle 底 + 全圆角 + 40vp 触摸目标」是**本应用的图标按钮样式决策**——
 * 换一个 app 图标按钮底色与热区策略就变 → 应用级。图标色由按钮内容
 * （SymbolGlyph.fontColor）在调用方按语义决定（激活态可绑 accent），本 modifier
 * 只管容器外观，保持单一职责。
 *
 * 【用法】Button({ type: ButtonType.Circle }) { SymbolGlyph($r('sys.symbol.plus'))
 *   .fontSize(AppSize.ICON_SM).fontColor([AppThemeApplier.brandColor()]) }
 *   .attributeModifier(new AppIconButtonModifier())
 *
 * 【@kit 纪律】AttributeModifier / ButtonAttribute 为全局类型，零 @kit。
 */
export class AppIconButtonModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.width(AppSize.TOUCH_MIN)
      .height(AppSize.TOUCH_MIN)
      .backgroundColor($r('app.color.app_fill_subtle'))
      .borderRadius(AppRadius.FULL)
      .padding(0)
  }
}
