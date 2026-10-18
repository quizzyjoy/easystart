import { AppFontSize, AppFontWeight, AppLineHeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, common } from '@quizzyjoy/platform';
import { AppEmptyState } from '@easystart/app-component';
import { DeveloperMember, DeveloperProfile } from '../model/SettingsContentModels';
import { RawFileTextLoader } from '../util/RawFileTextLoader';

const RAWFILE_NAME: string = 'developer.json';

/**
 * 开发者团队子页（v3.28，TODO-019）：数据驱动团队展示。
 *
 * 内容源 rawfile/developer.json（fork 替换点）：intro 简介 + members
 * 成员列表（name / role / bio）；解析收口 DeveloperProfile.parse，
 * 结构不符或读取失败兜底空档案 → 空态。
 */
@ComponentV2
export struct DeveloperView {
  @Local profile: DeveloperProfile = new DeveloperProfile('', []);
  @Local emptyText: string = '';

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      this.emptyText = ctx.resourceManager.getStringSync($r('app.string.settings_developer_empty').id);
    } catch (err) {
      this.emptyText = '';
    }
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const text: string = await RawFileTextLoader.load(ctx, RAWFILE_NAME);
      this.profile = DeveloperProfile.parse(text);
    } catch (err) {
      this.profile = new DeveloperProfile('', []);
    }
  }

  private bp(): string {
    return `${BreakpointManager.getInstance().breakpoint}`;
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        if (this.profile.isEmpty()) {
          AppEmptyState({
            icon: $r('sys.symbol.person_2'),
            title: this.emptyText
          })
        } else {
          if (this.profile.intro.length > 0) {
            Text(this.profile.intro)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_secondary'))
              .lineHeight(AppLineHeight.for(AppFontSize.BODY_SM, AppLineHeight.RELAXED))
              .width('100%')
              .padding(AppSpacing.LG)
              .borderRadius(AppRadius.XL)
              .backgroundColor($r('app.color.app_bg_card'))
          }

          ForEach(this.profile.members, (member: DeveloperMember) => {
            Column({ space: AppSpacing.XS }) {
              Row({ space: AppSpacing.SM }) {
                Text(member.name)
                  .fontSize(AppFontSize.TITLE_SM)
                  .fontWeight(AppFontWeight.BOLD)
                  .fontColor($r('app.color.app_text_primary'))
                Text(member.role)
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_tertiary'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .alignItems(VerticalAlign.Bottom)

              Text(member.bio)
                .fontSize(AppFontSize.BODY_SM)
                .fontColor($r('app.color.app_text_secondary'))
                .lineHeight(AppLineHeight.for(AppFontSize.BODY_SM, AppLineHeight.RELAXED))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(AppSpacing.LG)
            .borderRadius(AppRadius.XL)
            .backgroundColor($r('app.color.app_bg_card'))
          }, (member: DeveloperMember): string => `${member.name}_${member.role}`)
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
