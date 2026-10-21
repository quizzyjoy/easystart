import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';

/** 分组数据（ListItemGroup 的 header + 子项）。 */
class GroupData {
  readonly title: string;
  readonly items: string[];

  constructor(title: string, items: string[]) {
    this.title = title;
    this.items = items;
  }
}

/**
 * List 列表布局示例（独立页，v3.80）。
 *
 * 覆盖四件事（全仓此前 `ListItemGroup` / `sticky` / `lanes` / `swipeAction` 都是 0）：
 * 1. **分组 + 吸顶**：`ListItemGroup({ header: ... })` 配 `.sticky(StickyStyle.Header)`；
 * 2. **多列**：`.lanes(n)` 随宽度切 1/2/3（比 Grid 更适合"等宽等高的条目流"）；
 * 3. **侧滑**：`ListItem.swipeAction({ end: ... })`；
 * 4. **分组定位**：`Scroller.scrollToIndex(groupIndex)`。
 *
 * 【与「列表四态」的分工】那页只管 StateContainer 状态机（恒定单列）；本页只管布局形态。
 */
@ComponentV2
export struct LayoutListView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local lanes: number = 1;
  @Local sticky: boolean = true;
  @Local swipeTip: string = '未滑动过任何行';

  private scroller: Scroller = new Scroller();
  private groups: GroupData[] = [];

  aboutToAppear(): void {
    this.lanes = this.lanesForWidth(this.breakpoint.windowWidthVp);
    const next: GroupData[] = [];
    const names: string[] = ['A 组', 'B 组', 'C 组', 'D 组'];
    for (let g = 0; g < names.length; g++) {
      const items: string[] = [];
      for (let i = 0; i < 6; i++) {
        items.push(`${names[g]} · 条目 ${i + 1}`);
      }
      next.push(new GroupData(names[g], items));
    }
    this.groups = next;
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 多列档位：单列最小可读宽 ~220vp。 */
  private lanesForWidth(widthVp: number): number {
    if (widthVp < 480) {
      return 1;
    }
    if (widthVp < 900) {
      return 2;
    }
    return 3;
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

  /** 分组吸顶头 */
  @Builder
  groupHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(AppFontSize.BODY_SM)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_secondary'))
      Blank()
    }
    .width('100%')
    .height(40)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor($r('app.color.app_bg_page_deep'))
  }

  /** 行内容 */
  @Builder
  rowContent(text: string) {
    Row() {
      Text(text)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor($r('app.color.app_bg_card'))
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('List + ListItemGroup：分组吸顶、多列（lanes）、侧滑、分组定位。四件事都在这一页。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        this.sectionTitle('形态切换')

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({
            text: '1 列',
            variant: this.lanes === 1 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.lanes = 1;
            }
          })
          CommonButton({
            text: '2 列',
            variant: this.lanes === 2 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.lanes = 2;
            }
          })
          CommonButton({
            text: '3 列',
            variant: this.lanes === 3 ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.lanes = 3;
            }
          })
          CommonButton({
            text: this.sticky ? '吸顶：开' : '吸顶：关',
            variant: this.sticky ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
            onAction: (): void => {
              this.sticky = !this.sticky;
            }
          })
          CommonButton({
            text: '跳到 C 组',
            variant: ButtonVariant.SECONDARY,
            onAction: (): void => {
              // 分组索引 = 第 3 个分组（0 基 2）
              this.scroller.scrollToIndex(2);
            }
          })
        }
        .width('100%')

        this.tip(`当前 ${this.lanes} 列 · 吸顶${this.sticky ? '开' : '关'} · ${this.swipeTip}`)

        this.sectionTitle('分组列表（左滑任意行）')

        // 关键：List 自身要有确定高度；lanes 与 ListItemGroup 同用时分组头默认占满整行
        List({ scroller: this.scroller }) {
          ForEach(this.groups, (group: GroupData, gi: number) => {
            ListItemGroup({ header: this.groupHeader(group.title) }) {
              ForEach(group.items, (item: string) => {
                ListItem() {
                  this.rowContent(item)
                }
                .swipeAction({
                  end: {
                    builder: (): void => {
                      this.swipeButton(item);
                    }
                  }
                })
              }, (item: string): string => item)
            }
          }, (group: GroupData): string => group.title)
        }
        .lanes(this.lanes, AppSpacing.SM)
        .sticky(this.sticky ? StickyStyle.Header : StickyStyle.None)
        .width('100%')
        .height(420)
        .borderRadius(AppRadius.MD)
        .backgroundColor($r('app.color.app_bg_page_deep'))
        .scrollBar(BarState.Off)
        .onAreaChange((_old: Area, area: Area): void => {
          const w: number = Number(area.width);
          if (w > 0) {
            this.lanes = this.lanesForWidth(w);
          }
        })

        this.sectionTitle('照抄要点')

        Text('1. List 必须有确定高度，否则和 Grid 一样塌成 0；\n2. 吸顶只对 ListItemGroup 的 header 生效，普通 ListItem 没有吸顶；\n3. lanes 与 ListItemGroup 同用时，分组头默认占满整行（特殊项不受 lanes 约束，需要单独处理）；\n4. 侧滑用 swipeAction，删除类操作务必二次确认；\n5. 分组定位用 Scroller.scrollToIndex(分组索引)，不是条目的全局索引。')
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

  /** 侧滑动作（模板里用文案回写代替真删除，避免演示页撕数据）。 */
  @Builder
  swipeButton(item: string) {
    Row() {
      Text('已左滑')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_on_brand'))
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    }
    .height(56)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.qj_brand'))
    .onClick((): void => {
      this.swipeTip = `已触发侧滑：${item}`;
    })
  }
}
