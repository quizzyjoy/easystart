import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';
import { ColorModeManager } from '@quizzyjoy/platform';
import { AppBootstrap, AppThemeState } from '@easystart/app-common';
import { AppThemeApplier, CommonToast } from '@easystart/app-component';
import { CardLaunchTarget } from '../model/CardLaunchTarget';
import { WidgetRefresher } from '../model/WidgetRefresher';

const DOMAIN: string = 'app';
const TAG: string = 'PcAbility';

/**
 * 2in1（PC）专用入口 Ability（v2.3.2 按用户决断拆分，对齐官方 sample_in_harmonyos 的 products/pc）。
 *
 * 装配链与 EntryAbility 完全一致（AppBootstrap 编排），差异仅在：
 * 1. 独立 Ability 类名与页面（pages/PcIndex）
 * 2. 后续 PC 专属行为（多窗口/键鼠交互）在本层扩展，不回灌统一入口
 */
export default class PcAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(DOMAIN, TAG, 'onCreate');
    AppBootstrap.prepare(this.context);
    // 表现层装配：启动恢复「主题包 + 强调色」，一次铺满 L3（组件）+ L4（系统组件默认色）
    // AppCommon 只读不注入（手表要可用），落地在 Ability（与 CommonToast.attach 同范式）
    AppBootstrap.restoreTheme().then((state: AppThemeState): void => {
      AppThemeApplier.apply(state.presetId, state.accentHex);
    });
    this.captureCardTarget(want);
  }

  /** 应用已在运行时点击卡片：把深链目标寄存给已有页面（页面 onPageShow 消费）。 */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(DOMAIN, TAG, 'onNewWant');
    this.captureCardTarget(want);
  }

  /** 读取 want 里的卡片深链目标并寄存（无则忽略）。 */
  private captureCardTarget(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return;
    }
    const target: Object | undefined = params['target'];
    if (typeof target === 'string' && target.length > 0) {
      CardLaunchTarget.set(target);
      Logger.info(DOMAIN, TAG, `card launch target=${target}`);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    ColorModeManager.getInstance().updateFromConfiguration(newConfig);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(DOMAIN, TAG, 'onWindowStageCreate');
    windowStage.loadContent('pages/PcIndex', (err) => {
      if (err.code) {
        Logger.error(DOMAIN, TAG, `loadContent failed: ${JSON.stringify(err)}`);
        return;
      }
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      const uiContext = mainWindow.getUIContext();
      AppBootstrap.attachWindow(uiContext, mainWindow);
      CommonToast.attach((message: ResourceStr, duration: number): void => {
        uiContext.getPromptAction().showToast({ message: message, duration: duration });
      });
    });
  }

  onWindowStageDestroy(): void {
    AppBootstrap.detachWindow();
    CommonToast.detach();
    Logger.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    Logger.info(DOMAIN, TAG, 'onForeground');
  }

  onBackground(): void {
    Logger.info(DOMAIN, TAG, 'onBackground');
    // 应用内改完偏好离开应用时，把最新偏好推给已添加的卡片（不必等 30min 定时刷新）
    WidgetRefresher.refreshAll(this.context).catch((err: BusinessError) => {
      Logger.warn(DOMAIN, TAG, `widget refresh failed: ${err.message}`);
    });
  }

  onDestroy(): void {
    AppBootstrap.destroy();
    Logger.info(DOMAIN, TAG, 'onDestroy');
  }
}
