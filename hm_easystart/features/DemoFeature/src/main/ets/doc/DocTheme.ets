import { MarkdownController } from '@luvi/lv-markdown-in';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppRadius, AppSpacing } from '@quizzyjoy/foundation';

/**
 * 把 Markdown 组件的样式接到工程主题上。
 *
 * 三方库自带一套默认配色，若不管它，切主题时正文不会跟着变——这正是"三方 UI 必须做主题隔离"
 * 的典型场景：库的样式 API 是入口，我们的 `UiThemeManager` 是唯一取色来源。
 */
export class DocTheme {
  /** 依据当前主题生成（或复用）控制器样式。切主题后需重新调用一次。 */
  static style(theme: UiThemeManager): MarkdownController {
    const controller: MarkdownController = new MarkdownController();
    controller
      .setTitleColor($r('app.color.app_text_primary'))
      .setTextColor($r('app.color.app_text_primary'))
      .setTextSize(AppFontSize.BODY)
      .setInlineCodeColor(theme.brandColor())
      .setInlineCodeBackgroundColor(theme.brandSoftColor())
      .setInlineCodeBackgroundRadius(AppRadius.SM)
      .setQuoteTextColor($r('app.color.app_text_secondary'))
      .setQuoteBorderColor(theme.brandColor())
      .setQuoteBackgroundColor(theme.brandSoftColor())
      .setQuoteBorderRadius(AppRadius.MD)
      .setCodeBlockBorderRadius(AppRadius.MD)
      .setCodeBlockActionAreaVisible(false)
      .setImageBorderRadius(AppRadius.MD)
      .setImageMaxWidth('100%')
      .setHyperlinkTextColor(theme.brandColor())
      .setTableOuterBorderColor($r('app.color.app_divider'))
      .setTableInnerBorderColor($r('app.color.app_divider'))
      .setTableTitleBackgroundColor($r('app.color.app_bg_page_deep'))
      .setTableBorderRadius(AppRadius.MD)
      .setTableAlign(FlexAlign.Start);
    return controller;
  }

  /** 正文两侧留白（与页面 padding 一致，避免表格贴边）。 */
  static padding(): Padding {
    return { left: AppSpacing.XS, right: AppSpacing.XS };
  }
}
