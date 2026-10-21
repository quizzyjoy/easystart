import { SectionNavRow, sectionNavDesc, sectionNavRows, sectionNavTitle } from '../model/SectionNav';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';

/**
 * 示例 Tab 的二级导航页（v3.66）。
 *
 * 首页（L1）只留六个入口卡，子入口全部收进本页：一页一事，列出该入口下的所有子项，
 * 点击把 id 上抛给宿主（不 import RouterManager，导航纪律与其它视图一致）。
 *
 * 三个入口共用本页：`gallery`（组件示例 3 行）/ `vitalui`（VitalUI 组件 4 行）/
 * `scene`（场景示例 6 行）。行数据与首页卡来自同一份元数据（`model/SectionNav`）。
 */
@ComponentV2
export struct SectionNavView {
  /** 入口 id：gallery / vitalui / scene。 */
  @Param sectionId: string = 'gallery';
  /** 组件类子项（gallery / vitalui 的行）：上抛 groupId。 */
  @Event onOpenGroup: (groupId: string) => void = (_groupId: string): void => {
  };
  /** 场景类子项：上抛 sceneId。 */
  @Event onOpenScene: (sceneId: string) => void = (_sceneId: string): void => {
  };

  @Local rows: SectionNavRow[] = [];
  /** 断点与窗口避让：padding / 最大内容宽 / 底部避让全部走设计令牌（v3.68）。 */
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 行容器实际宽度（vp）：由 Flex 的 onAreaChange 回填。 */
  @Local containerW: number = 0;
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /**
   * 子项宽度：按**容器实际宽度**判定（v3.71）。
   * 导航行单列最小可读宽 360vp——分栏左栏 340–420vp 时不会硬塞两列。
   */
  private rowWidth(): string {
    return DesignToken.twoUpWidth(this.containerW > 0 ? this.containerW : this.breakpoint.windowWidthVp, 360);
  }

  aboutToAppear(): void {
    this.rows = sectionNavRows(this.sectionId);
  }

  /** 行点击：场景入口走 onOpenScene，其余走 onOpenGroup。 */
  private handleRow(row: SectionNavRow): void {
    if (this.sectionId === 'scene') {
      this.onOpenScene(row.id);
      return;
    }
    this.onOpenGroup(row.id);
  }

  @Builder
  navRow(row: SectionNavRow) {
    Column() {
      Row({ space: AppSpacing.SM }) {
        Column({ space: AppSpacing.XXS }) {
          Text(row.title)
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text(row.desc)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(AppFontSize.BODY_SM)
          .fontColor([$r('app.color.app_text_tertiary')])
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(DesignToken.cardPadding())
    }
    .width(this.rowWidth())
    .margin({ bottom: DesignToken.cardGap() })
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.handleRow(row);
    })
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text(sectionNavDesc(this.sectionId))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
          ForEach(this.rows, (row: SectionNavRow, index: number) => {
            this.navRow(row)
          }, (row: SectionNavRow): string => `${this.sectionId}_${row.id}`)
        }
        .width('100%')
        .onAreaChange((_old: Area, area: Area): void => {
          this.containerW = Number(area.width);
        })

        Text(`共 ${this.rows.length} 个子页 · ${sectionNavTitle(this.sectionId)}`)
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
        top: AppSpacing.MD,
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
}
