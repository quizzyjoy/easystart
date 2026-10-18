import { AppRadius, AppSpacing } from '@quizzyjoy/foundation';

/**
 * AppCard —— 应用级卡片容器。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「app_bg_card 底 + AppRadius.XL(16) 圆角 + AppSpacing.LG 内边距」的卡片律是
 * 本应用的页面分区规范——换一个 app 底色 / 圆角 / 内边距策略就变 → 应用级
 * （判据见指南 §17「换一个 app 还能用吗」）。结构纯 Column 布局，零 @kit。
 *
 * 【用法】AppCard() { 内容 }
 * 注意：带尾随闭包的自定义组件不能再链式属性，内容样式由内容自裹或外层容器承载。
 */
@ComponentV2
export struct AppCard {
  @BuilderParam contentBuilder: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  build() {
    Column() {
      this.contentBuilder()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .borderRadius(AppRadius.XL)
  }
}
