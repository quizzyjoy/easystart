import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { ToolId } from '../tools/ToolId';

/**
 * ID 生成（v3.46）：UUID v4 + ULID，附时间戳三栏互看。
 *
 * 全部本地生成（`util.generateRandomUUID` 与 `cryptoFramework.createRandom`），零依赖。
 */
@ComponentV2
export struct IdToolView {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local count: number = 1;
  @Local ids: string[] = [];
  @Local epochMs: number = Date.now();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private generate(): void {
    const list: string[] = [];
    const limit: number = this.count > 50 ? 50 : this.count;
    for (let i = 0; i < limit; i++) {
      list.push(ToolId.ulid());
    }
    this.ids = list;
    this.epochMs = Date.now();
  }

  private generateUuid(): void {
    const list: string[] = [];
    const limit: number = this.count > 50 ? 50 : this.count;
    for (let i = 0; i < limit; i++) {
      list.push(ToolId.uuidV4());
    }
    this.ids = list;
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.XS }) {
          Text('ID 生成')
            .fontSize(AppFontSize.BODY)
            .fontWeight(AppFontWeight.MEDIUM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text('UUID v4 与 ULID（时间序）本地批量生成；ULID 的字典序等于时间序，适合当 requestId / traceId。')
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
          Row({ space: AppSpacing.SM }) {
            Text('数量（1~50）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .layoutWeight(1)
            Text(`${this.count}`)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_primary'))
          }
          .width('100%')

          Slider({ value: this.count, min: 1, max: 50, step: 1 })
            .width('100%')
            .onChange((value: number): void => {
              this.count = Math.round(value);
            })

          Row({ space: AppSpacing.SM }) {
            CommonButton({
              text: '生成 ULID',
              variant: ButtonVariant.PRIMARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.generate();
              }
            })
            CommonButton({
              text: '生成 UUID',
              variant: ButtonVariant.SECONDARY,
              accentColor: this.theme.effectiveAccent(),
              onAction: (): void => {
                this.generateUuid();
              }
            })
          }
          .width('100%')

          Text(`当前时间戳：${this.epochMs}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
          Text(ToolId.iso(this.epochMs))
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
            .copyOption(CopyOptions.LocalDevice)
          Text(ToolId.local(this.epochMs))
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        if (this.ids.length > 0) {
          Column({ space: AppSpacing.SM }) {
            Text(`已生成 ${this.ids.length} 条（长按可复制单条）`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
              .width('100%')
            ForEach(this.ids, (id: string) => {
              Text(id)
                .fontSize(AppFontSize.BODY_SM)
                .fontColor($r('app.color.app_text_primary'))
                .width('100%')
                .padding({ top: AppSpacing.XXS, bottom: AppSpacing.XXS })
                .copyOption(CopyOptions.LocalDevice)
            }, (id: string, index: number): string => `${index}-${id}`)
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
