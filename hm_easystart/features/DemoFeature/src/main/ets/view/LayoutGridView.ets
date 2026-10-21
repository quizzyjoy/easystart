import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';

const GRID_CARD_HEIGHT: number = 88;
const GRID_GAP: number = 8;

/**
 * 网格布局示例（独立页，v3.80）。
 *
 * 覆盖三件 Grid 的关键差异（全仓此前 `GridLayoutOptions` / `onGetRectByIndex` 都是 0）：
 * 1. **只设列 = 可滚动**；**同时设行列 = 定死不可滚**（这是最常被误解的一点）；
 * 2. **跨行跨列**：必须同时给 `rowsTemplate`，否则 `onGetRectByIndex` 不生效；
 * 3. **按位放置**：`onGetRectByIndex` 返回 `[rowStart, columnStart, rowSpan, columnSpan]`。
 *
 * 【与「开发工具」页的分工】那页的 Grid 只解决"卡片不塌"；本页讲形态与跨格。
 */
@ComponentV2
export struct LayoutGridView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 列数（2 / 3 / 4） */
  @Local cols: number = 2;
  /** true = 同时设行列（定死不可滚）；false = 只设列（可滚） */
  @Local fixedRows: boolean = true;
  /** true = 开启跨行跨列（需要 rowsTemplate） */
  @Local spanMode: boolean = false;
  /** 固定模式的可见行数 */
  @Local visibleRows: number = 3;

  /** Grid 的 layoutOptions 只能走构造参数（第二个位置参数），没有链式修饰器。 */
  private gridScroller: Scroller = new Scroller();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private colsForWidth(widthVp: number): number {
    if (widthVp < 480) {
      return 2;
    }
    if (widthVp < 900) {
      return 3;
    }
    return 4;
  }

  /** 单元格总数：固定模式按 行×列 算，滚动模式给足 24 格。 */
  private cellCount(): number {
    return this.fixedRows ? this.cols * this.visibleRows : 24;
  }

  /** 列模板 */
  private colTemplate(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.cols; i++) {
      parts.push('1fr');
    }
    return parts.join(' ');
  }

  /** 行模板（仅支跨格时必须给） */
  private rowTemplate(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.visibleRows; i++) {
      parts.push(`${GRID_CARD_HEIGHT}vp`);
    }
    return parts.join(' ');
  }

  /**
   * 跨格规则：第 1 格跨 2 列 1 行；第 4 格（若存在）跨 1 列 2 行。
   * 索引从 0 开始；返回 [rowStart, columnStart, rowSpan, columnSpan]。
   */
  private layoutOptions(): GridLayoutOptions {
    const target: GridLayoutOptions = {
      regularSize: [1, 1],
      // SDK 要求返回元组 [rowStart, columnStart, rowSpan, columnSpan]
      onGetRectByIndex: (index: number): [number, number, number, number] => {
        if (this.spanMode && index === 0) {
          return [0, 0, 1, 2];
        }
        return [0, 0, 1, 1];
      }
    };
    return target;
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
  cell(index: number) {
    Column({ space: AppSpacing.XXS }) {
      Text(`#${index + 1}`)
        .fontSize(AppFontSize.BODY_SM)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
      Text(index === 0 && this.spanMode ? '跨 2 列' : '单格')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .borderRadius(AppRadius.MD)
    .backgroundColor($r('app.color.app_bg_card'))
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('Grid 的三种形态：只设列（可滚）/ 同时设行列（定死）/ 跨行跨列。最后一种必须同时给 rowsTemplate，否则 onGetRectByIndex 不生效。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        this.sectionTitle('形态切换')

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({
            text: '2 列',
            variant: this.cols === 2 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.cols = 2;
            }
          })
          CommonButton({
            text: '3 列',
            variant: this.cols === 3 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.cols = 3;
            }
          })
          CommonButton({
            text: '4 列',
            variant: this.cols === 4 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.cols = 4;
            }
          })
          CommonButton({
            text: this.fixedRows ? '定死（行列都设）' : '可滚（只设列）',
            variant: this.fixedRows ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.fixedRows = !this.fixedRows;
              // 跨格依赖 rowsTemplate，所以关掉定死时同步关跨格
              if (!this.fixedRows) {
                this.spanMode = false;
              }
            }
          })
          CommonButton({
            text: this.spanMode ? '跨格：开' : '跨格：关',
            variant: this.spanMode ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            disabled: !this.fixedRows,
            onAction: (): void => {
              this.spanMode = !this.spanMode;
            }
          })
        }
        .width('100%')

        Text(`当前 ${this.cols} 列 · ${this.fixedRows ? '行列都设（不可滚）' : '只设列（可滚）'} · 跨格${this.spanMode ? '开' : '关'} · 共 ${this.cellCount()} 格`)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')

        this.sectionTitle('网格')

        // Grid 放在 Scroll 里必须给显式高度；定死模式按 行×行高+间距 算，滚动模式给固定视口
        Scroll() {
          Grid(this.gridScroller, this.spanMode ? this.layoutOptions() : undefined) {
            ForEach(this.buildIndexes(), (index: number) => {
              GridItem() {
                this.cell(index)
              }
            }, (index: number): string => `g-${index}`)
          }
          .columnsTemplate(this.colTemplate())
          .rowsTemplate(this.fixedRows ? this.rowTemplate() : '')
          .columnsGap(GRID_GAP)
          .rowsGap(GRID_GAP)
          .width('100%')
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height(this.fixedRows ? this.fixedHeight() : 320)
        .scrollBar(BarState.Off)
        .borderRadius(AppRadius.MD)
        .backgroundColor($r('app.color.app_bg_page_deep'))
        .onAreaChange((_old: Area, area: Area): void => {
          const w: number = Number(area.width);
          if (w > 0) {
            this.cols = this.colsForWidth(w);
          }
        })

        this.sectionTitle('照抄要点')

        Text('1. 只设 columnsTemplate → 可滚；同时设 rowsTemplate → 定死不可滚（最常见的误解）；\n2. 跨行跨列必须同时给 rowsTemplate，否则 onGetRectByIndex 不生效；\n3. onGetRectByIndex 返回 [rowStart, columnStart, rowSpan, columnSpan]；\n4. Grid 放在 Scroll 里必须给显式高度，否则塌成 0（开发工具页已有同样范式）；\n5. 等宽等高的条目流优先用 List + lanes，跨格/定位才用 Grid。')
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

  /** 索引数组（ForEach 需要显式数组，不能在 build 里临时拼）。 */
  private buildIndexes(): number[] {
    const list: number[] = [];
    for (let i = 0; i < this.cellCount(); i++) {
      list.push(i);
    }
    return list;
  }

  /** 定死模式的高度：行数 × 行高 + 间距。 */
  private fixedHeight(): number {
    return this.visibleRows * GRID_CARD_HEIGHT + (this.visibleRows - 1) * GRID_GAP;
  }
}
