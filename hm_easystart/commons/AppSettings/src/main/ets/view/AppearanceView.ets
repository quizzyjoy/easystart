import { AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';
import { SchemaSettingsSection } from './SchemaSettingsSection';

/**
 * 主题外观子页（v3.14 独立二级子页；v3.30 schema 化，TODO-021）：
 * 显示模式（builtin 行，SuffixSelect）+ 强调色（块型 builtin，AccentColorSetting
 * 取色 Sheet + 收藏 + 恢复 + 预览）——由 rawfile/settings_schema.json（页键
 * appearance）定义、SchemaSettingsSection 统一渲染，行为零改。
 *
 * 本页由入口 pageMap 注册（AppRoute.APPEARANCE），titleBar 标题在入口层装配；
 * VM 为渲染器实例自持（偏好以 PreferencesStore 为单一事实源、Manager 单例即时生效）。
 */
@ComponentV2
export struct AppearanceView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.SM }) {
        SchemaSettingsSection({ page: 'appearance' })
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
