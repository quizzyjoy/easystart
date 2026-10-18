import { HdsListItemCard, IconSize, PrefixIcon, SuffixTextAndArrow } from '@kit.UIDesignKit';
import { AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, common } from '@quizzyjoy/platform';
import { AppEmptyState, CommonToast } from '@easystart/app-component';
import { FeedbackChannels } from '../model/SettingsContentModels';
import { RawFileTextLoader } from '../util/RawFileTextLoader';
import { ClipboardUtil } from '../util/ClipboardUtil';

const RAWFILE_NAME: string = 'help_feedback.json';

/**
 * 帮助与反馈子页（v3.28，TODO-019）：数据驱动反馈渠道。
 *
 * 内容源 rawfile/help_feedback.json（fork 替换点）：email / qqGroup，
 * 空串渠道隐藏、全空显示空态；渠道行点击复制（ClipboardUtil 机制收口），
 * 复制结果 Toast 提示（QQ 群按 EasyMusic 三级兜底口径提示手动加群）。
 */
@ComponentV2
export struct HelpFeedbackView {
  @Local channels: FeedbackChannels = new FeedbackChannels('', '');
  @Local emptyText: string = '';

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      this.emptyText = ctx.resourceManager.getStringSync($r('app.string.settings_feedback_empty').id);
    } catch (err) {
      this.emptyText = '';
    }
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const text: string = await RawFileTextLoader.load(ctx, RAWFILE_NAME);
      this.channels = FeedbackChannels.parse(text);
    } catch (err) {
      this.channels = new FeedbackChannels('', '');
    }
  }

  /** 复制文本并 Toast 反馈；qqFallback 为真时按加群兜底口径提示。 */
  private copyWithToast(text: string, qqFallback: boolean): void {
    ClipboardUtil.copyText(text).then((ok: boolean): void => {
      if (!ok) {
        CommonToast.info($r('app.string.settings_feedback_copy_fail'));
        return;
      }
      CommonToast.info(qqFallback
        ? $r('app.string.settings_feedback_qq_fallback')
        : $r('app.string.settings_feedback_copy_ok'));
    });
  }

  private bp(): string {
    return `${BreakpointManager.getInstance().breakpoint}`;
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.SM }) {
        if (this.channels.isEmpty()) {
          AppEmptyState({
            icon: $r('sys.symbol.envelope_badge_adiowaves'),
            title: this.emptyText
          })
        } else {
          if (this.channels.email.length > 0) {
            HdsListItemCard({
              prefixItem: new PrefixIcon({
                iconSize: IconSize.SYSTEM_ICON,
                iconValue: { symbol: $r('sys.symbol.envelope') }
              }),
              textItem: {
                primaryText: { text: $r('app.string.settings_help_feedback_email') },
                secondaryText: { text: this.channels.email }
              },
              suffixItem: new SuffixTextAndArrow({ text: this.channels.email }),
              onClick: (): void => {
                this.copyWithToast(this.channels.email, false);
              }
            })
              .width('100%')
          }

          if (this.channels.qqGroup.length > 0) {
            HdsListItemCard({
              prefixItem: new PrefixIcon({
                iconSize: IconSize.SYSTEM_ICON,
                iconValue: { symbol: $r('sys.symbol.message') }
              }),
              textItem: {
                primaryText: { text: $r('app.string.settings_help_feedback_qq_group') },
                secondaryText: { text: this.channels.qqGroup }
              },
              suffixItem: new SuffixTextAndArrow({ text: this.channels.qqGroup }),
              onClick: (): void => {
                this.copyWithToast(this.channels.qqGroup, true);
              }
            })
              .width('100%')
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: AppSpacing.XXXL
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
