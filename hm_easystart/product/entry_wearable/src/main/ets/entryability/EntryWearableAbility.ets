import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';
import { ColorModeManager } from '@quizzyjoy/platform';
import { AppBootstrap } from '@easystart/app-common';
import { CardLaunchTarget } from '../model/CardLaunchTarget';
import { WidgetRefresher } from '../model/WidgetRefresher';

const DOMAIN: string = 'app';
const TAG: string = 'EntryWearableAbility';

/**
 * 手表入口 Ability。
 *
 * 手表形态：断点恒为 xs，单列单页无 Tab。
 * 走 AppBootstrap 全链（prepare / attachWindow / detachWindow / destroy），
 * 不注入 Toast（AppCommon 不依赖 VitalUI，手表无 Toast 需求）。
 */
export default class EntryWearableAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(DOMAIN, TAG, 'onCreate');
    AppBootstrap.prepare(this.context);
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
    windowStage.loadContent('pages/WearableIndex', (err) => {
      if (err.code) {
        Logger.error(DOMAIN, TAG, `loadContent failed: ${JSON.stringify(err)}`);
        return;
      }
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      AppBootstrap.attachWindow(mainWindow.getUIContext(), mainWindow);
    });
  }

  onWindowStageDestroy(): void {
    AppBootstrap.detachWindow();
    Logger.info(DOMAIN, TAG, 'onWindowStageDestroy');
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
