import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import type { common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'PermissionHelper';

/**
 * 权限申请封装。
 *
 * 约定：
 * 1. 申请前先 isGranted()，避免重复弹窗；
 * 2. 拒绝后给出可解释的降级路径（不要静默失败）；
 * 3. 权限字符串集中定义，禁止业务里写裸字符串。
 */
export class PermissionHelper {
  /** 常用权限常量。 */
  static readonly PERMISSION_CAMERA: Permissions = 'ohos.permission.CAMERA';
  static readonly PERMISSION_MICROPHONE: Permissions = 'ohos.permission.MICROPHONE';
  static readonly PERMISSION_LOCATION: Permissions = 'ohos.permission.APPROXIMATELY_LOCATION';
  static readonly PERMISSION_INTERNET: Permissions = 'ohos.permission.INTERNET';

  /** 是否已授权。 */
  static async isGranted(context: common.UIAbilityContext, permission: Permissions): Promise<boolean> {
    try {
      const tokenId: number = await PermissionHelper.tokenId();
      const manager = abilityAccessCtrl.createAtManager();
      const status = await manager.checkAccessToken(tokenId, permission);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      Logger.error(DOMAIN, TAG, `isGranted failed: ${ErrorMapper.from(err, DOMAIN, 'isGranted').toLog()}`);
      return false;
    }
  }

  /** 批量申请；返回被拒绝的权限列表（空代表全部通过）。 */
  static async request(context: common.UIAbilityContext, permissions: Permissions[]): Promise<Permissions[]> {
    try {
      const manager = abilityAccessCtrl.createAtManager();
      const result = await manager.requestPermissionsFromUser(context, permissions);
      const denied: Permissions[] = [];
      result.authResults.forEach((code: number, index: number) => {
        if (code !== 0) {
          denied.push(permissions[index]);
        }
      });
      return denied;
    } catch (err) {
      Logger.error(DOMAIN, TAG, `request failed: ${ErrorMapper.from(err, DOMAIN, 'request').toLog()}`);
      return permissions;
    }
  }

  private static async tokenId(): Promise<number> {
    const info = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    return info.appInfo.accessTokenId;
  }
}
