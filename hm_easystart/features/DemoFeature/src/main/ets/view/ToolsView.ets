import { UiThemeManager } from '@quizzyjoy/vitalui';
import { CommonToast } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, FeatureGate, GateResult, GateStatus, WindowAdapter } from '@quizzyjoy/platform';
import {
  DevToolGroup,
  DevToolItem,
  DevToolStatus,
  DevToolSymbol,
  devToolGroupTitle,
  devToolsOf
} from '../model/DevToolItem';

/**
 * 开发工具 Tab（v3.46：按组渲染两个网格）。
 *
 * 结构：组标题 + `Grid` 卡片网格；列数按**实际容器宽度**分档（sm 2 / md 3 / lg·xl 4），
 * 分栏宿主传 `paneWidthVp` 避免宽屏算出 4 列把卡片挤窄。
 *
 * 【为什么 Grid 要显式高度】Grid 放在 Scroll 里高度无上界，会塌成 0；这里按每组
 * 「行数 × 行高 + 行间距」算出固定高度，卡片内容用 maxLines 收口，不做内部滚动。
 *
 * 【分发约定】点击只上抛 id（`onOpenTool`），路由名映射唯一留在入口装配层。
 */
@ComponentV2
export struct ToolsView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  /**
   * 宿主分栏时左栏的可用宽度（vp）。0 = 不分栏，按窗口断点取列数。
   *
   * 为什么需要它：Pura X Max 等阔折叠展开后窗口 bp=lg，但入口用 Split 分栏，
   * 本页实际容器只有 ~420vp；若仍按 lg 取 4 列，卡片会被压到 ~100vp、标题截成「设…」。
   */
  @Param paneWidthVp: number = 0;

  /** 点击某张工具卡：参数是 `DevToolItem.id`。 */
  @Param onOpenTool: (id: string) => void = (_id: string): void => {
  };

  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local envTools: DevToolItem[] = devToolsOf(DevToolGroup.ENV);
  @Local dataTools: DevToolItem[] = devToolsOf(DevToolGroup.DATA);

  /**
   * 是否隐藏「当前系统跑不了」的条目。
   *
   * 两种策略都保留，因为模板要教的是取舍：
   * - false（默认）：**置灰 + 角标**，用户知道能力存在、只差条件；
   * - true：**整条隐藏**，适合面向存量设备的正式产品。
   */
  @Local hideUnavailable: boolean = false;

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 列数：按**实际容器宽度**分档（分栏时用 paneWidthVp，未分栏用窗口宽度）。 */
  private columns(): number {
    const w: number = this.paneWidthVp > 0 ? this.paneWidthVp : this.breakpoint.windowWidthVp;
    if (w > 0) {
      if (w < 480) {
        return 2;
      }
      if (w < 760) {
        return 3;
      }
      return 4;
    }
    // 宽度未知时退回断点判定
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
  private gridHeight(count: number): number {
    const rows: number = Math.ceil(count / this.columns());
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
    if (symbol === DevToolSymbol.HASH) {
      return $r('sys.symbol.hash');
    }
    if (symbol === DevToolSymbol.CODEC) {
      return $r('sys.symbol.arrow_left_arrow_right');
    }
    if (symbol === DevToolSymbol.KEY) {
      return $r('sys.symbol.key_fill');
    }
    if (symbol === DevToolSymbol.WRENCH) {
      return $r('sys.symbol.wrench_and_screwdriver_fill');
    }
    if (symbol === DevToolSymbol.DOC) {
      return $r('sys.symbol.doc_plaintext');
    }
    if (symbol === DevToolSymbol.STAR) {
      return $r('sys.symbol.star_fill');
    }
    return $r('sys.symbol.display');
  }

  private tintOf(status: DevToolStatus): ResourceColor {
    return status === DevToolStatus.READY ? this.theme.brandColor() : $r('app.color.app_bg_page');
  }

  private iconColorOf(status: DevToolStatus): ResourceColor {
    return status === DevToolStatus.READY ? $r('app.color.app_text_on_brand') : $r('app.color.app_text_tertiary');
  }

  /** 门控判定：版本 + syscap 统一走 FeatureGate，视图只负责呈现。 */
  private gateOf(item: DevToolItem): GateResult {
    return FeatureGate.checkInline(item.minApi, item.syscaps);
  }

  /** 按当前策略过滤：隐藏模式剔除不达标项，置灰模式原样返回。 */
  private visibleOf(items: DevToolItem[]): DevToolItem[] {
    if (!this.hideUnavailable) {
      return items;
    }
    return items.filter((item: DevToolItem): boolean => this.gateOf(item).isAvailable());
  }

  /** 本组被隐藏的条目数（用于组标题右侧提示）。 */
  private hiddenCountOf(items: DevToolItem[]): number {
    let n: number = 0;
    for (let i = 0; i < items.length; i++) {
      if (!this.gateOf(items[i]).isAvailable()) {
        n++;
      }
    }
    return n;
  }

  private onTap(item: DevToolItem): void {
    if (item.status === DevToolStatus.PLANNED) {
      // 待实现：明确告知去哪看参考实现，避免「点了没反应」。
      // 用 CommonToast（EntryAbility 已 attach）而非 AppSnackBar：后者在本页取不到宿主色票，
      // 真机实测不显示且报 GetColorById id=-1。
      CommonToast.info(`${item.title} 待实现：参考实现见 docs/权威参考与开源项目盘点.md §6`);
      return;
    }
    const gate: GateResult = this.gateOf(item);
    if (!gate.isAvailable()) {
      // 不达标时明确说「差什么」，而不是让用户点了没反应。
      CommonToast.info(`${item.title} 不可用：${gate.reason}`);
      return;
    }
    this.onOpenTool(item.id);
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        this.gateBar()
        this.groupBlock(devToolGroupTitle(DevToolGroup.ENV), this.envTools)
        this.groupBlock(devToolGroupTitle(DevToolGroup.DATA), this.dataTools)
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

  /** 一个分组：标题 + 该组网格。 */
  @Builder
  groupBlock(title: string, items: DevToolItem[]) {
    Column({ space: AppSpacing.SM }) {
      Row() {
        Text(title)
          .fontSize(AppFontSize.BODY_SM)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_secondary'))
        Blank()
        if (this.hideUnavailable && this.hiddenCountOf(items) > 0) {
          Text(`已隐藏 ${this.hiddenCountOf(items)} 项`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
        }
      }
      .width('100%')
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM })

      if (this.visibleOf(items).length === 0) {
        Text('本组条目在当前系统均不达标，可关闭「隐藏不可用」查看原因')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .padding({ left: AppSpacing.SM, top: AppSpacing.SM, bottom: AppSpacing.SM })
      } else {
        Grid() {
          ForEach(this.visibleOf(items), (item: DevToolItem) => {
            GridItem() {
              this.toolCard(item)
            }
          }, (item: DevToolItem): string => item.id)
        }
        .columnsTemplate(this.columnsTemplate())
        .columnsGap(ToolsView.CARD_GAP)
        .rowsGap(ToolsView.CARD_GAP)
        .height(this.gridHeight(this.visibleOf(items).length))
        .width('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 门控控制条：显示当前 API 版本 + 切换「隐藏不可用」。
   *
   * 把它放在工具页顶部，是为了让 fork 者一眼看到「入口可见性是有策略的」，
   * 而不是自己去猜某个卡片为什么点不动。
   */
  @Builder
  gateBar() {
    Row({ space: AppSpacing.SM }) {
      Text(`当前 API ${FeatureGate.currentApi()}`)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
      Blank()
      Text(this.hideUnavailable ? '隐藏不可用：开' : '隐藏不可用：关')
        .fontSize(AppFontSize.CAPTION)
        .fontColor(this.hideUnavailable ? this.theme.brandColor() : $r('app.color.app_text_secondary'))
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
        .borderRadius(AppRadius.FULL)
        .backgroundColor($r('app.color.app_bg_card'))
        .onClick((): void => {
          this.hideUnavailable = !this.hideUnavailable;
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
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
        } else if (!this.gateOf(item).isAvailable()) {
          // 门控角标：显示「差什么」，比单纯灰掉更有指导性
          Text(this.gateOf(item).reason)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
        .fontColor(item.status === DevToolStatus.READY && this.gateOf(item).isAvailable()
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
    .opacity(this.gateOf(item).isAvailable() ? 1 : 0.55)
    .onClick((): void => {
      this.onTap(item);
    })
  }

  /** 卡片高度（网格行高与之对齐，改这里的数就要同步 gridHeight）。 */
  private static readonly CARD_HEIGHT: number = 148;
  private static readonly CARD_GAP: number = AppSpacing.MD;
}
