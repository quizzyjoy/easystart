import { util } from '@kit.ArkTS';
import { AppFontSize, AppLineHeight, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, common } from '@quizzyjoy/platform';

/**
 * rawfile 长文本阅读组件（关于组政策 / 许可子页共用，v3.13）。
 *
 * 文本放 AppSettings 域 resources/rawfile/（隐私政策 / 用户协议 / 开源许可），
 * fork 替换正文即可，无需改代码；模板不引 Markdown 依赖，纯文本分段展示。
 * 资源读取走 resourceManager（应用资源原语），TextDecoder 属 @kit.ArkTS 稳定工具。
 */
@ComponentV2
export struct RawFileTextView {
  /** rawfile 根下的文件名，如 policy_privacy.txt。 */
  @Param fileName: string = '';
  @Local content: string = '';
  @Local loadFailed: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const buffer: Uint8Array = await ctx.resourceManager.getRawFileContent(this.fileName);
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      this.content = decoder.decodeToString(buffer);
      this.loadFailed = false;
    } catch (err) {
      this.loadFailed = true;
    }
  }

  build() {
    Scroll() {
      Column() {
        Text(this.loadFailed ? $r('app.string.settings_rawfile_missing') : this.content)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .lineHeight(AppLineHeight.for(AppFontSize.BODY_SM, AppLineHeight.RELAXED))
          .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(BreakpointManager.getInstance().breakpoint) })
      .padding({
        left: AppSpacing.LG,
        right: AppSpacing.LG,
        top: AppSpacing.MD,
        bottom: AppSpacing.XXXL
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
  }
}
