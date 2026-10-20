import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import { common } from '@kit.AbilityKit';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';
import { DocMeta } from '../doc/DocTypes';
import { DocRepository } from '../doc/DocRepository';
import { DocTheme } from '../doc/DocTheme';

/**
 * 学习 Tab · 文档详情（v3.49）。
 *
 * 正文不再由代码内联，而是直接渲染 `resources/rawfile/docs/<专题>/<专题>.md`：
 * 内容来自仓根 `教程/` 的同一份 Markdown（构建前由 `scripts/sync-docs.mjs` 同步），
 * 解析与排版交给三方库 `@luvi/lv-markdown-in`（`mode: 'rawfile'`），
 * 颜色/圆角/字号则由 `DocTheme` 映射到运行时主题，切主题时正文一起变。
 */
@ComponentV2
export struct LearnChapterView {
  /** 运行时主题：正文配色跟随换肤。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 章节 id（路由参数，对应 `教程/<专题>/<专题>.md`）。 */
  @Param chapterId: string = '';
  /** 解析后的文档元数据；未命中时为空态。 */
  @Local doc: DocMeta | undefined = undefined;
  /** 三方渲染器控制器（样式由 DocTheme 生成）。 */
  @Local controller: MarkdownController = DocTheme.style(UiThemeManager.getInstance());

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private hostContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.resolveDoc();
  }

  private async resolveDoc(): Promise<void> {
    const docs: DocMeta[] = await DocRepository.loadIndex(this.hostContext());
    this.doc = DocRepository.find(docs, this.chapterId);
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        // 标题与目录已由 Markdown 自身渲染，这里不再重复绘制
        if (this.doc === undefined) {
          Text('未找到该文档，请返回学习 Tab 重新选择。')
            .fontSize(AppFontSize.BODY)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
        } else {
          Markdown({
            controller: this.controller,
            mode: 'rawfile',
            rawfilePath: this.doc.path,
            context: this.hostContext()
          })
            .width('100%')
            .padding(DocTheme.padding())
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: DesignToken.tabPageBottomPadding(this.bp(), 0)
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
