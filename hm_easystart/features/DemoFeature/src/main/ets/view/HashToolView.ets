import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { HashOutcome, ToolHash } from '../tools/ToolHash';

/**
 * 哈希校验页（v3.46，开发工具「数据处理」组第一项）。
 *
 * 纯本地：`cryptoFramework.createMd` 算摘要，输入文本、算法、期望值三项都由用户给；
 * 不支持某算法时 `ToolHash.digest` 返回 ok=false，本页只负责把那句话显示出来。
 */
@ComponentV2
export struct HashToolView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 默认给一段样例，进页即可点「计算摘要」看到结果（模板演示优先）。 */
  @Local input: string = 'EasyStart 模板 · 哈希演示';
  @Local expected: string = '';
  @Local algIndex: number = 0;
  @Local hex: string = '';
  @Local compare: string = '';
  @Local error: string = '';
  @Local busy: boolean = false;

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private async run(): Promise<void> {
    if (this.input.length === 0) {
      this.error = '请先输入要计算摘要的文本';
      this.hex = '';
      this.compare = '';
      return;
    }
    this.busy = true;
    const alg: string = ToolHash.ALGORITHMS[this.algIndex];
    const outcome: HashOutcome = await ToolHash.digest(alg, this.input);
    this.busy = false;
    if (!outcome.ok) {
      this.error = outcome.error;
      this.hex = '';
      this.compare = '';
      return;
    }
    this.error = '';
    this.hex = outcome.hex;
    this.compare = ToolHash.compare(this.expected, outcome.hex);
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.XS }) {
          Text('哈希校验')
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('本地计算 SHA-256 / SHA-512 / SHA-1 / MD5 摘要，可粘贴期望值做一致性核对。不联网、不需要权限。')
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
          Text('算法')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
          Row({ space: AppSpacing.SM }) {
            ForEach(ToolHash.ALGORITHMS, (alg: string, index: number) => {
              Text(alg)
                .fontSize(AppFontSize.CAPTION)
                .fontColor(index === this.algIndex ? this.theme.onBrandColor() : $r('app.color.app_text_secondary'))
                .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
                .borderRadius(AppRadius.FULL)
                .backgroundColor(index === this.algIndex ? this.theme.brandColor() : $r('app.color.app_bg_page'))
                .onClick((): void => {
                  this.algIndex = index;
                })
            }, (alg: string): string => alg)
          }
          .width('100%')

          TextArea({ text: this.input, placeholder: '输入要计算摘要的文本' })
            .height(120)
            .fontSize(AppFontSize.BODY_SM)
            .onChange((value: string): void => {
              this.input = value;
            })

          CommonButton({
            text: '计算摘要',
            variant: ButtonVariant.PRIMARY,
            fullWidth: true,
            loading: this.busy,
            accentColor: this.theme.effectiveAccent(),
            onAction: (): void => {
              this.run();
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

        if (this.hex.length > 0) {
          Column({ space: AppSpacing.SM }) {
            Text(`${ToolHash.ALGORITHMS[this.algIndex]} 摘要`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
            Text(this.hex)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_primary'))
              .width('100%')
              .copyOption(CopyOptions.LocalDevice)

            TextInput({ text: this.expected, placeholder: '粘贴期望摘要做核对（可留空）' })
              .fontSize(AppFontSize.CAPTION)
              .onChange((value: string): void => {
                this.expected = value;
                this.compare = ToolHash.compare(value, this.hex);
              })

            if (this.compare.length > 0) {
              Text(`核对结果：${this.compare}`)
                .fontSize(AppFontSize.BODY_SM)
                .fontWeight(AppFontWeight.MEDIUM)
                .fontColor(this.compare === '一致' ? $r('app.color.app_success') : $r('app.color.app_danger'))
                .width('100%')
            }
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
