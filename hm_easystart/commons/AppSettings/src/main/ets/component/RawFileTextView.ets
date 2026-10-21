import { util } from '@kit.ArkTS';
import { AppFontSize, AppLineHeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, common } from '@quizzyjoy/platform';
import { AppDialog, DialogSemantic } from '@easystart/app-component';

/**
 * rawfile 长文本阅读组件（关于组政策 / 许可子页共用，v3.13）。
 *
 * 文本放 AppSettings 域 resources/rawfile/（隐私政策 / 用户协议 / 开源许可 / SDK 清单），
 * fork 替换正文即可，无需改代码；模板不引 Markdown 依赖，纯文本分段展示。
 * 资源读取走 resourceManager（应用资源原语），TextDecoder 属 @kit.ArkTS 稳定工具。
 *
 * v3.50：开源许可与 SDK 清单的正文改为**真实信息**（真实仓库地址、真实依赖及其许可），
 * 顶部保留「信息」按钮，点击说明「fork 后请替换」；infoTip 为空时不渲染该按钮。
 */
@ComponentV2
export struct RawFileTextView {
  /** rawfile 根下的文件名，如 policy_privacy.txt。 */
  @Param fileName: string = '';
  /** 非空时在正文上方渲染「信息」按钮，点击弹出该提示文案。 */
  @Param infoTip: string = '';
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

  /** 弹出「本页为模板真实信息示例」提示。 */
  private showInfo(): void {
    AppDialog.open(this.getUIContext(), DialogSemantic.CONFIRM,
      '关于本页信息', this.infoTip, (): void => {
      }, '我知道了');
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.SM }) {
        if (this.infoTip.length > 0) {
          Row({ space: AppSpacing.XS }) {
            SymbolGlyph($r('sys.symbol.info_circle'))
              .fontSize(AppFontSize.CAPTION)
              .fontColor([$r('app.color.app_text_secondary')])
            Text($r('app.string.settings_info_replace_hint'))
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .layoutWeight(1)
          }
          .width('100%')
          .padding({
            left: AppSpacing.SM,
            right: AppSpacing.SM,
            top: AppSpacing.XS,
            bottom: AppSpacing.XS
          })
          .borderRadius(AppRadius.SM)
          .backgroundColor($r('app.color.app_bg_page_deep'))
          .onClick((): void => {
            this.showInfo();
          })
        }
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
