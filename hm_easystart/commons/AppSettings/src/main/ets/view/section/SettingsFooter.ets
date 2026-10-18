import { AppFontSize, AppSpacing } from '@quizzyjoy/foundation';
import { common } from '@quizzyjoy/platform';

/**
 * 设置主页页脚（v3.28 TODO-019）：版权行 + 备案行。
 *
 * - 版权行：格式资源「© %s %s」（年份 + 应用名），fork 后自动跟随；
 * - 备案行：资源键 settings_footer_icp 默认空字符串 → 不渲染；
 *   fork 后按需填入备案信息即自动显示（不碰合规红线，留白即隐藏）。
 */
@ComponentV2
export struct SettingsFooter {
  @Local yearText: string = '';
  @Local appName: string = '';
  @Local icpText: string = '';

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.yearText = `${new Date().getFullYear()}`;
    try {
      this.appName = ctx.resourceManager.getStringSync($r('app.string.app_name').id);
      this.icpText = ctx.resourceManager.getStringSync($r('app.string.settings_footer_icp').id);
    } catch (err) {
      this.appName = '';
      this.icpText = '';
    }
  }

  build() {
    Column({ space: AppSpacing.XS }) {
      Text($r('app.string.settings_footer_copyright', this.yearText, this.appName))
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_tertiary'))
      if (this.icpText.length > 0) {
        Text(this.icpText)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: AppSpacing.LG })
  }
}
