import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { JsonOutcome, ToolJson } from '../tools/ToolJson';

/**
 * JSON 工具台（v3.46）：格式化 / 压缩 / 键排序 / 路径查询 + 错误行定位。
 *
 * 错误行用二分前缀解析定位（`ToolJson.errorLine`），因为内置 JSON.parse 不给位置。
 */
@ComponentV2
export struct JsonToolView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 默认样例：进页点「格式化」立即有结果。 */
  @Local input: string = '{"name":"EasyStart","version":1000038,"features":["one-code","four-ends"]}';
  @Local indent: number = 2;
  @Local path: string = '$';
  @Local output: string = '';
  @Local error: string = '';

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private apply(kind: string): void {
    if (this.input.trim().length === 0) {
      this.error = '请先粘贴 JSON';
      this.output = '';
      return;
    }
    let outcome: JsonOutcome;
    if (kind === 'minify') {
      outcome = ToolJson.minify(this.input);
    } else if (kind === 'sort') {
      outcome = ToolJson.sortKeys(this.input, this.indent);
    } else if (kind === 'query') {
      outcome = ToolJson.query(this.input, this.path);
    } else {
      outcome = ToolJson.format(this.input, this.indent);
    }
    if (!outcome.ok) {
      this.error = outcome.error;
      this.output = '';
      return;
    }
    this.error = '';
    this.output = outcome.output;
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.XS }) {
          Text('JSON 工具台')
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('格式化 / 压缩 / 递归键排序 / $.a.b[0] 路径查询；语法错误会指出大概行号。纯本地解析。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        Column({ space: AppSpacing.MD }) {
          TextArea({ text: this.input, placeholder: '粘贴 JSON 文本' })
            .height(150)
            .fontSize(AppFontSize.BODY_SM)
            .onChange((value: string): void => {
              this.input = value;
            })

          Row({ space: AppSpacing.SM }) {
            CommonButton({
              text: '格式化',
              variant: ButtonVariant.PRIMARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.apply('format');
              }
            })
            CommonButton({
              text: '压缩',
              variant: ButtonVariant.SECONDARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.apply('minify');
              }
            })
            CommonButton({
              text: '键排序',
              variant: ButtonVariant.SECONDARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.apply('sort');
              }
            })
          }
          .width('100%')

          Row({ space: AppSpacing.SM }) {
            Text('缩进')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
            Text('2')
              .fontSize(AppFontSize.CAPTION)
              .fontColor(this.indent === 2 ? this.theme.onBrandColor() : $r('app.color.app_text_secondary'))
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
              .borderRadius(AppRadius.FULL)
              .backgroundColor(this.indent === 2 ? this.theme.brandColor() : $r('app.color.app_bg_page'))
              .onClick((): void => {
                this.indent = 2;
              })
            Text('4')
              .fontSize(AppFontSize.CAPTION)
              .fontColor(this.indent === 4 ? this.theme.onBrandColor() : $r('app.color.app_text_secondary'))
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
              .borderRadius(AppRadius.FULL)
              .backgroundColor(this.indent === 4 ? this.theme.brandColor() : $r('app.color.app_bg_page'))
              .onClick((): void => {
                this.indent = 4;
              })
          }
          .width('100%')

          TextInput({ text: this.path, placeholder: '路径，例如 $.data.items[0].id' })
            .fontSize(AppFontSize.CAPTION)
            .onChange((value: string): void => {
              this.path = value;
            })
          CommonButton({
            text: '路径查询',
            variant: ButtonVariant.SECONDARY,
            fullWidth: true,
            accentColor: this.theme.effectiveAccent(),
            onAction: (): void => {
              this.apply('query');
            }
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        if (this.error.length > 0) {
          Text(this.error)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_danger'))
            .width('100%')
            .padding(AppSpacing.MD)
            .borderRadius(AppRadius.MD)
            .backgroundColor($r('app.color.app_bg_card'))
        }

        if (this.output.length > 0) {
          Column({ space: AppSpacing.SM }) {
            Text(`结果（${this.output.length} 字符）`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
            Text(this.output)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_primary'))
              .width('100%')
              .copyOption(CopyOptions.LocalDevice)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(AppSpacing.LG)
          .borderRadius(AppRadius.XL)
          .backgroundColor($r('app.color.app_bg_card'))
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
