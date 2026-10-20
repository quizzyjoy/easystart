import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, AppStroke, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';
import { learnChapterOrDefault, LearnBlock, LearnChapter, LEARN_MISSING_CHAPTER } from '../learn/LearnContent';

/**
 * 学习 Tab · 章节详情（v3.38）。
 *
 * 渲染 learn/LearnContent 的类型化块：段落 / 代码 / 要点 / 提示。
 * 代码块走横向 Scroll（代码不折行），提示块走信息容器底色。
 * 章节不存在（旧链接或已删章节）时给空态，不白屏。
 */
@ComponentV2
export struct LearnChapterView {
  /** 章节 id（入口 pageMap 传入；对应 LearnContent 的 id）。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  @Param chapterId: string = '';
  @Local chapter: LearnChapter = LEARN_MISSING_CHAPTER;
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();

  aboutToAppear(): void {
    this.chapter = learnChapterOrDefault(this.chapterId);
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  paragraphBlock(block: LearnBlock) {
    Text(block.text)
      .fontSize(AppFontSize.BODY)
      .fontColor($r('app.color.app_text_primary'))
      .lineHeight(24)
      .width('100%')
  }

  /** 代码块行高（与 Text.lineHeight 一致；代码块高度 = 行数 × 行高）。 */
  private static readonly CODE_LINE_HEIGHT: number = 20;

  /**
   * 代码块行数 → 显式高度。
   *
   * 必须显式给高度：横向 Scroll 包在纵向 Scroll 里时，不给高度会参与父级内容测量，
   * 真机上表现为进入页面时纵向位置被顶到中段（v3.38 真机走查）。
   */
  private codeHeight(text: string): number {
    const lines: number = text.split('\n').length;
    return lines * LearnChapterView.CODE_LINE_HEIGHT;
  }

  @Builder
  codeBlock(block: LearnBlock) {
    Column() {
      Scroll() {
        Text(block.text)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_primary'))
          .lineHeight(LearnChapterView.CODE_LINE_HEIGHT)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .width('100%')
      .height(this.codeHeight(block.text))
      .nestedScroll({
        scrollForward: NestedScrollMode.SELF_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.MD)
    .backgroundColor($r('app.color.app_fill_subtle'))
  }

  @Builder
  bulletsBlock(block: LearnBlock) {
    Column({ space: AppSpacing.SM }) {
      ForEach(block.items, (item: string, index: number) => {
        Row({ space: AppSpacing.SM }) {
          Text('·')
            .fontSize(AppFontSize.BODY)
            .fontColor(this.theme.brandColor())
          Text(item)
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
            .lineHeight(22)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }, (item: string, index: number): string => `${index}_${item}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  noteBlock(block: LearnBlock) {
    Column() {
      Text(block.text)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_primary'))
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.MD)
    .backgroundColor($r('app.color.app_info_container'))
    .border({ width: { left: AppStroke.THICK }, color: this.theme.brandColor() })
  }

  @Builder
  blockItem(block: LearnBlock) {
    if (block.kind === 'code') {
      this.codeBlock(block)
    } else if (block.kind === 'list') {
      this.bulletsBlock(block)
    } else if (block.kind === 'note') {
      this.noteBlock(block)
    } else {
      this.paragraphBlock(block)
    }
  }

  @Builder
  chapterBody(chapter: LearnChapter) {
    Column({ space: AppSpacing.LG }) {
      Column({ space: AppSpacing.XS }) {
        Text(chapter.title)
          .fontSize(AppFontSize.TITLE_LG)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(`${chapter.summary} · 约 ${chapter.minutes} 分钟`)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      ForEach(chapter.blocks, (block: LearnBlock, index: number) => {
        this.blockItem(block)
      }, (block: LearnBlock, index: number): string => `${chapter.id}_${index}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
    .padding({
      left: DesignToken.pagePadding(this.bp()),
      right: DesignToken.pagePadding(this.bp()),
      top: AppSpacing.LG,
      bottom: AppSpacing.XXXL
    })
  }

  build() {
    Scroll() {
      Column() {
        if (this.chapter.blocks.length > 0) {
          this.chapterBody(this.chapter)
        } else {
          Column({ space: AppSpacing.SM }) {
            Text(this.chapter.title)
              .fontSize(AppFontSize.BODY)
              .fontColor($r('app.color.app_text_secondary'))
            Text(this.chapter.summary)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(DesignToken.pagePadding(this.bp()))
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
