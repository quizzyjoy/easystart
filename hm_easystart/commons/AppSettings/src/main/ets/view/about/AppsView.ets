import { common } from '@quizzyjoy/platform';
import { AppLauncher, LaunchResult } from '@quizzyjoy/platform';
import { AppDialog, CommonTag, DialogSemantic, TagTone } from '@easystart/app-component';
import { AppFontSize, AppRadius, AppSpacing } from '@quizzyjoy/foundation';
import { AppMatrix, AppMatrixEntry, AppEntryStatus } from '../../model/AppMatrix';

/**
 * 应用矩阵子页（v3.50）：趣开发系列四个应用的聚合展示。
 *
 * 点击行为是一条完整回退链（实现见 `quizzyjoy/Platform` 的 `AppLauncher`）：
 * 1. 已安装 → 直接拉起目标应用；
 * 2. 未安装 → 打开应用市场详情页；
 * 3. 未上架 / 市场也打不开 → 弹「应用介绍」弹窗（当前为占位文案）。
 *
 * 本应用自身（status = SELF）不上抛拉起，改走 `onOpenSelf` 回到「关于本应用」。
 */
@ComponentV2
export struct AppsView {
  /** 本应用被点击时的跳转（由设置域目的地提供，域内压内层栈）。 */
  @Event onOpenSelf: () => void = (): void => {
  };

  /** 包名等宽展示用等宽字体族（不引外部字体，靠 CSS 等宽回退）。 */
  private static readonly MONO_FONT: string = 'HarmonyOS Sans Mono, monospace';

  private async handleOpen(entry: AppMatrixEntry): Promise<void> {
    if (entry.status === AppEntryStatus.SELF) {
      this.onOpenSelf();
      return;
    }
    if (entry.status === AppEntryStatus.UNPUBLISHED) {
      this.showIntro(entry);
      return;
    }
    const context: common.UIAbilityContext =
      this.getUIContext().getHostContext() as common.UIAbilityContext;
    const result: LaunchResult = await AppLauncher.open(context, entry.bundleName);
    if (result === LaunchResult.UNAVAILABLE) {
      this.showIntro(entry);
    }
  }

  /** 未上架 / 无法跳转时的介绍弹窗（内容占位，下轮补真实介绍）。 */
  private showIntro(entry: AppMatrixEntry): void {
    AppDialog.open(this.getUIContext(), DialogSemantic.CONFIRM,
      '应用介绍', `${entry.intro}\n\n（此页为占位内容，后续补上截图与详细介绍）`, (): void => {
      }, '我知道了');
  }

  @Builder
  appRow(entry: AppMatrixEntry) {
    Row({ space: AppSpacing.MD }) {
      Image(entry.icon)
        .width(56)
        .height(56)
        .borderRadius(AppRadius.MD)
        .objectFit(ImageFit.Cover)
      Column({ space: 4 }) {
        Row({ space: AppSpacing.XS }) {
          Text(entry.name)
            .fontSize(AppFontSize.BODY)
            .fontColor($r('app.color.app_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          CommonTag({ text: entry.statusLabel, tone: TagTone.NEUTRAL })
        }
        .width('100%')

        Text(entry.desc)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(entry.bundleName)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .fontFamily(AppsView.MONO_FONT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppFontSize.CAPTION)
        .fontColor([$r('app.color.app_text_tertiary')])
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.handleOpen(entry);
    })
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text($r('app.string.apps_intro'))
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .lineHeight(AppFontSize.BODY_SM * 1.6)
          .width('100%')

        ForEach(AppMatrix.all(), (entry: AppMatrixEntry) => {
          this.appRow(entry)
        }, (entry: AppMatrixEntry): string => entry.id)

        Text($r('app.string.apps_fork_tip'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .padding({ top: AppSpacing.SM })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: AppSpacing.LG,
        right: AppSpacing.LG,
        top: AppSpacing.MD,
        bottom: AppSpacing.XXXL
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
