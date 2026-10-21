import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { REGEX_TEXT_LIMIT, RegexMatch, RegexOutcome, ToolRegex } from '../tools/ToolRegex';

/**
 * 正则测试器（v3.46）：pattern + flags + 文本 → 命中列表 / 捕获组 / 替换预览。
 *
 * 防护按分析文档：文本上限 8000 字符（截断提示）、匹配上限 5000 次、零宽匹配手动推进。
 */
@ComponentV2
export struct RegexToolView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 默认样例：手机号段，进页点「执行匹配」即有命中与捕获组。 */
  @Local pattern: string = '\\d{3,4}';
  @Local input: string = '客服 400-8000，分机 1234 与 5678';
  @Local ignoreCase: boolean = false;
  @Local multiline: boolean = false;
  @Local dotAll: boolean = false;
  @Local matches: RegexMatch[] = [];
  @Local replaced: string = '';
  @Local error: string = '';
  @Local truncated: boolean = false;

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private run(): void {
    const flags: string = ToolRegex.flagsOf(this.ignoreCase, this.multiline, this.dotAll);
    const outcome: RegexOutcome = ToolRegex.run(this.pattern, flags, this.input);
    if (!outcome.ok) {
      this.error = outcome.error;
      this.matches = [];
      this.replaced = '';
      this.truncated = false;
      return;
    }
    this.error = '';
    this.matches = outcome.matches;
    this.replaced = outcome.replaced;
    this.truncated = outcome.truncated;
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.XS }) {
          Text('正则测试器')
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('本地执行 RegExp：看命中位置、捕获组与替换预览。防 ReDoS 靠上限硬拦，不跑 Worker。')
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
          TextInput({ text: this.pattern, placeholder: '正则表达式，例如 ^\\d{3}-\\d{4}$' })
            .fontSize(AppFontSize.BODY_SM)
            .onChange((value: string): void => {
              this.pattern = value;
            })

          Row({ space: AppSpacing.SM }) {
            this.flagChip('i 忽略大小写', this.ignoreCase, (): void => {
              this.ignoreCase = !this.ignoreCase;
            })
            this.flagChip('m 多行', this.multiline, (): void => {
              this.multiline = !this.multiline;
            })
            this.flagChip('s 点跨行', this.dotAll, (): void => {
              this.dotAll = !this.dotAll;
            })
          }
          .width('100%')

          TextArea({ text: this.input, placeholder: `测试文本（上限 ${REGEX_TEXT_LIMIT} 字符）` })
            .height(120)
            .fontSize(AppFontSize.BODY_SM)
            .onChange((value: string): void => {
              this.input = value;
            })

          CommonButton({
            text: '执行匹配',
            variant: ButtonVariant.PRIMARY,
            fullWidth: true,
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

        if (this.matches.length > 0) {
          Column({ space: AppSpacing.SM }) {
            Text(`命中 ${this.matches.length} 处${this.truncated ? '（文本已截断到上限）' : ''}`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
            ForEach(this.matches, (m: RegexMatch, index: number) => {
              Column({ space: AppSpacing.XXS }) {
                Text(`#${index + 1} 位置 ${m.index}：${m.text.length === 0 ? '（零宽匹配）' : m.text}`)
                  .fontSize(AppFontSize.BODY_SM)
                  .fontColor($r('app.color.app_text_primary'))
                  .width('100%')
                  .copyOption(CopyOptions.LocalDevice)
                if (m.groups.length > 0) {
                  Text(`捕获组：${m.groups.join(' | ')}`)
                    .fontSize(AppFontSize.CAPTION)
                    .fontColor($r('app.color.app_text_tertiary'))
                    .width('100%')
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }, (m: RegexMatch, index: number): string => `${index}-${m.index}`)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(AppSpacing.LG)
          .borderRadius(AppRadius.XL)
          .backgroundColor($r('app.color.app_bg_card'))
        }

        if (this.replaced.length > 0) {
          Column({ space: AppSpacing.SM }) {
            Text('替换预览（命中处替换为 [命中]）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
            Text(this.replaced)
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

  @Builder
  flagChip(label: string, active: boolean, onTap: () => void) {
    Text(label)
      .fontSize(AppFontSize.CAPTION)
      .fontColor(active ? this.theme.onBrandColor() : $r('app.color.app_text_secondary'))
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
      .borderRadius(AppRadius.FULL)
      .backgroundColor(active ? this.theme.brandColor() : $r('app.color.app_bg_page'))
      .onClick((): void => {
        onTap();
      })
  }
}
