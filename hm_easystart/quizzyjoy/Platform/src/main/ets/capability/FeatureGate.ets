import { deviceInfo } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'FeatureGate';

/**
 * 门控结果状态。
 *
 * 三态而不是 boolean：调用方要能区分「版本不够」和「能力缺失」，
 * 因为两者给用户的处置不同（升级系统 vs 换能力）。
 */
export enum GateStatus {
  /** 达标可用 */
  AVAILABLE,
  /** 系统 API 版本低于条目要求 */
  API_TOO_LOW,
  /** 系统能力（syscap）缺失 */
  SYSCAP_MISSING
}

/**
 * 一个可门控条目（示例页 / 工具页 / 卡片入口）的能力要求。
 *
 * 约定：
 * - `minApi = 0` 表示不限制版本；
 * - `syscaps` 为空数组表示不检查系统能力；
 * - 两者都声明时**必须同时满足**（版本是下限，能力是硬门槛）。
 *
 * 为什么需要它（模板视角）：
 * 新 API 往往在旧系统上「编译通过、运行崩」。把门槛写成数据（而不是散落在 if 里），
 * 入口层就能统一决定「隐藏」还是「置灰」，fork 者不必每次手工核对。
 */
export class FeatureRequirement {
  readonly minApi: number;
  readonly syscaps: string[];

  constructor(minApi: number = 0, syscaps: string[] = []) {
    this.minApi = minApi;
    this.syscaps = syscaps;
  }

  /** 无要求（绝大多数条目用它）。 */
  static none(): FeatureRequirement {
    return new FeatureRequirement(0, []);
  }

  /** 只要求 API 版本。 */
  static api(minApi: number): FeatureRequirement {
    return new FeatureRequirement(minApi, []);
  }

  /** 只要求系统能力。 */
  static syscap(syscap: string): FeatureRequirement {
    return new FeatureRequirement(0, [syscap]);
  }

  /** 是否声明了任何要求。 */
  hasRequirement(): boolean {
    return this.minApi > 0 || this.syscaps.length > 0;
  }
}

/**
 * 门控判定结果。
 *
 * `reason` 是给用户看的一句话（如「需 API 26，当前 API 23」），
 * 视图直接把它渲成角标，不要在视图里再拼字符串——保证多端话术一致。
 */
export class GateResult {
  readonly status: GateStatus;
  readonly requiredApi: number;
  readonly currentApi: number;
  readonly missingSyscap: string;
  readonly reason: string;

  constructor(status: GateStatus, requiredApi: number, currentApi: number,
    missingSyscap: string = '', reason: string = '') {
    this.status = status;
    this.requiredApi = requiredApi;
    this.currentApi = currentApi;
    this.missingSyscap = missingSyscap;
    this.reason = reason;
  }

  /** 是否可进入/可点击。 */
  isAvailable(): boolean {
    return this.status === GateStatus.AVAILABLE;
  }
}

/**
 * 能力门控：把「入口是否可用」收敛到一处。
 *
 * 与 `CapabilityManager` 的分工：
 * - `CapabilityManager` 是**探测原语**（canIUse / isApiAtLeast / deviceType）；
 * - `FeatureGate` 是**策略层**（把条目要求翻译成用户可读的结论 + 角标文案）。
 *
 * 判定顺序固定为先版本、后能力：版本不足通常是根因，先报它更有指导意义。
 */
export class FeatureGate {
  /** 当前设备 API 版本（进程内常量，读取无开销）。 */
  static currentApi(): number {
    return deviceInfo.sdkApiVersion;
  }

  /** 判定一个要求是否达标。 */
  static check(req: FeatureRequirement): GateResult {
    const current: number = FeatureGate.currentApi();

    if (req.minApi > 0 && current < req.minApi) {
      return new GateResult(GateStatus.API_TOO_LOW, req.minApi, current, '',
        `需 API ${req.minApi}，当前 ${current}`);
    }

    for (let i = 0; i < req.syscaps.length; i++) {
      const syscap: string = req.syscaps[i];
      let ok: boolean = false;
      try {
        ok = canIUse(syscap);
      } catch (err) {
        Logger.warn(DOMAIN, TAG, `canIUse(${syscap}) failed: ${JSON.stringify(err)}`);
        ok = false;
      }
      if (!ok) {
        // 能力名较长，只取最后一段做角标（完整名进日志）
        const short: string = FeatureGate.shortSyscap(syscap);
        return new GateResult(GateStatus.SYSCAP_MISSING, req.minApi, current, syscap,
          `缺少能力 ${short}`);
      }
    }

    return new GateResult(GateStatus.AVAILABLE, req.minApi, current);
  }

  /** 便捷入口：直接给 minApi 与 syscaps。 */
  static checkInline(minApi: number, syscaps: string[] = []): GateResult {
    return FeatureGate.check(new FeatureRequirement(minApi, syscaps));
  }

  /** 'SystemCapability.UIDesign.HDSPattern.Standard' → 'HDSPattern'（角标用短名）。 */
  private static shortSyscap(syscap: string): string {
    const parts: string[] = syscap.split('.');
    if (parts.length >= 3) {
      return parts[parts.length - 2];
    }
    return syscap;
  }
}
