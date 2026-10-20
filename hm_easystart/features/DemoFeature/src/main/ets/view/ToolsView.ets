import { CommonToast } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { DevToolItem, DevToolStatus, DevToolSymbol, devTools } from '../model/DevToolItem';

/**
 * 开发工具 Tab（v3.41：单列表 → 网格卡片）。
 *
 * 结构：分组标题 + `Grid` 卡片网格（列数随断点变化：sm 2 列 / md 3 列 / lg·xl 4 列）。
 * 卡片承载「工具入口」，已实现的点击进面板，待实现的灰显并给提示——避免点了没反应。
 *
 * 【为什么 Grid 要显式高度】Grid 放在 Scroll 里高度无上界，会塌成 0；这里按
 * 「行数 × 行高 + 行间距」算出固定高度，卡片内容用 maxLines 收口，不做内部滚动。
 */
@ComponentV2
export struct ToolsView {
  @Param onOpenDeviceCapability: () => void = (): void => {
  };
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local tools: DevToolItem[] = devTools();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 列数：窄屏 2 列，中屏 3 列，宽屏 4 列。 */
  private columns(): number {
    const bp: string = this.bp();
    if (bp === 'sm') {
      return 2;
    }
    if (bp === 'md') {
      return 3;
    }
    return 4;
  }

  /** 网格高度 = 行数 × 行高 + 行间距（行高与卡片一致，见 CARD_HEIGHT）。 */
  private gridHeight(): number {
    const rows: number = Math.ceil(this.tools.length / this.columns());
    return rows * ToolsView.CARD_HEIGHT + (rows - 1) * ToolsView.CARD_GAP;
  }

  private columnsTemplate(): string {
    const n: number = this.columns();
    const parts: string[] = [];
    for (let i = 0; i < n; i++) {
      parts.push('1fr');
    }
    return parts.join(' ');
  }

  /** 图标映射：model 存枚举，视图换 Resource（$r 不能动态拼接）。 */
  private symbolOf(symbol: DevToolSymbol): Resource {
    if (symbol === DevToolSymbol.PALETTE) {
      return $r('sys.symbol.paintpalette');
    }
    if (symbol === DevToolSymbol.GRID) {
      return $r('sys.symbol.square_grid_2x2');
    }
    return $r('sys.symbol.display');
  }

  private tintOf(status: DevToolStatus): Resource {
    return status === DevToolStatus.READY ? $r('app.color.qj_brand') : $r('app.color.app_bg_page');
  }

  private iconColorOf(status: DevToolStatus): Resource {
    return status === DevToolStatus.READY ? $r('app.color.app_text_on_brand') : $r('app.color.app_text_tertiary');
  }

  private onTap(item: DevToolItem): void {
    if (item.status === DevToolStatus.READY) {
      this.onOpenDeviceCapability();
      return;
    }
    // 待实现：明确告知去哪看参考实现，避免「点了没反应」。
    // 用 CommonToast（EntryAbility 已 attach）而非 AppSnackBar：后者在本页取不到宿主色票，
    // 真机实测不显示且报 GetColorById id=-1。
    CommonToast.info(`${item.title} 待实现：参考实现见 docs/权威参考与开源项目盘点.md §6`);
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.SM }) {
          Text('开发工具')
            .fontSize(AppFontSize.BODY_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
            .padding({ left: AppSpacing.SM })

          Grid() {
            ForEach(this.tools, (item: DevToolItem) => {
              GridItem() {
                this.toolCard(item)
              }
            }, (item: DevToolItem): string => item.id)
          }
          .columnsTemplate(this.columnsTemplate())
          .columnsGap(ToolsView.CARD_GAP)
          .rowsGap(ToolsView.CARD_GAP)
          .height(this.gridHeight())
          .width('100%')
          .scrollBar(BarState.Off)
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

  /** 单张工具卡：图标 + 标题 + 两行描述 + （待实现角标）。 */
  @Builder
  toolCard(item: DevToolItem) {
    Column({ space: AppSpacing.SM }) {
      Row() {
        Column() {
          SymbolGlyph(this.symbolOf(item.symbol))
            .fontSize(AppSize.ICON_LG)
            .fontColor([this.iconColorOf(item.status)])
        }
        .width(AppSize.ICON_CHIP)
        .height(AppSize.ICON_CHIP)
        .borderRadius(AppRadius.FULL)
        .backgroundColor(this.tintOf(item.status))
        .justifyContent(FlexAlign.Center)

        Blank()

        if (item.status === DevToolStatus.PLANNED) {
          Text('待实现')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .padding({ left: AppSpacing.XXS, right: AppSpacing.XXS, top: 1, bottom: 1 })
            .borderRadius(AppRadius.SM)
            .backgroundColor($r('app.color.app_bg_page'))
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(item.title)
        .fontSize(AppFontSize.BODY)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor(item.status === DevToolStatus.READY
          ? $r('app.color.app_text_primary') : $r('app.color.app_text_secondary'))
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(item.desc)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(ToolsView.CARD_HEIGHT)
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.onTap(item);
    })
  }

  /** 卡片高度（网格行高与之对齐，改这里的数就要同步 gridHeight）。 */
  private static readonly CARD_HEIGHT: number = 148;
  private static readonly CARD_GAP: number = AppSpacing.MD;
}
