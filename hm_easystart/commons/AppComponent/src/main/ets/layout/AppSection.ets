import { AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { AppTextCaptionModifier, AppTextTitleModifier } from '../modifier/AppTextModifier';

/**
 * AppSection —— 应用级区块容器（v3.9）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「节标题 + 可选说明 + 内容」的排布律与节间距（DesignToken.sectionSpacing）是
 * 本应用的页面分区规范——换一个 app 标题档位与间距律就变 → 应用级
 * （AppDialog 先例：结构原语在 VitalUI，应用语义在应用级）。结构纯布局
 * （Column/Text），零 @kit。
 *
 * 【用法】AppSection({ sectionTitle: '标题', description: '说明' }) { 内容 }
 * 注意：带尾随闭包的自定义组件不能再链式属性，内容样式由内容自裹或外层容器承载。
 *
 * 【@kit 纪律】Column/Text 为全局组件类型，零 @kit。
 */
@ComponentV2
export struct AppSection {
  /** 区块标题（TITLE 档 + Bold；空串不渲染标题行）。 */
  @Param sectionTitle: string = '';
  /** 可选说明行（CAPTION 档 + 次要色；空串不渲染）。 */
  @Param description: string = '';
  /** 内容插槽（尾随闭包注入）。 */
  @BuilderParam contentBuilder: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  build() {
    Column() {
      if (this.sectionTitle.length > 0) {
        Text(this.sectionTitle)
          .attributeModifier(new AppTextTitleModifier())
          .width('100%')
      }
      if (this.description.length > 0) {
        Text(this.description)
          .attributeModifier(new AppTextCaptionModifier())
          .width('100%')
          .margin({ top: AppSpacing.XS })
      }
      Column() {
        this.contentBuilder()
      }
      .width('100%')
      .margin({ top: AppSpacing.MD })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ top: DesignToken.sectionSpacing() })
  }
}
