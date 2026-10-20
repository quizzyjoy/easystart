import { common } from '@kit.AbilityKit';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { DocRepository } from '../doc/DocRepository';
import { DocMeta } from '../doc/DocTypes';

/**
 * 学习 Tab（v3.49）：文档目录。
 *
 * 目录来自构建期生成的 `resources/rawfile/docs/index.json`——内容源头是仓根 `教程/<专题>/<专题>.md`，
 * 由 `scripts/sync-docs.mjs` 同步，应用内不再手工维护章节。详情走 AppRoute.LEARN_CHAPTER 子页。
 */
@ComponentV2
export struct LearnView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local docs: DocMeta[] = [];

  /** 打开章节详情（@Event 上抛，入口映射到路由）。 */
  @Param onOpenChapter: (chapterId: string) => void = (_chapterId: string): void => {
  };

  aboutToAppear(): void {
    this.loadDocs();
  }

  private async loadDocs(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.docs = await DocRepository.loadIndex(context);
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private indexLabel(index: number): string {
    return index < 9 ? `0${index + 1}` : `${index + 1}`;
  }

  @Builder
  chapterCard(doc: DocMeta, index: number) {
    Row({ space: AppSpacing.MD }) {
      Text(this.indexLabel(index))
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor(this.theme.brandColor())
        .width(28)
        .textAlign(TextAlign.Center)

      Column({ space: AppSpacing.XXS }) {
        Text(doc.title)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(doc.summary)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`约 ${doc.minutes} 分钟 · ${doc.sections.length} 节`)
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
      this.onOpenChapter(doc.id);
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
          Text('正文直接渲染仓库里的 Markdown（教程/ 目录），改文档即改应用内内容。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: AppSpacing.SM }) {
          ForEach(this.docs, (doc: DocMeta, index: number) => {
            this.chapterCard(doc, index)
          }, (doc: DocMeta): string => doc.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.docs.length === 0) {
          Text('未找到文档：请先在仓根执行 node scripts/sync-docs.mjs 同步教程。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
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
