import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Logger } from '@quizzyjoy/foundation';
import { ColorModeManager } from '@quizzyjoy/platform';
import { AppBootstrap } from '@easystart/app-common';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { CommonToast } from '@easystart/app-component';

const DOMAIN: string = 'app';
const TAG: string = 'EntryTvAbility';

/**
 * TV 入口 Ability。
 *
 * 与统一入口的差异：首屏页面不同（TvIndex，10-foot UI）；Tab 用原生 Tabs（HDS 例外 E1）。
 * 装配已下沉 AppBootstrap（项目 Common），本层保留 Toast 注入与配置变更回调。
 */
export default class EntryTvAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(DOMAIN, TAG, 'onCreate');
    AppBootstrap.prepare(this.context);
    // 表现层装配：启动恢复强调色（AppCommon 不依赖 VitalUI 仅读出，注入在本层；手表入口不调）
    AppBootstrap.restoreAccentColor().then((hex: string): void => {
      if (hex.length > 0) {
        UiThemeManager.getInstance().setAccentColor(hex);
      }
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    ColorModeManager.getInstance().updateFromConfiguration(newConfig);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(DOMAIN, TAG, 'onWindowStageCreate');
    windowStage.loadContent('pages/TvIndex', (err) => {
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

  onDestroy(): void {
    AppBootstrap.destroy();
    Logger.info(DOMAIN, TAG, 'onDestroy');
  }
}
