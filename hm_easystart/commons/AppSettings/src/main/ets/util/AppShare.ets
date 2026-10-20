import { AppEnvManager, ShareHelper, UIContext } from '@quizzyjoy/platform';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'settings';
const TAG: string = 'AppShare';

/**
 * 应用分享文案（v3.39）：设置根页 titleBar 分享按钮与 schema `shareApp` 动作共用一处，
 * 避免「标题栏一个实现、设置行一个实现」的文案漂移。
 */
export class AppShare {
  /** 拉起系统分享面板（应用名 + 版本）；取不到应用名时退化为固定名。 */
  static share(uiContext: UIContext): void {
    let appName: string = '';
    const host = uiContext.getHostContext();
    if (host !== undefined) {
      try {
        appName = host.resourceManager.getStringSync($r('app.string.app_name').id);
      } catch (err) {
        appName = '';
      }
    }
    if (appName.length === 0) {
      appName = 'EasyStart';
    }
    const env = AppEnvManager.get();
    try {
      ShareHelper.getInstance().shareText(`${appName} v${env.versionName}`, {
        title: appName
      });
      Logger.info(DOMAIN, TAG, 'share panel requested');
    } catch (err) {
      Logger.warn(DOMAIN, TAG, 'share failed: ShareHelper not attached or panel unavailable');
    }
  }
}
