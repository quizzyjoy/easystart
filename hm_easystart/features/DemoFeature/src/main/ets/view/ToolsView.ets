import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';

/**
 * 开发工具 Tab（v3.37）。
 *
 * 当前只放「设备能力检测」一张卡片，点击进入现有 DeviceCapabilityView（保留原能力面板
 * 的全部内容，不重复实现）。后续新增工具时按同样卡片模式追加。
 */
@ComponentV2
export struct ToolsView {
  @Param onOpenDeviceCapability: () => void = (): void => {
  };
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.SM }) {
          Text('设备与环境')
            .fontSize(AppFontSize.BODY_SM)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
            .padding({ left: AppSpacing.SM })

          Row({ space: AppSpacing.MD }) {
            Column() {
              SymbolGlyph($r('sys.symbol.display'))
                .fontSize(AppSize.ICON_LG)
                .fontColor([$r('app.color.app_text_on_brand')])
            }
            .width(AppSize.ICON_CHIP)
            .height(AppSize.ICON_CHIP)
            .borderRadius(AppRadius.FULL)
            .backgroundColor($r('app.color.qj_brand'))
            .justifyContent(FlexAlign.Center)

            Column({ space: AppSpacing.XXS }) {
              Text('设备能力检测')
                .fontSize(AppFontSize.BODY)
                .fontWeight(AppFontWeight.MEDIUM)
                .fontColor($r('app.color.app_text_primary'))
                .width('100%')
              Text('断点 / 设备形态 / 窗口适配 / 网络 / 国际化')
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_tertiary'))
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(AppFontSize.TITLE_SM)
              .fontColor([$r('app.color.app_text_tertiary')])
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.LG)
          .backgroundColor($r('app.color.app_bg_card'))
          .onClick((): void => {
            this.onOpenDeviceCapability();
          })
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
}
