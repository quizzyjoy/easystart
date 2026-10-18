import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { AppEnvManager, AppEnvSnapshot, BreakpointManager } from '@quizzyjoy/platform';
import { AccountSection } from './section/AccountSection';
import { SettingsFooter } from './section/SettingsFooter';
import { SchemaSettingsSection } from './SchemaSettingsSection';

/**
 * 设置主页（v3.28 完备 IA；v3.30 schema 化，TODO-021）：
 * 应用头（图标 / 名称 / 版本）→ 账号卡占位 → 组区（schema 驱动：外观与通用 /
 * 互动与反馈 / 关于）→ 页脚（版权 + 备案留空隐藏）。
 *
 * v3.30 起组区由 rawfile/settings_schema.json 定义（页键 home），fork 改 JSON
 * 即得定制设置页；行型七类 / 组型两类由 SchemaSettingsSection 统一渲染
 * （builtin 行为行逐字复刻 v3.28 接线，行为零改；chip 彩底贴片复用 chart_c01~c20）。
 * 应用头 / 账号卡 / 页脚为固定区块（schema 外）；滚动 / 限宽 / pagePadding
 * 与各子页同构，避让由 HdsNavDestination 协调。
 */
@ComponentV2
export struct SettingsView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local env: AppEnvSnapshot = AppEnvManager.get();
  /** 设置域内层导航栈（v3.32 双层栈：域内跳转压内层，不再压外层应用栈）。 */
  @Param settingsStack: NavPathStack = new NavPathStack();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  appHeader() {
    Column({ space: AppSpacing.SM }) {
      // 蓝图默认 foreground 为透明占位，桌面图标实际呈 background 品牌蓝底；
      // 此处与桌面图标保持一致（AboutView 同款先例），fork 替换分层图标后自动更新。
      Image($r('app.media.background'))
        .width(AppSize.AVATAR_MD)
        .height(AppSize.AVATAR_MD)
        .borderRadius(AppRadius.XL)
      Text($r('app.string.app_name'))
        .fontSize(AppFontSize.TITLE_LG)
        .fontWeight(AppFontWeight.BOLD)
        .fontColor($r('app.color.app_text_primary'))
      Text(this.env.versionName)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_tertiary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: AppSpacing.LG, bottom: AppSpacing.XS })
  }

  build() {
    Scroll() {
      Column() {
        Column({ space: DesignToken.sectionSpacing() }) {
          // —— 应用头 ——
          this.appHeader()

          // —— 账号卡占位（固定区块） ——
          AccountSection({ settingsStack: this.settingsStack })

          // —— 组区（schema 驱动：外观与通用 / 互动与反馈 / 关于） ——
          SchemaSettingsSection({ page: 'home', settingsStack: this.settingsStack })

          // —— 页脚 ——
          SettingsFooter()
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
        .padding({
          left: DesignToken.pagePadding(this.bp()),
          right: DesignToken.pagePadding(this.bp()),
          top: AppSpacing.LG,
          bottom: AppSpacing.XXXL
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
