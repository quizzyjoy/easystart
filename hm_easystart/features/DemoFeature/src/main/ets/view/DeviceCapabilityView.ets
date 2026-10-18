import {
  AppOrientation,
  BreakpointManager,
  CapabilityManager,
  DeviceManager,
  DeviceType,
  FormFactor,
  HapticManager,
  I18nManager,
  NetworkMonitor,
  NetworkStatus,
  OrientationManager,
  ScreenManager,
  UiMetrics,
  WindowAdapter
} from '@quizzyjoy/platform';
import { AppFontSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { ButtonVariant, CommonButton } from '@quizzyjoy/vitalui';

/**
 * 设备能力示例视图：断点 / 形态因子 / 窗口避让 / 网络 / 国际化 / 系统控制。
 *
 * 只读部分由 Ability 层统一 attach / init（见 EntryAbility），本视图仅消费单例状态；
 * 「系统控制」区是新能力的降级示例入口（震动；屏幕方向 v3.14、常亮 v3.13 收口设置页），
 * 每项都走 Promise + WARN 降级路径：能力不支持时只记日志、不崩溃。
 */
@ComponentV2
export struct DeviceCapabilityView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local networkStatus: NetworkStatus = NetworkMonitor.getStatus();
  @Local orientationManager: OrientationManager = OrientationManager.getInstance();
  @Local screenManager: ScreenManager = ScreenManager.getInstance();

  private networkListener: (status: NetworkStatus) => void = () => {
  };

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  aboutToAppear(): void {
    this.networkListener = (status: NetworkStatus) => {
      this.networkStatus = status;
    };
    NetworkMonitor.onChange(this.networkListener);
  }

  aboutToDisappear(): void {
    NetworkMonitor.offChange(this.networkListener);
  }

  private networkLabel(): string {
    if (this.networkStatus === NetworkStatus.WIFI) {
      return 'Wi-Fi';
    }
    if (this.networkStatus === NetworkStatus.CELLULAR) {
      return '蜂窝网络';
    }
    if (this.networkStatus === NetworkStatus.ETHERNET) {
      return '以太网';
    }
    if (this.networkStatus === NetworkStatus.NONE) {
      return '离线';
    }
    return '未知';
  }

  private formFactorLabel(): string {
    const landscape: boolean = this.breakpoint.windowWidthVp > this.breakpoint.windowHeightVp;
    const factor: FormFactor = DeviceManager.getFormFactor(this.breakpoint.breakpoint, landscape);
    if (factor === FormFactor.COMPACT) {
      return 'COMPACT（紧凑）';
    }
    if (factor === FormFactor.EXPANDED) {
      return 'EXPANDED（宽松）';
    }
    return 'MEDIUM（中等）';
  }

  private deviceLabel(): string {
    const type: DeviceType = DeviceManager.getDeviceType();
    if (type === DeviceType.PHONE) {
      return '手机';
    }
    if (type === DeviceType.TABLET) {
      return '平板';
    }
    if (type === DeviceType.TWO_IN_ONE) {
      return '2in1';
    }
    if (type === DeviceType.TV) {
      return 'TV';
    }
    if (type === DeviceType.WEARABLE) {
      return '穿戴';
    }
    return '未知';
  }

  private orientationLabel(): string {
    return this.orientationManager.orientation === AppOrientation.LANDSCAPE ? '横屏' : '竖屏';
  }

  @Builder
  infoLine(label: string, value: string) {
    Row({ space: AppSpacing.SM }) {
      Text(label)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
      Blank()
      Text(value)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_primary'))
    }
    .width('100%')
    .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
  }

  build() {
    Scroll() {
      // 响应式令牌范式（ListStateView 同构）：外层居中，内层限宽 + 断点内边距
      Column() {
      Column({ space: AppSpacing.XS }) {
        Text('窗口与断点')
          .fontSize(AppFontSize.TITLE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .margin({ bottom: AppSpacing.XS })

        this.infoLine('断点（平台 API）', `${this.breakpoint.breakpoint}`)
        this.infoLine('栅格列数', `${this.breakpoint.gridColumns()}`)
        this.infoLine('窗口尺寸', `${Math.round(this.breakpoint.windowWidthVp)} × ${Math.round(this.breakpoint.windowHeightVp)} vp`)
        this.infoLine('布局形态', this.formFactorLabel())

        Text('设备与环境')
          .fontSize(AppFontSize.TITLE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .margin({ top: AppSpacing.LG, bottom: AppSpacing.XS })

        this.infoLine('设备类型', this.deviceLabel())
        this.infoLine('设备类型（原始）', `${CapabilityManager.getDeviceType()}`)
        this.infoLine('SDK API', `${CapabilityManager.SDK_API_VERSION}`)
        this.infoLine('系统语言', I18nManager.getSystemLanguage())
        this.infoLine('24 小时制', `${I18nManager.is24HourClock()}`)

        Text('网络（GET_NETWORK_INFO）')
          .fontSize(AppFontSize.TITLE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .margin({ top: AppSpacing.LG, bottom: AppSpacing.XS })

        this.infoLine('当前状态', this.networkLabel())
        this.infoLine('是否在线', `${NetworkMonitor.isOnline()}`)

        Text('安全区避让（WindowAdapter）')
          .fontSize(AppFontSize.TITLE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .margin({ top: AppSpacing.LG, bottom: AppSpacing.XS })

        this.infoLine('状态栏高度', `${Math.round(this.windowAdapter.statusBarHeightVp)} vp`)
        this.infoLine('手势条高度', `${Math.round(this.windowAdapter.navIndicatorHeightVp)} vp`)
        this.infoLine('顶部避让', `${Math.round(this.windowAdapter.topAvoidVp)} vp`)
        this.infoLine('底部避让', `${Math.round(this.windowAdapter.bottomAvoidVp)} vp`)

        Text('系统控制（震动示例；屏幕方向 / 常亮已收口至设置页通用设置）')
          .fontSize(AppFontSize.TITLE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .margin({ top: AppSpacing.LG, bottom: AppSpacing.XS })

        this.infoLine('屏幕方向', this.orientationLabel())
        this.infoLine('窗口亮度', `${this.screenManager.getBrightness()}`)
        this.infoLine('屏幕常亮', `${this.screenManager.keepScreenOn}`)

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({ text: '轻震动', variant: ButtonVariant.SECONDARY, onAction: () => {
            HapticManager.getInstance().light();
          } })
          CommonButton({ text: '中震动', variant: ButtonVariant.SECONDARY, onAction: () => {
            HapticManager.getInstance().medium();
          } })
          CommonButton({ text: '重震动', variant: ButtonVariant.DANGER, onAction: () => {
            HapticManager.getInstance().heavy();
          } })
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
