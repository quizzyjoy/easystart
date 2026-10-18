import { deviceInfo } from '@kit.BasicServicesKit';
import { bundleManager, common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'AppEnvManager';

/** 应用与运行环境快照 */
export class AppEnvSnapshot {
  bundleName: string = '';
  versionName: string = '';
  versionCode: number = 0;
  /** API 版本 */
  sdkApiVersion: number = 0;
  deviceType: string = '';
  /** 产品型号，如 HUAWEI Mate 80 */
  productModel: string = '';
  osFullName: string = '';

  toString(): string {
    return `AppEnv(bundle=${this.bundleName}, ver=${this.versionName}, api=${this.sdkApiVersion},`
      + ` device=${this.deviceType}, model=${this.productModel})`;
  }
}

/**
 * API 与设备信息管理。
 *
 * 唯一允许直接读取系统环境信息的地方；业务层不得自行调用 deviceInfo / bundleManager。
 */
export class AppEnvManager {
  private static snapshot: AppEnvSnapshot | undefined = undefined;

  /** 采集一次环境快照并缓存 */
  static async init(context: common.UIAbilityContext): Promise<AppEnvSnapshot> {
    const snap = new AppEnvSnapshot();
    snap.sdkApiVersion = deviceInfo.sdkApiVersion;
    snap.deviceType = deviceInfo.deviceType;
    snap.productModel = deviceInfo.productModel;
    snap.osFullName = deviceInfo.osFullName;
    try {
      const info: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      snap.bundleName = info.name;
      snap.versionName = info.versionName;
      snap.versionCode = info.versionCode;
    } catch (err) {
      Logger.error(DOMAIN, TAG, `getBundleInfoForSelf failed: ${JSON.stringify(err)}`);
    }
    AppEnvManager.snapshot = snap;
    Logger.info(DOMAIN, TAG, snap.toString());
    return snap;
  }

  /** 获取缓存快照；未初始化时返回一份可用的兜底值 */
  static get(): AppEnvSnapshot {
    if (AppEnvManager.snapshot === undefined) {
      const snap = new AppEnvSnapshot();
      snap.sdkApiVersion = deviceInfo.sdkApiVersion;
      snap.deviceType = deviceInfo.deviceType;
      snap.productModel = deviceInfo.productModel;
      snap.osFullName = deviceInfo.osFullName;
      AppEnvManager.snapshot = snap;
    }
    return AppEnvManager.snapshot;
  }
}