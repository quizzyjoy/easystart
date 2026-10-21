import { CommonButton, CommonToast, ButtonVariant } from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, CapabilityManager, PermissionHelper, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import type { common } from '@kit.AbilityKit';

/**
 * 运行时权限示例页（独立页，v3.79）。
 *
 * 为什么独立成页而不是塞进「组件示例 → 平台能力」：
 * 权限链路有四段状态（未申请 / 已授权 / 已拒绝 / 需去设置），塞进长页会被压缩成一行按钮，
 * fork 者看不出"拒绝之后还要做什么"。独立页才有空间把每段讲清楚。
 *
 * 前置条件：`product/entry` 与 `product/entry_pc` 的 module.json5 里声明了
 * `ohos.permission.APPROXIMATELY_LOCATION`；TV / 手表未声明，本页会显示禁用提示。
 */
@ComponentV2
export struct PermissionSampleView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local stateText: string = '状态检查中…';
  @Local granted: boolean = false;
  @Local busy: boolean = false;

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 仅手机 / 平板 / 2in1 的入口声明了该权限。 */
  private supported(): boolean {
    return CapabilityManager.isUnifiedHandsetFamily();
  }

  private ctx(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private async refresh(): Promise<void> {
    if (!this.supported()) {
      this.stateText = '本端未声明该权限（示例只在手机 / 2in1 生效）';
      this.granted = false;
      return;
    }
    const ok: boolean = await PermissionHelper.isGranted(this.ctx(), PermissionHelper.PERMISSION_LOCATION);
    this.granted = ok;
    this.stateText = ok ? '已授权：可读取近似位置' : '未授权：读取位置会被系统拦截';
  }

  private async request(): Promise<void> {
    if (this.busy || !this.supported()) {
      return;
    }
    this.busy = true;
    const denied: string[] = await PermissionHelper.request(this.ctx(), [PermissionHelper.PERMISSION_LOCATION]);
    this.busy = false;
    await this.refresh();
    CommonToast.info(denied.length === 0 ? '已授权近似位置' : '用户拒绝了授权，可点「去设置」手动开启');
  }

  /** 用户拒绝一次后系统不再弹窗，只能拉起权限设置页。 */
  private async openSetting(): Promise<void> {
    if (!this.supported()) {
      return;
    }
    try {
      const manager = abilityAccessCtrl.createAtManager();
      await manager.requestPermissionOnSetting(this.ctx(), [PermissionHelper.PERMISSION_LOCATION]);
      await this.refresh();
    } catch (err) {
      CommonToast.warn('拉起权限设置失败，请到 系统设置 → 应用 → 本应用 手动开启');
    }
  }

  aboutToAppear(): void {
    this.refresh();
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

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('四段闭环：申请 → 系统弹窗 → 拒绝 → 去设置。`PermissionHelper`（quizzyjoy/platform）封装了 checkAccessToken 与 requestPermissionsFromUser。')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')

        this.sectionTitle('当前状态')

        Row({ space: AppSpacing.SM }) {
          Text(PermissionHelper.PERMISSION_LOCATION)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
          Blank()
          Text(this.granted ? '已授权' : '未授权')
            .fontSize(AppFontSize.CAPTION)
            .fontColor(this.granted ? $r('app.color.qj_brand') : $r('app.color.app_text_tertiary'))
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 2, bottom: 2 })
            .borderRadius(AppRadius.FULL)
            .backgroundColor($r('app.color.app_bg_card'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.stateText)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))

        this.sectionTitle('操作')

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({
            text: this.busy ? '申请中…' : (this.granted ? '重新申请' : '申请近似位置'),
            variant: ButtonVariant.PRIMARY,
            disabled: this.busy || !this.supported(),
            onAction: (): void => {
              this.request();
            }
          })
          CommonButton({
            text: '去设置',
            variant: ButtonVariant.SECONDARY,
            disabled: !this.supported(),
            onAction: (): void => {
              this.openSetting();
            }
          })
          CommonButton({
            text: '刷新状态',
            variant: ButtonVariant.SECONDARY,
            disabled: !this.supported(),
            onAction: (): void => {
              this.refresh();
            }
          })
        }
        .width('100%')

        this.sectionTitle('为什么需要「去设置」')

        Text('用户拒绝一次后，系统不会再弹权限框（这是系统策略，不是 bug）。此时 requestPermissionsFromUser 会直接返回拒绝，只有 requestPermissionOnSetting 能把用户带到权限设置页。模板里必须演示这一步，否则 fork 者会以为"点了没反应"。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')

        if (!this.supported()) {
          Text('当前形态（TV / 手表）未在 module.json5 声明该权限，按钮已禁用。要在本端启用，请在对应模块的 requestPermissions 里补声明并带上 reason。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
            .width('100%')
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
