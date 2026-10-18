import { deviceInfo } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'CompatManager';

/**
 * 兼容性处理。
 *
 * 原则：能力先探测、再调用；不同 API 版本走不同分支；禁止用 try/catch 掩盖版本差异。
 * 所有降级分支必须打日志，便于线上定位。
 */
export class CompatManager {
  private static readonly SDK_API_VERSION: number = deviceInfo.sdkApiVersion;

  /** 当前运行环境 API 版本 */
  static apiVersion(): number {
    return CompatManager.SDK_API_VERSION;
  }

  /**
   * 按 API 版本执行不同分支。
   * @param requiredApi 需要的最低 API 版本
   * @param onSupported 满足时执行
   * @param fallback 不满足时的降级实现（可选）
   */
  static runByApi(requiredApi: number, onSupported: () => void, fallback?: () => void): void {
    if (CompatManager.SDK_API_VERSION >= requiredApi) {
      onSupported();
      return;
    }
    Logger.warn(DOMAIN, TAG, `api ${requiredApi} not reachable on ${CompatManager.SDK_API_VERSION}, fallback used`);
    if (fallback !== undefined) {
      fallback();
    }
  }

  /** 在调用可能不存在的新接口前做保护，异常时返回兜底值 */
  static safeCall<T>(tag: string, action: () => T, fallback: T): T {
    try {
      return action();
    } catch (err) {
      Logger.error(DOMAIN, TAG, `${tag} failed, use fallback: ${JSON.stringify(err)}`);
      return fallback;
    }
  }
}