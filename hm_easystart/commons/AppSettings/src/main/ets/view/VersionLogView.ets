import { AppFontSize, AppFontWeight, AppLineHeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, common } from '@quizzyjoy/platform';
import { AppEmptyState } from '@easystart/app-component';
import { VersionLogEntry } from '../model/SettingsContentModels';
import { RawFileTextLoader } from '../util/RawFileTextLoader';

const RAWFILE_NAME: string = 'version_log.json';

/**
 * 版本更新日志子页（v3.28，TODO-019）：数据驱动版本条目列表。
 *
 * 内容源 rawfile/version_log.json（fork 替换点）；每条 version / date /
 * notes（字符串数组）；解析收口 VersionLogEntry.parseList，结构不符或
 * 读取失败兜底空数组 → 空态。
 */
@ComponentV2
export struct VersionLogView {
  @Local entries: VersionLogEntry[] = [];
  @Local emptyText: string = '';

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      this.emptyText = ctx.resourceManager.getStringSync($r('app.string.settings_version_log_empty').id);
    } catch (err) {
      this.emptyText = '';
    }
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const text: string = await RawFileTextLoader.load(ctx, RAWFILE_NAME);
      this.entries = VersionLogEntry.parseList(text);
    } catch (err) {
      this.entries = [];
    }
  }

  private bp(): string {
    return `${BreakpointManager.getInstance().breakpoint}`;
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        if (this.entries.length === 0) {
          AppEmptyState({
            icon: $r('sys.symbol.doc_text_badge_clock'),
            title: this.emptyText
          })
        } else {
          ForEach(this.entries, (entry: VersionLogEntry) => {
            Column({ space: AppSpacing.SM }) {
              Row({ space: AppSpacing.SM }) {
                Text(entry.version)
                  .fontSize(AppFontSize.TITLE_SM)
                  .fontWeight(AppFontWeight.BOLD)
                  .fontColor($r('app.color.app_text_primary'))
                Text(entry.date)
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_tertiary'))
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Bottom)

              ForEach(entry.notes, (note: string) => {
                Row({ space: AppSpacing.SM }) {
                  Text('•')
                    .fontSize(AppFontSize.BODY_SM)
                    .fontColor($r('app.color.app_text_tertiary'))
                  Text(note)
                    .fontSize(AppFontSize.BODY_SM)
                    .fontColor($r('app.color.app_text_secondary'))
                    .lineHeight(AppLineHeight.for(AppFontSize.BODY_SM, AppLineHeight.RELAXED))
                    .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }, (note: string): string => note)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(AppSpacing.LG)
            .borderRadius(AppRadius.XL)
            .backgroundColor($r('app.color.app_bg_card'))
          }, (entry: VersionLogEntry): string => `${entry.version}_${entry.date}`)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        // v3.32 宽度统一：左右额外内缩，对齐 HdsListItemCard 自带的约 17vp 横向内缩，
        // 使自绘卡片与设置行的背景宽度一致（否则子页卡片会比主页行宽一圈）。
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
