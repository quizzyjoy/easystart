import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import {
  AppEnvManager,
  AppEnvSnapshot,
  AppGalleryHelper,
  BreakpointManager,
  MarketHelper,
  StoreCapabilityResult
} from '@quizzyjoy/platform';
import { ButtonVariant, CommonButton } from '@quizzyjoy/vitalui';
import { CommonToast } from '@easystart/app-component';
import { StoreFeedback } from '../../util/StoreFeedback';

/** 开源仓库地址（v3.33 上架：关于页直达）。 */
const REPO_URL: string = 'https://github.com/quizzyjoy/easystart';

/**
 * 关于本应用子页（v3.13，TODO-003；v3.39 上架后能力接入）：
 * 应用头（图标 / 名称 / 版本）+ 环境信息卡 + 检查更新 / 给我们评分 / 开源仓库。
 *
 * 检查更新与评分走 Platform 的 AppGalleryHelper（应用市场官方能力），失败按
 * StoreFeedback 的分档文案提示并兜底跳市场详情页；系统不支持时同样是跳市场，
 * 不出现「点了没反应」。bundleName 由 AppEnvManager 快照自动提供，fork 改包名零代码改动。
 */
@ComponentV2
export struct AboutView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local env: AppEnvSnapshot = AppEnvManager.get();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 检查更新：官方接口优先 → 有新版拉起系统升级框 → 其余降级到市场详情页。 */
  private checkUpdate(): void {
    const helper: AppGalleryHelper = AppGalleryHelper.getInstance();
    helper.checkUpdate(true).then((result: StoreCapabilityResult): void => {
      if (result === StoreCapabilityResult.OK) {
        helper.showUpdateDialog().then((shown: StoreCapabilityResult): void => {
          if (shown !== StoreCapabilityResult.OK) {
            StoreFeedback.openMarket($r('app.string.settings_update_failed'));
          }
        });
        return;
      }
      const message: ResourceStr = StoreFeedback.updateMessage(result);
      if (`${message}`.length > 0) {
        CommonToast.info(message);
        return;
      }
      StoreFeedback.openMarket($r('app.string.settings_update_failed'));
    });
  }

  /** 应用内评分：官方弹窗优先；未登录 / 已评过给单独文案，其余降级到市场。 */
  private rateApp(): void {
    AppGalleryHelper.getInstance().showCommentDialog().then((result: StoreCapabilityResult): void => {
      if (result === StoreCapabilityResult.OK) {
        return;
      }
      const message: ResourceStr = StoreFeedback.rateMessage(result);
      if (`${message}`.length > 0) {
        CommonToast.info(message);
        return;
      }
      StoreFeedback.openMarket($r('app.string.settings_rate_failed'));
    });
  }

  /** 打开开源仓库（系统浏览器）；无处理方时降级提示。 */
  private openRepo(): void {
    MarketHelper.getInstance().openUri(REPO_URL).then((ok: boolean): void => {
      if (!ok) {
        CommonToast.info($r('app.string.about_open_repo_failed'));
      }
    });
  }

  @Builder
  infoRow(label: ResourceStr, value: ResourceStr) {
    Row() {
      Text(label)
        .fontSize(AppFontSize.BODY)
        .fontColor($r('app.color.app_text_primary'))
        .layoutWeight(1)
      Text(value)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_tertiary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        // —— 应用头 ——
        Column({ space: AppSpacing.SM }) {
        // 蓝图默认 foreground 为透明占位，桌面图标实际呈 background 品牌蓝底；
        // 此处与桌面图标保持一致，fork 替换分层图标后自动更新。
        Image($r('app.media.background'))
          .width(AppSize.AVATAR_LG)
          .height(AppSize.AVATAR_LG)
          .borderRadius(AppRadius.XL)
          Text($r('app.string.app_name'))
            .fontSize(AppFontSize.TITLE)
            .fontWeight(AppFontWeight.BOLD)
            .fontColor($r('app.color.app_text_primary'))
          Text(this.env.versionName)
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_tertiary'))
        }
        .width('100%')
        .padding({ top: AppSpacing.LG, bottom: AppSpacing.MD })

        // —— 环境信息卡 ——
        Column({ space: AppSpacing.MD }) {
          this.infoRow($r('app.string.about_version_name'), this.env.versionName || '—')
          this.infoRow($r('app.string.about_version_code'), `${this.env.versionCode}`)
          this.infoRow($r('app.string.about_api_level'), `API ${this.env.sdkApiVersion}`)
          this.infoRow($r('app.string.about_device_type'), this.env.deviceType || '—')
          this.infoRow($r('app.string.about_product_model'), this.env.productModel || '—')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— 市场操作 ——
        Column({ space: AppSpacing.MD }) {
          CommonButton({
            text: $r('app.string.settings_check_update'),
            variant: ButtonVariant.PRIMARY,
            fullWidth: true,
            onAction: (): void => {
              this.checkUpdate();
            }
          })
          CommonButton({
            text: $r('app.string.settings_rate'),
            variant: ButtonVariant.SECONDARY,
            fullWidth: true,
            onAction: (): void => {
              this.rateApp();
            }
          })
          CommonButton({
            text: $r('app.string.about_open_source_repo'),
            variant: ButtonVariant.SECONDARY,
            fullWidth: true,
            onAction: (): void => {
              this.openRepo();
            }
          })
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        // v3.32 宽度统一：左右额外内缩，对齐 HdsListItemCard 自带的约 17vp 横向内缩，
        // 使自绘卡片与设置行的背景宽度一致（否则子页卡片会比主页行宽一圈）。
        left: DesignToken.pagePadding(this.bp()) + AppSpacing.LG + AppSpacing.XXS,
        right: DesignToken.pagePadding(this.bp()) + AppSpacing.LG + AppSpacing.XXS,
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
