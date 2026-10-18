import { AppFontSize, AppFontWeight, AppLineHeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, ShareHelper, WindowAdapter } from '@quizzyjoy/platform';
import { ButtonVariant, CommonButton, CommonTag, TagTone, UiThemeManager } from '@quizzyjoy/vitalui';
import { HomeItem, HomeTarget } from '../data/HomeRepository';

/**
 * 详情页范式（v3.26，样例子页 / HomeFeature）。
 *
 * 【fork 可整体复制的页面范式】「列表 → 详情」的标准骨架：
 *   品牌徽标 + 标题副标题 → 元信息标签行 → 正文段落 → 底部操作条（分享 / 收藏）。
 *
 * 布局：Scroll + 断点限宽居中（DesignToken.contentMaxWidth / pagePadding）——
 * 窄屏整页 push、宽屏由 HdsNavigation 的 Split 模式落到右栏，**模板不做特殊分支**。
 *
 * 依赖面刻意收窄到 VitalUI/Foundation/Platform：本 feature 是 fork 后整体替换的
 * 示范域，不引应用级组件包（AppComponent）；若需要 SnackBar/Dialog 等应用级反馈，
 * 在 fork 后的工程里自行接入（或改由入口装配注入）。
 *
 * 导航纪律：本视图不感知路由（不 import RouterManager）；分享机制由 Platform 的
 * ShareHelper 承担，页面只决定「分享什么」。
 */
@ComponentV2
export struct HomeDetailView {
  /** 详情数据（入口 pageMap 传入 HomeItem 实例；缺省值保证空参不崩）。 */
  @Param item: HomeItem = new HomeItem('', '详情', '', HomeTarget.DETAIL);
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  /** 操作反馈行（自持状态，不依赖应用级反馈组件）。 */
  @Local shareState: string = '';
  private share: ShareHelper = ShareHelper.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 徽标首字（标题为空时兜底 '?'）。 */
  private initial(): string {
    return this.item.title.length > 0 ? this.item.title.substring(0, 1) : '?';
  }

  private onShare(): void {
    this.share.shareText(`${this.item.title}：${this.item.description}`, {
      title: this.item.title,
      onShareCompleted: (targetName: string): void => {
        this.shareState = `已分享至：${targetName}`;
      },
      onPanelDismiss: (): void => {
        this.shareState = '分享面板已关闭';
      }
    });
  }

  @Builder
  header() {
    Column({ space: AppSpacing.SM }) {
      Row({ space: AppSpacing.MD }) {
        Column() {
          Text(this.initial())
            .fontSize(AppFontSize.TITLE_LG)
            .fontWeight(AppFontWeight.LIGHT)
            .fontColor($r('app.color.app_text_on_brand'))
        }
        .width(AppSize.TOUCH_COMFORT)
        .height(AppSize.TOUCH_COMFORT)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.qj_brand'))
        .borderRadius(AppRadius.MD)

        Column({ space: AppSpacing.XXS }) {
          Text(this.item.title)
            .fontSize(AppFontSize.TITLE_SM)
            .fontWeight(AppFontWeight.BOLD)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text(this.item.description)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      if (this.item.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
          CommonTag({ text: '范式', tone: TagTone.BRAND, accentColor: this.theme.accentColor })
          ForEach(this.item.tags, (tag: string) => {
            CommonTag({ text: tag, tone: TagTone.NEUTRAL })
          }, (tag: string) => tag)
        }
        .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  blockTitle(title: string) {
    Text(title)
      .fontSize(AppFontSize.CAPTION)
      .fontWeight(AppFontWeight.MEDIUM)
      .fontColor($r('app.color.app_text_tertiary'))
      .width('100%')
      .margin({ bottom: AppSpacing.SM })
  }

  @Builder
  bodyBlock() {
    Column({ space: AppSpacing.SM }) {
      this.blockTitle('正文（范式段落）')
      ForEach(this.item.body, (paragraph: string) => {
        Text(paragraph)
          .fontSize(AppFontSize.BODY)
          .lineHeight(AppLineHeight.for(AppFontSize.BODY, AppLineHeight.NORMAL))
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
      }, (paragraph: string, index: number) => `${index}`)
      if (this.item.body.length === 0) {
        Text('本项未提供正文（范式正文仅「详情页范式」条目携带）——结构与样式不受影响。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  actions() {
    Column({ space: AppSpacing.SM }) {
      this.blockTitle('操作条（机制收口 Platform，页面只决定「做什么」）')
      Row({ space: AppSpacing.MD }) {
        CommonButton({
          text: '分享本页', variant: ButtonVariant.PRIMARY, accentColor: this.theme.accentColor,
          onAction: () => {
            this.onShare();
          }
        })
        CommonButton({
          text: '收藏', variant: ButtonVariant.SECONDARY,
          onAction: () => {
            this.shareState = '已收藏（范式占位：接 PreferencesStore 持久化）';
          }
        })
      }
      .width('100%')

      Text(this.shareState.length > 0
        ? this.shareState
        : '操作反馈显示在此行')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.LG }) {
        this.header()
        this.bodyBlock()
        this.actions()
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: AppSpacing.XXXL + this.windowAdapter.bottomAvoidVp
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
