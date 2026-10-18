import { AppFontSize, AppFontWeight, AppSize, AppSpacing } from '@quizzyjoy/foundation';
import { AppButtonPrimaryModifier } from '../modifier/AppButtonModifier';

/**
 * AppEmptyState —— 应用级空态（无数据 / 无结果占位）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「图标 + 标题 + 说明 + 可选主操作」的空态排布律、图标档位（ICON_XXL）、
 * 主操作走 AppButtonPrimaryModifier 是本应用的空态规范——换一个 app 空态文案
 * 与操作策略就变 → 应用级（判据见指南 §17）。ListStateView 四态里的 EMPTY
 * 态此前无组件封装，本组件补齐该范式。
 *
 * 【用法】AppEmptyState({ title: '暂无数据', description: '换个关键词试试',
 *   actionText: '刷新', onAction: () => { ... } })
 *
 * 【@kit 纪律】SymbolGlyph / Text / Button 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppEmptyState {
  /** 空态图标（默认文档；可换搜索 / 收藏等语义符号）。 */
  @Param icon: Resource = $r('sys.symbol.doc_text');
  /** 主标题（TITLE 档 + Bold；空串不渲染）。 */
  @Param title: string = '';
  /** 说明文案（CAPTION 档 + 次要色；空串不渲染）。 */
  @Param description: string = '';
  /** 可选主操作按钮文案（空串不渲染按钮）。 */
  @Param actionText: string = '';
  /** 主操作回调。 */
  @Event onAction: () => void = () => {
  };

  build() {
    Column({ space: AppSpacing.MD }) {
      SymbolGlyph(this.icon)
        .fontSize(AppSize.ICON_XXL)
        .fontColor([$r('app.color.app_text_tertiary')])

      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(AppFontSize.TITLE)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
          .textAlign(TextAlign.Center)
      }

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .textAlign(TextAlign.Center)
      }

      if (this.actionText.length > 0) {
        Button(this.actionText)
          .attributeModifier(new AppButtonPrimaryModifier())
          .margin({ top: AppSpacing.SM })
          .onClick((): void => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding(AppSpacing.XXXL)
  }
}
