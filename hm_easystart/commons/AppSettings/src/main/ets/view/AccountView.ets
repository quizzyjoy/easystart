import { AppSnackBar } from '@easystart/app-component';
import { AppFontSize, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';

/**
 * 账号子页（v3.28，TODO-019；v3.33 上架预览态）：**预览模板**，账号体系未接入。
 *
 * - 顶部常驻「预览模板」声明，避免用户误以为可真实登录；
 * - 所有操作按钮（获取验证码 / 登录 / 第三方 / 注销）统一走应用级 SnackBar 提示
 *   「预览模板：该功能暂未接入」，不再静默无响应；
 * - 收藏/登录等状态不入库，仅作结构演示；
 * - 接入真实账号体系时：替换本文件按钮回调与状态源，并把声明改为真实协议入口。
 */
@ComponentV2
export struct AccountView {
  private bp(): string {
    return `${BreakpointManager.getInstance().breakpoint}`;
  }

  /** 预览态统一反馈：所有按钮点击都提示未接入，避免「点了没反应」。 */
  private showPreviewToast(): void {
    const uiCtx: UIContext = this.getUIContext();
    const host = uiCtx.getHostContext();
    // AppSnackBar.info 的 message 参数为 string（非 ResourceStr），故此处取字符串；
    // 极端情况下取不到资源时回退中文文案，保证提示永不静默。
    const msg: string = host !== undefined
      ? host.resourceManager.getStringSync($r('app.string.settings_account_preview_toast'))
      : '预览模板：该功能暂未接入';
    AppSnackBar.info(uiCtx, msg);
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        // —— 预览模板声明（常驻，最高优先级信息）——
        Text($r('app.string.settings_account_preview_note'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')

        // —— 登录卡（表单结构预览）——
        Column({ space: AppSpacing.MD }) {
          TextInput({ placeholder: $r('app.string.settings_account_phone_hint') })
            .type(InputType.PhoneNumber)
            .width('100%')

          Row({ space: AppSpacing.SM }) {
            TextInput({ placeholder: $r('app.string.settings_account_code_hint') })
              .type(InputType.Number)
              .layoutWeight(1)
            Button($r('app.string.settings_account_get_code'))
              .fontSize(AppFontSize.BODY_SM)
              .onClick((): void => {
                this.showPreviewToast();
              })
          }
          .width('100%')

          Button($r('app.string.settings_account_login'))
            .fontSize(AppFontSize.BODY)
            .width('100%')
            .onClick((): void => {
              this.showPreviewToast();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        // —— 第三方登录（品牌蓝底 + 白色图标，预览占位）——
        Text($r('app.string.settings_account_third_party'))
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)

        Row({ space: AppSpacing.XL }) {
          Button({ type: ButtonType.Circle, stateEffect: false }) {
            // v3.33：品牌蓝底上图标统一白色（原次要色在蓝底上对比不足）
            SymbolGlyph($r('sys.symbol.at'))
              .fontSize(AppSize.ICON_LG)
              .fontColor([$r('app.color.app_text_on_brand')])
          }
          .width(AppSize.AVATAR_SM)
          .height(AppSize.AVATAR_SM)
          .onClick((): void => {
            this.showPreviewToast();
          })

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            SymbolGlyph($r('sys.symbol.message'))
              .fontSize(AppSize.ICON_LG)
              .fontColor([$r('app.color.app_text_on_brand')])
          }
          .width(AppSize.AVATAR_SM)
          .height(AppSize.AVATAR_SM)
          .onClick((): void => {
            this.showPreviewToast();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // —— 注销账号（合规占位行；白底卡片保持中性图标，预览态点击同样提示）——
        Column() {
          Row({ space: AppSpacing.MD }) {
            SymbolGlyph($r('sys.symbol.person_xmark'))
              .fontSize(AppSize.ICON_LG)
              .fontColor([$r('app.color.app_text_secondary')])
            Column({ space: AppSpacing.XXS }) {
              Text($r('app.string.settings_account_delete'))
                .fontSize(AppFontSize.BODY)
                .fontColor($r('app.color.app_text_primary'))
              Text($r('app.string.settings_account_delete_desc'))
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_tertiary'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))
        .onClick((): void => {
          this.showPreviewToast();
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        // v3.32 宽度统一：左右额外内缩，对齐 HdsListItemCard 自带的约 17vp 横向内缩，
        // 使自绘卡片与设置行的背景宽度一致（否则子页卡片会比主页行宽一圈）。
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: AppSpacing.XXXL
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
