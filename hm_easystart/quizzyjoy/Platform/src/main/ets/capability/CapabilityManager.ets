import { deviceInfo } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'CapabilityManager';

/**
 * 能力检测。
 *
 * 三层检测，缺一不可：
 * 1. 系统能力（syscap）：canIUse('SystemCapability.xxx')
 * 2. API 版本：isApiAtLeast()
 * 3. 硬件 / 形态：deviceType
 *
 * 所有检测必须可失败降级，禁止直接抛出。
 */
export class CapabilityManager {
  /** 当前设备 SDK 的 API 版本 */
  static readonly SDK_API_VERSION: number = deviceInfo.sdkApiVersion;

  /** 系统能力检测，例如 'SystemCapability.UIDesign.HDSPattern.Standard' */
  static hasSysCap(syscap: string): boolean {
    try {
      return canIUse(syscap);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `canIUse(${syscap}) failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /** API 版本是否达到指定版本 */
  static isApiAtLeast(api: number): boolean {
    return CapabilityManager.SDK_API_VERSION >= api;
  }

  /** 当前设备形态：phone / tablet / 2in1 / tv / wearable / car ... */
  static getDeviceType(): string {
    return deviceInfo.deviceType;
  }

  static isPhone(): boolean {
    return deviceInfo.deviceType === 'phone';
  }

  static isTablet(): boolean {
    return deviceInfo.deviceType === 'tablet';
  }

  static is2in1(): boolean {
    return deviceInfo.deviceType === '2in1';
  }

  static isTv(): boolean {
    return deviceInfo.deviceType === 'tv';
  }

  static isWearable(): boolean {
    return deviceInfo.deviceType === 'wearable';
  }

  /** 是否属于"手机 / 平板 / 2in1 统一入口"覆盖的形态 */
  static isUnifiedHandsetFamily(): boolean {
    const t: string = deviceInfo.deviceType;
    return t === 'phone' || t === 'tablet' || t === '2in1';
  }
}