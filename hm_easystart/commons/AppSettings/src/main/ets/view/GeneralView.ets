import { AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';
import { SchemaSettingsSection } from './SchemaSettingsSection';

/**
 * 通用设置子页（v3.14 独立二级子页；v3.30 schema 化，TODO-021）：
 * 语言 / 字体大小 / 触感反馈 / 屏幕常亮 / 屏幕方向（仅 phone/tablet）/ 清除缓存 /
 * 系统设置——全部为 builtin 行为行，由 rawfile/settings_schema.json（页键 general）
 * 定义、SchemaSettingsSection 统一渲染；行为接线逐字复刻 v3.28（SettingsViewModel
 * 即时生效链零改），屏幕方向行的设备门控改由 schema deviceTypes 声明。
 *
 * 本页由入口 pageMap 注册（AppRoute.GENERAL），titleBar 标题在入口层装配。
 */
@ComponentV2
export struct GeneralView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.SM }) {
        SchemaSettingsSection({ page: 'general' })
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
