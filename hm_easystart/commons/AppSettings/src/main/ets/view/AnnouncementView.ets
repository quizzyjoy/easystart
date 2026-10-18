import { AppFontSize, AppFontWeight, AppLineHeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, common } from '@quizzyjoy/platform';
import { AppEmptyState } from '@easystart/app-component';
import { AnnouncementEntry } from '../model/SettingsContentModels';
import { RawFileTextLoader } from '../util/RawFileTextLoader';

const RAWFILE_NAME: string = 'announcement.json';

/**
 * 公告子页（v3.28，TODO-019）：数据驱动列表。
 *
 * 内容源 rawfile/announcement.json（fork 替换点，_readme 字段为说明），
 * 解析收口 AnnouncementEntry.parseList；结构不符 / 文件缺失 / JSON 非法
 * 一律兜底空数组 → 空态，不崩溃。
 */
@ComponentV2
export struct AnnouncementView {
  @Local entries: AnnouncementEntry[] = [];
  @Local emptyText: string = '';

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      this.emptyText = ctx.resourceManager.getStringSync($r('app.string.settings_announcement_empty').id);
    } catch (err) {
      this.emptyText = '';
    }
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const text: string = await RawFileTextLoader.load(ctx, RAWFILE_NAME);
      this.entries = AnnouncementEntry.parseList(text);
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
            icon: $r('sys.symbol.bell'),
            title: this.emptyText
          })
        } else {
          ForEach(this.entries, (entry: AnnouncementEntry) => {
            Column({ space: AppSpacing.SM }) {
              Text(entry.title)
                .fontSize(AppFontSize.TITLE_SM)
                .fontWeight(AppFontWeight.BOLD)
                .fontColor($r('app.color.app_text_primary'))
              Text(entry.date)
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_tertiary'))
              Text(entry.body)
                .fontSize(AppFontSize.BODY_SM)
                .fontColor($r('app.color.app_text_secondary'))
                .lineHeight(AppLineHeight.for(AppFontSize.BODY_SM, AppLineHeight.RELAXED))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(AppSpacing.LG)
            .borderRadius(AppRadius.XL)
            .backgroundColor($r('app.color.app_bg_card'))
          }, (entry: AnnouncementEntry): string => `${entry.title}_${entry.date}`)
        }
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
