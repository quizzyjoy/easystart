import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';

/**
 * 自适应布局示例（独立页，v3.80）。
 *
 * 官方「自适应布局」七能力逐个可开关：拉伸 / 均分 / 占比 / 缩放 / 延伸 / 隐藏 / 折行。
 * 与「响应式布局」的区别：自适应是**随容器连续变化**（拖窗口宽就能看到），
 * 响应式是**在断点处跳变**（列数从 2 跳 4）。
 *
 * 注意：`ContainerReader`（按容器而非窗口算断点）是 **API 26 起**，
 * 本仓 `compatibleSdkVersion` 是 6.1.0(23)，所以本页用 `onAreaChange` 读容器宽做替代，
 * 并在页内标注这个差异——不要照抄成 ContainerReader 而不加版本守卫。
 */
@ComponentV2
export struct LayoutAdaptiveView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 容器实际宽度（由 onAreaChange 回填，用于展示"连续变化"） */
  @Local containerW: number = 0;

  // 六个开关（对应官方七能力，其中"占比"与"缩放"合为一个演示块）
  @Local stretchOn: boolean = true;
  @Local evenOn: boolean = false;
  @Local weightsOn: boolean = false;
  @Local aspectOn: boolean = false;
  @Local scrollOn: boolean = false;
  @Local priorityOn: boolean = false;
  @Local wrapOn: boolean = true;

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
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
  chip(text: string, on_: boolean, action: () => void) {
    Text(text)
      .fontSize(AppFontSize.CAPTION)
      .fontColor(on_ ? $r('app.color.app_text_on_brand') : $r('app.color.app_text_secondary'))
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
      .borderRadius(AppRadius.FULL)
      .backgroundColor(on_ ? $r('app.color.qj_brand') : $r('app.color.app_bg_card'))
      .onClick((): void => {
        action();
      })
  }

  @Builder
  box(label: string, weight: number) {
    Column() {
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_primary'))
    }
    .height(48)
    .justifyContent(FlexAlign.Center)
    .borderRadius(AppRadius.SM)
    .backgroundColor($r('app.color.app_bg_card'))
    .layoutWeight(weight)
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('七种自适应能力逐个开关。它们是「随容器连续变化」——拖窗口宽度就能看到，不像响应式那样在断点跳变。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        // 容器宽实时读数：这就是"连续变化"的度量
        Text(`当前容器宽 ≈ ${this.containerW > 0 ? Math.round(this.containerW) : '—'} vp（断点 ${this.bp()}）`)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .padding(AppSpacing.SM)
          .borderRadius(AppRadius.SM)
          .backgroundColor($r('app.color.app_bg_card'))
          .onAreaChange((_old: Area, area: Area): void => {
            this.containerW = Number(area.width);
          })

        // ① 拉伸：Blank 把两端推开
        this.sectionTitle('① 拉伸（Blank）')
        Row() {
          Text('左侧')
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
          if (this.stretchOn) {
            Blank()
          }
          Text('右侧')
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
        }
        .width('100%')
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.MD)
        .backgroundColor($r('app.color.app_bg_card'))
        this.tip('Blank() 吃掉剩余空间，把左右两端推开；容器越宽，推开越明显。')
        Row({ space: AppSpacing.SM }) {
          this.chip(this.stretchOn ? 'Blank：开' : 'Blank：关', this.stretchOn, (): void => {
            this.stretchOn = !this.stretchOn;
          })
        }

        // ② 均分：justifyContent
        this.sectionTitle('② 均分（justifyContent）')
        Row() {
          this.box('A', 1)
          if (this.evenOn) {
            Blank().width(AppSpacing.MD)
          }
          this.box('B', 1)
        }
        .width('100%')
        .justifyContent(this.evenOn ? FlexAlign.SpaceEvenly : FlexAlign.Start)
        Row({ space: AppSpacing.SM }) {
          this.chip(this.evenOn ? 'SpaceEvenly：开' : 'SpaceEvenly：关', this.evenOn, (): void => {
            this.evenOn = !this.evenOn;
          })
        }

        // ③ 占比：layoutWeight
        this.sectionTitle('③ 占比（layoutWeight）')
        Row() {
          this.box('1', this.weightsOn ? 1 : 1)
          this.box('2', this.weightsOn ? 2 : 1)
          this.box('1', this.weightsOn ? 1 : 1)
        }
        .width('100%')
        Row({ space: AppSpacing.SM }) {
          this.chip(this.weightsOn ? '权重 1:2:1：开' : '等分：关', this.weightsOn, (): void => {
            this.weightsOn = !this.weightsOn;
          })
        }
        this.tip('权重模式下中间块占两份；容器的剩余宽度按权重分配，与绝对宽度无关。')

        // ④ 缩放：aspectRatio
        this.sectionTitle('④ 缩放（aspectRatio）')
        Row() {
          Column() {
            Text('16:9')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_primary'))
          }
          .width('100%')
          .aspectRatio(this.aspectOn ? 16 / 9 : 3)
          .justifyContent(FlexAlign.Center)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))
        }
        .width('100%')
        Row({ space: AppSpacing.SM }) {
          this.chip(this.aspectOn ? '16:9' : '3:1', this.aspectOn, (): void => {
            this.aspectOn = !this.aspectOn;
          })
        }
        this.tip('aspectRatio 让高度跟着宽度走——宽度变、高度自动变，这是"连续变化"的另一种形态。')

        // ⑤ 延伸：外层 Scroll
        this.sectionTitle('⑤ 延伸（外层 Scroll）')
        Column({ space: AppSpacing.XS }) {
          ForEach(this.repeatRows(), (i: number) => {
            Text(`条目 ${i + 1}`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
              .padding(AppSpacing.SM)
              .borderRadius(AppRadius.SM)
              .backgroundColor($r('app.color.app_bg_card'))
          }, (i: number): string => `row-${i}`)
        }
        .width('100%')
        .height(this.scrollOn ? 120 : 232)
        .clip(this.scrollOn)
        Row({ space: AppSpacing.SM }) {
          this.chip(this.scrollOn ? '限高 120 + 裁剪：开' : '不限高（全展开）', this.scrollOn, (): void => {
            this.scrollOn = !this.scrollOn;
          })
        }
        this.tip('内容超出容器又不想撑高页面时，限高 120 + clip；关掉裁剪则按内容全展开（232）。')

        // ⑥ 隐藏：displayPriority
        this.sectionTitle('⑥ 隐藏（displayPriority）')
        Row({ space: AppSpacing.SM }) {
          Text('主信息')
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
            .displayPriority(this.priorityOn ? 1 : 3)
          Text('次要')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .displayPriority(this.priorityOn ? 2 : 2)
          Text('最次要')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .displayPriority(this.priorityOn ? 3 : 1)
        }
        .width('100%')
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.MD)
        .backgroundColor($r('app.color.app_bg_card'))
        Row({ space: AppSpacing.SM }) {
          this.chip(this.priorityOn ? '按优先级砍级：开' : '关', this.priorityOn, (): void => {
            this.priorityOn = !this.priorityOn;
          })
        }
        this.tip('displayPriority 只在 Row/Column/Flex 父容器内生效：空间不够时数字大的先消失（需窄容器才看得出来）。')

        // ⑦ 折行：FlexWrap.Wrap
        this.sectionTitle('⑦ 折行（FlexWrap）')
        Flex({ wrap: this.wrapOn ? FlexWrap.Wrap : FlexWrap.NoWrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          ForEach(this.repeatChips(), (i: number) => {
            Text(`标签 ${i + 1}`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 4, bottom: 4 })
              .borderRadius(AppRadius.FULL)
              .backgroundColor($r('app.color.app_bg_card'))
          }, (i: number): string => `c-${i}`)
        }
        .width('100%')
        Row({ space: AppSpacing.SM }) {
          this.chip(this.wrapOn ? 'Wrap：开' : 'NoWrap：关', this.wrapOn, (): void => {
            this.wrapOn = !this.wrapOn;
          })
        }

        this.sectionTitle('与响应式的边界')

        Text('自适应 = 随容器连续变化（本页七项）；响应式 = 断点跳变（列数 2→4、页签底改侧）。\n官方「一多」共四类响应式手法：重复（列表/瀑布流/轮播/网格）、分栏（侧边栏/单双栏/三分栏）、挪移（图文换位/底改侧导航）、缩进（限宽居中）。\n注意：ContainerReader（按容器算断点）是 API 26 起，本仓基线 23，所以这里用 onAreaChange 替代。')
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

  private repeatRows(): number[] {
    return [0, 1, 2, 3, 4];
  }

  private repeatChips(): number[] {
    return [0, 1, 2, 3, 4, 5, 6, 7];
  }
}
