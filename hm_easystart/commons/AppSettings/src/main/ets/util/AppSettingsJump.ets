import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'app-settings';
const TAG: string = 'AppSettingsJump';

/**
 * 系统设置跳转封装（v3.28，TODO-019）。
 *
 * want 实证参照 EasyTools PermissionRequester.openAppSettings（只读参考，
 * 不引入依赖）：bundleName 'com.huawei.hmos.settings' + MainAbility +
 * uri 'application_info_entry' + pushParams 传本应用包名，直达本应用的
 * 系统侧详情页（通知 / 权限等系统级配置）。
 *
 * 「机制」收口本文件，跳转后的系统页面形态由系统托管；fork 后包名
 * 变化经 context.abilityInfo.bundleName 自动跟随，零改动。
 */
export class AppSettingsJump {
  /**
   * 跳转本应用的系统设置详情页。
   * 失败仅记录日志不中断业务（系统设置缺失属环境异常，非应用缺陷）。
   */
  static jumpToAppSystemSettings(context: common.UIAbilityContext): void {
    const want: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        pushParams: context.abilityInfo.bundleName
      }
    };
    context.startAbility(want).then((): void => {
      Logger.info(DOMAIN, TAG, 'jumped to system app settings');
    }).catch((err: BusinessError) => {
      Logger.warn(DOMAIN, TAG, `jump failed (system settings unavailable?): code=${err.code}`);
    });
  }
}
