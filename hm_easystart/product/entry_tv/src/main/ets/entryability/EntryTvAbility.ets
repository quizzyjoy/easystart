import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Logger } from '@quizzyjoy/foundation';
import { ColorModeManager } from '@quizzyjoy/platform';
import { AppBootstrap, AppThemeState } from '@easystart/app-common';
import { AppThemeApplier, CommonToast } from '@easystart/app-component';

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
    // 表现层装配：启动恢复「主题包 + 强调色」，一次铺满 L3（组件）+ L4（系统组件默认色）
    // AppCommon 只读不注入（手表要可用），落地在 Ability（与 CommonToast.attach 同范式）
    AppBootstrap.restoreTheme().then((state: AppThemeState): void => {
      AppThemeApplier.apply(state.presetId, state.accentHex);
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
