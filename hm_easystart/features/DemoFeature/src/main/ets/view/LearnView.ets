import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { LEARN_CHAPTERS, LearnChapter } from '../learn/LearnContent';

/**
 * 学习 Tab（v3.38）：教学文档章节目录。
 *
 * 每章对应本工程里真实存在的代码（内容在 learn/LearnContent.ets，类型化数据、零运行时 IO）。
 * 章节详情走 AppRoute.LEARN_CHAPTER 子页；fork 后整目录替换为自己的教程即可。
 */
@ComponentV2
export struct LearnView {
  /** 打开章节详情（@Event 上抛，入口映射到路由）。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  @Param onOpenChapter: (chapterId: string) => void = (_chapterId: string): void => {
  };
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private indexLabel(index: number): string {
    return index < 9 ? `0${index + 1}` : `${index + 1}`;
  }

  @Builder
  chapterCard(chapter: LearnChapter, index: number) {
    Row({ space: AppSpacing.MD }) {
      Text(this.indexLabel(index))
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor(this.theme.brandColor())
        .width(28)
        .textAlign(TextAlign.Center)

      Column({ space: AppSpacing.XXS }) {
        Text(chapter.title)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(chapter.summary)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`约 ${chapter.minutes} 分钟`)
          .fontSize(AppFontSize.CAPTION_XS)
          .fontColor($r('app.color.app_text_quaternary'))
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppFontSize.TITLE_SM)
        .fontColor([$r('app.color.app_text_tertiary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.onOpenChapter(chapter.id);
    })
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.SM }) {
          Text('跟着模板学鸿蒙')
            .fontSize(AppFontSize.TITLE_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('每章都对应本工程里真实存在的代码：读完可直接打开源码对照，不是抽象教程。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: AppSpacing.SM }) {
          ForEach(LEARN_CHAPTERS, (chapter: LearnChapter, index: number) => {
            this.chapterCard(chapter, index)
          }, (chapter: LearnChapter): string => chapter.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        // Tab 页统一避让：悬浮页签栏 + 手势条（barOverlap 下内容会延伸到底部 bar 之后）
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
