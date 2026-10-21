import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { CodecMode, CodecResult, ToolCodec } from '../tools/ToolCodec';

/**
 * 编码工作台（v3.46）：Base64 / URL / HTML 实体 / JSON 字符串转义，四模式双向。
 *
 * 为什么合成一页：对开发者是同一个动作「这段东西编/解一下」，拆成五张卡反而难找。
 */
@ComponentV2
export struct CodecToolView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local modeIndex: number = 0;
  @Local urlSafe: boolean = false;
  /** 默认样例：进页点「编码」立即有结果。 */
  @Local input: string = '你好 EasyStart';
  @Local output: string = '';
  @Local error: string = '';

  private readonly modes: CodecMode[] = [CodecMode.BASE64, CodecMode.URL, CodecMode.HTML, CodecMode.JSON_STRING];
  private readonly modeLabels: string[] = ['Base64', 'URL', 'HTML 实体', 'JSON 转义'];

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private apply(encode: boolean): void {
    if (this.input.length === 0) {
      this.error = '请先输入内容';
      this.output = '';
      return;
    }
    const mode: CodecMode = this.modes[this.modeIndex];
    const result: CodecResult = encode
      ? ToolCodec.encode(mode, this.input, this.urlSafe)
      : ToolCodec.decode(mode, this.input, this.urlSafe);
    if (!result.ok) {
      this.error = result.error;
      this.output = '';
      return;
    }
    this.error = '';
    this.output = result.output;
  }

  /** 结果回填到输入，方便连续反向操作。 */
  private swap(): void {
    if (this.output.length === 0) {
      return;
    }
    this.input = this.output;
    this.output = '';
    this.error = '';
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.XS }) {
          Text('编码工作台')
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('Base64 / URL / HTML 实体 / JSON 转义四种编解码合成一页，全部本地计算。')
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
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.modeLabels, (label: string, index: number) => {
              Text(label)
                .fontSize(AppFontSize.CAPTION)
                .fontColor(index === this.modeIndex ? this.theme.onBrandColor() : $r('app.color.app_text_secondary'))
                .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
                .borderRadius(AppRadius.FULL)
                .backgroundColor(index === this.modeIndex ? this.theme.brandColor() : $r('app.color.app_bg_page'))
                .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
                .onClick((): void => {
                  this.modeIndex = index;
                  this.output = '';
                  this.error = '';
                })
            }, (label: string): string => label)
          }
          .width('100%')

          if (this.modeIndex === 0) {
            Row({ space: AppSpacing.SM }) {
              Text('URL-safe 变体（- _ 替代 + /）')
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_secondary'))
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.urlSafe })
                .onChange((isOn: boolean): void => {
                  this.urlSafe = isOn;
                })
            }
            .width('100%')
          }

          TextArea({ text: this.input, placeholder: '输入原文或编码结果' })
            .height(110)
            .fontSize(AppFontSize.BODY_SM)
            .onChange((value: string): void => {
              this.input = value;
            })

          Row({ space: AppSpacing.SM }) {
            CommonButton({
              text: '编码',
              variant: ButtonVariant.PRIMARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.apply(true);
              }
            })
            CommonButton({
              text: '解码',
              variant: ButtonVariant.SECONDARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.apply(false);
              }
            })
            CommonButton({
              text: '结果回填',
              variant: ButtonVariant.SECONDARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.swap();
              }
            })
          }
          .width('100%')
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
            Text('结果')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
            Text(this.output)
              .fontSize(AppFontSize.BODY_SM)
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
