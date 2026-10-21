import { CommonButton, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';
import { NetReport, NetRepository } from '../data/NetRepository';

/**
 * 网络请求示例页（独立页，v3.79）。
 *
 * 为什么独立成页：网络有四种收场（2xx / 非 2xx / 超时 / 传输异常），每种处置不同；
 * 塞进长页只能放一个按钮，演示不出"分型"这件事。
 */
@ComponentV2
export struct NetworkSampleView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local busy: boolean = false;
  @Local summary: string = '尚未请求';
  @Local body: string = '';
  /** 最近一次用的 timeout（展示用） */
  @Local lastTimeout: number = 0;

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private async send(url: string, timeoutMs: number): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    this.lastTimeout = timeoutMs;
    this.summary = `请求中…（timeout ${timeoutMs}ms）`;
    this.body = '';
    const report: NetReport = await NetRepository.get(url, timeoutMs);
    this.busy = false;
    this.summary = report.summary();
    this.body = report.bodyPreview;
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(AppFontSize.TITLE_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .fontColor($r('app.color.app_text_primary'))
      .width('100%')
      .margin({ top: AppSpacing.SM, bottom: AppSpacing.XS })
  }

  @Builder
  urlLine(label: string, url: string) {
    Column({ space: AppSpacing.XXS }) {
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
      Text(url)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_quaternary'))
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('NetRepository.get(url, timeoutMs)：内部 http.createHttp() + finally destroy，把「HTTP 非 2xx / 超时 / 传输异常」分成三种收场，而不是一个 success=false。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        this.sectionTitle('最近一次结果')

        Text(this.summary)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))

        if (this.body.length > 0) {
          Text(this.body)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
            .maxLines(6)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding(AppSpacing.MD)
            .borderRadius(AppRadius.MD)
            .backgroundColor($r('app.color.app_bg_card'))
        }

        this.sectionTitle('三个分支')

        this.urlLine('① 正常（2xx）', NetRepository.URL_OK)
        this.urlLine('② 非 2xx（收到响应但状态码不对）', NetRepository.URL_404)
        this.urlLine('③ 超时（延迟 10s 的接口 + 2s timeout）', NetRepository.URL_SLOW)

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({
            text: '正常请求',
            variant: ButtonVariant.PRIMARY,
            disabled: this.busy,
            onAction: (): void => {
              this.send(NetRepository.URL_OK, 8000);
            }
          })
          CommonButton({
            text: '404',
            variant: ButtonVariant.SECONDARY,
            disabled: this.busy,
            onAction: (): void => {
              this.send(NetRepository.URL_404, 8000);
            }
          })
          CommonButton({
            text: '超时（2s）',
            variant: ButtonVariant.SECONDARY,
            disabled: this.busy,
            onAction: (): void => {
              this.send(NetRepository.URL_SLOW, 2000);
            }
          })
        }
        .width('100%')

        this.sectionTitle('照抄要点')

        Text('1. 每次请求都要 finally { request.destroy() }，否则底层连接与回调不释放。\n2. 超时由调用方给：connectTimeout 与 readTimeout 用同一个值，别只设一个。\n3. 超时判定用错误码 2300028，不要用 message 文本匹配。\n4. 需要 ohos.permission.INTERNET（system_grant，装包即得，不弹窗）。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
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
