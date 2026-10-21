import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';
import { SimpleDataSource } from '../data/ListDataSource';

const PERF_ROW_HEIGHT: number = 44;
const PERF_VIEWPORT: number = 240;

/**
 * 长列表性能示例页（独立页，v3.79）。
 *
 * 结论来自可复现的计数（每行 onAppear 累加），不依赖设备性能：
 * - ForEach 放在 Scroll + Column（非虚拟化）→ 2000 条会建满 2000 行；
 * - LazyForEach 放在 List（虚拟化）→ 同样 2000 条只建可视区那几行。
 *
 * 注意：**List 里的 ForEach 也会被虚拟化**（实测只建 12 行），
 * 所以对照必须把 ForEach 放进非虚拟化容器，否则演示不出差异。
 */
@ComponentV2
export struct ListPerfSampleView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 0 = 未开始，1 = ForEach，2 = LazyForEach */
  @Local mode: number = 0;
  @Local count: number = 2000;
  @Local foreachCreated: number = 0;
  @Local lazyCreated: number = 0;

  private source: SimpleDataSource = new SimpleDataSource();
  private plainItems: string[] = [];

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private start(mode: number, count: number): void {
    this.mode = mode;
    this.count = count;
    this.foreachCreated = 0;
    this.lazyCreated = 0;
    const arr: string[] = [];
    for (let i = 0; i < count; i++) {
      arr.push(`第 ${i + 1} 条数据`);
    }
    this.plainItems = arr;
    this.source.reset(count, '第');
  }

  private summary(): string {
    if (this.mode === 0) {
      return '尚未开始：先选一种写法';
    }
    const created: number = this.mode === 1 ? this.foreachCreated : this.lazyCreated;
    const name: string = this.mode === 1 ? 'ForEach' : 'LazyForEach';
    return `${name}：已创建 ${created} / ${this.count} 行`;
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
  row(text: string, tag: string) {
    Row() {
      Text(text)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
      Blank()
      Text(tag)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_quaternary'))
    }
    .width('100%')
    .height(PERF_ROW_HEIGHT)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .onAppear((): void => {
      // 两个模式各自计数：谁被创建过，谁的计数就涨
      if (tag === 'ForEach') {
        this.foreachCreated = this.foreachCreated + 1;
      } else {
        this.lazyCreated = this.lazyCreated + 1;
      }
    })
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('同一份数据分别用两种写法渲染，计数来自每行 onAppear —— 可复现的硬指标，不看设备性能。ForEach 放 Scroll+Column（全量创建），LazyForEach 放 List（按需创建）。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        this.sectionTitle('实测结果')

        Text(this.summary())
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor(this.mode === 2 ? $r('app.color.qj_brand') : $r('app.color.app_text_primary'))
          .width('100%')
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))

        this.sectionTitle('开始测量')

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({
            text: '200 条 · ForEach',
            variant: this.mode === 1 && this.count === 200 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.start(1, 200);
            }
          })
          CommonButton({
            text: '2000 条 · ForEach',
            variant: this.mode === 1 && this.count === 2000 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.start(1, 2000);
            }
          })
          CommonButton({
            text: '2000 条 · Lazy',
            variant: this.mode === 2 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.start(2, 2000);
            }
          })
        }
        .width('100%')

        if (this.mode === 1) {
          Scroll() {
            Column() {
              ForEach(this.plainItems, (text: string) => {
                this.row(text, 'ForEach')
              }, (text: string, index: number): string => `f-${index}`)
            }
            .width('100%')
          }
          .width('100%')
          .height(PERF_VIEWPORT)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))
          .scrollBar(BarState.Off)
        } else if (this.mode === 2) {
          List() {
            LazyForEach(this.source, (text: string) => {
              ListItem() {
                this.row(text, 'LazyForEach')
              }
            }, (text: string, index: number): string => `l-${index}`)
          }
          .cachedCount(4)
          .width('100%')
          .height(PERF_VIEWPORT)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))
          .scrollBar(BarState.Off)
        } else {
          Text('选一种写法开始测量：2000 条时差异最明显。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
            .width('100%')
            .padding(AppSpacing.MD)
            .borderRadius(AppRadius.MD)
            .backgroundColor($r('app.color.app_bg_card'))
        }

        this.sectionTitle('照抄要点')

        Text('1. 数据量大且可能增长 → List/Grid + LazyForEach，只创建可视区。\n2. LazyForEach 的数据源必须真实现 IDataSource，且 registerDataChangeListener 要真的把 listener 存进数组，否则 notifyDataReload 不刷新。\n3. 注意：List 里的 ForEach 其实也会被虚拟化（实测同样只建十几行）；真正危险的是把大量数据放进 Scroll+Column+ForEach，会一次性建满。\n4. ListItem 建议配 cachedCount，滚动更顺。')
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
}
