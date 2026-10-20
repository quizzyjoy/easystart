import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { TransitionCard, transitionCardOrDefault } from './TransitionsView';

/**
 * 共享元素转场详情页（v3.42）：列表侧的 `.sharedTransition('tcard-<id>')` 在这里复用同一 key，
 * 系统把那张 44vp 的小方块「放大」到本页 96vp 的大图位置，中间内容不做二次布局。
 */
@ComponentV2
export struct TransitionDetailView {
  @Param cardId: string = '';
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private card(): TransitionCard {
    return transitionCardOrDefault(this.cardId);
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column() {
          Text(this.card().id.toUpperCase())
            .fontSize(AppFontSize.TITLE_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_on_brand'))
        }
        .width(96)
        .height(96)
        .borderRadius(AppRadius.LG)
        .backgroundColor($r('app.color.qj_brand'))
        .justifyContent(FlexAlign.Center)
        // 与列表卡同 key：系统负责中间的位移与缩放
        .sharedTransition(`tcard-${this.card().id}`, { duration: 350, curve: Curve.Friction })

        Column({ space: AppSpacing.SM }) {
          Text(this.card().title)
            .fontSize(AppFontSize.TITLE_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text(this.card().desc)
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
          Text('共享元素转场的意义：列表里的「身份」直接变成详情里的「主体」，' +
            '用户不需要重新建立「点的是这一项」的认知；key 必须两侧一致，尺寸差异由系统插值。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
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
        top: AppSpacing.XL,
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
