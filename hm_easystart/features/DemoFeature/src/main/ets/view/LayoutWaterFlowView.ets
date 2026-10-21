import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';
import { SimpleDataSource } from '../data/ListDataSource';

/** 瀑布流卡片：高度按 index 造出「错落」效果（真数据里通常是图片原始比例）。 */
class FlowCard {
  readonly title: string;
  readonly ratio: number;

  constructor(title: string, ratio: number) {
    this.title = title;
    this.ratio = ratio;
  }
}

/**
 * 瀑布流布局示例（独立页，v3.80）。
 *
 * 【为什么单独成页】WaterFlow 有三个必须同时满足的前提，任何一个漏了都表现为"看不出效果"或"不滚动"：
 * 1. 自身要有**确定高度**（`height` 或 `layoutWeight`），否则和 Grid 一样塌成 0；
 * 2. `FlowItem` 的高度必须由 `aspectRatio` / `itemConstraintSize` 给定，交给内容撑会把相邻列拉垮；
 * 3. 列数用 `columnsTemplate('repeat(N, 1fr)')` 随宽度切换，切列时数据源不要重建。
 *
 * 全仓此前 `WaterFlow` 零覆盖，本页是唯一可照抄的实现。
 */
@ComponentV2
export struct LayoutWaterFlowView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 列数（2 / 3 / 4，按容器宽度切换） */
  @Local columns: number = 2;
  /** 数据条数 */
  @Local count: number = 40;
  /** 是否开启 SLIDING_WINDOW（切列不重建，滚动更顺） */
  @Local sliding: boolean = true;

  private source: SimpleDataSource = new SimpleDataSource();
  /** 卡片元数据（与数据源同步维护） */
  private cards: FlowCard[] = [];

  aboutToAppear(): void {
    this.columns = this.columnsForWidth(this.breakpoint.windowWidthVp);
    this.refill(this.count);
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 列数按**容器宽度**分档：瀑布流卡片最窄 ~140vp 才不至于标题挤成两行。 */
  private columnsForWidth(widthVp: number): number {
    if (widthVp < 480) {
      return 2;
    }
    if (widthVp < 760) {
      return 3;
    }
    return 4;
  }

  private refill(count: number): void {
    this.count = count;
    const next: FlowCard[] = [];
    // 用 3 档比例造错落：1:0.75 / 1:1 / 1:1.4
    const ratios: number[] = [0.75, 1.0, 1.4];
    for (let i = 0; i < count; i++) {
      next.push(new FlowCard(`卡片 ${i + 1}`, ratios[i % 3]));
    }
    this.cards = next;
    this.source.reset(count, '卡片');
  }

  /** 切换列数（同时演示"切列不重建数据源"）。 */
  private setColumns(n: number): void {
    this.columns = n;
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(AppFontSize.TITLE_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .fontColor($r('app.color.app_text_primary'))
      .width('100%')
      .margin({ top: AppSpacing.SM, bottom: AppSpacing.XS })
  }

  @Builder
  tip(text: string) {
    Text(text)
      .fontSize(AppFontSize.CAPTION)
      .fontColor($r('app.color.app_text_tertiary'))
      .width('100%')
  }

  @Builder
  flowItem(index: number) {
    Column({ space: AppSpacing.XXS }) {
      // 文字先渲染（固定高度），占位块用 layoutWeight 吃掉剩余——反过来写会把文字压成 0 行
      Text(this.cardTitle(index))
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .maxLines(1)
        .height(16)
        .width('100%')
      Column()
        .width('100%')
        .layoutWeight(1)
        .borderRadius(AppRadius.SM)
        .backgroundColor($r('app.color.app_bg_page_deep'))
    }
    .width('100%')
    .height('100%')
    .padding(AppSpacing.SM)
    .borderRadius(AppRadius.MD)
    .backgroundColor($r('app.color.app_bg_card'))
  }

  /** 标题取值（越界兜底，避免 LazyForEach 预取到未填充索引时出现空串）。 */
  private cardTitle(index: number): string {
    if (index < this.cards.length) {
      return this.cards[index].title;
    }
    return `卡片 ${index + 1}`;
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('WaterFlow + LazyForEach：等高用 Grid、不等高才用瀑布流。本页用三档比例造错落，列数按容器宽度 2/3/4 切换。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        this.sectionTitle('列数切换')

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({
            text: '2 列',
            variant: this.columns === 2 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.setColumns(2);
            }
          })
          CommonButton({
            text: '3 列',
            variant: this.columns === 3 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.setColumns(3);
            }
          })
          CommonButton({
            text: '4 列',
            variant: this.columns === 4 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.setColumns(4);
            }
          })
          CommonButton({
            text: this.sliding ? 'SLIDING_WINDOW：开' : 'SLIDING_WINDOW：关',
            variant: this.sliding ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.sliding = !this.sliding;
            }
          })
        }
        .width('100%')

        this.tip(`当前 ${this.columns} 列 · ${this.count} 条 · layoutMode=${this.sliding ? 'SLIDING_WINDOW' : 'ALWAYS_TOP_DOWN'}（切列不重建数据源）`)

        this.sectionTitle('瀑布流')

        // 关键：WaterFlow 自身必须有确定高度
        // layoutMode 是**构造参数**（WaterFlowOptions 字段），不是链式修饰器
        WaterFlow({
          layoutMode: this.sliding ? WaterFlowLayoutMode.SLIDING_WINDOW : WaterFlowLayoutMode.ALWAYS_TOP_DOWN
        }) {
          LazyForEach(this.source, (item: string, index: number) => {
            FlowItem() {
              this.flowItem(index)
            }
            // 关键：高度由 aspectRatio 给定，不能交给内容撑
            .aspectRatio(this.cards.length > index ? this.cards[index].ratio : 1)
          }, (item: string, index: number): string => `wf-${index}`)
        }
        .columnsTemplate(this.columnsTemplate())
        .columnsGap(AppSpacing.SM)
        .rowsGap(AppSpacing.SM)
        .cachedCount(4)
        .width('100%')
        .height(420)
        .borderRadius(AppRadius.MD)
        .backgroundColor($r('app.color.app_bg_page_deep'))
        .onAreaChange((_old: Area, area: Area): void => {
          const w: number = Number(area.width);
          if (w > 0) {
            this.columns = this.columnsForWidth(w);
          }
        })

        this.sectionTitle('照抄要点')

        Text('1. WaterFlow 必须给确定高度（height 或 layoutWeight），否则塌成 0；\n2. FlowItem 必须给 aspectRatio 或 itemConstraintSize，交给内容撑会把相邻列拉垮；\n3. 列数用 columnsTemplate(\'repeat(N, 1fr)\')，N 随容器宽度变；\n4. 切列时不要重建数据源，配 layoutMode(SLIDING_WINDOW) 更顺；\n5. 数据源必须是 IDataSource（LazyForEach 契约），别传数组。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
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

  private columnsTemplate(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.columns; i++) {
      parts.push('1fr');
    }
    return parts.join(' ');
  }
}
