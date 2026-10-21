import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'SelfSignature';

/**
 * 当前安装包的签名自述（v3.59）。
 *
 * 用途：应用市场的能力（隐私托管 / 签署记录 / 更新 / 评分）都以
 * **bundleName + 签名证书指纹** 为键与 AGC 上的登记匹配。调试证书与发布证书
 * 指纹不同时，这些接口会静默返回空或报"未使用隐私管理服务"（1006700003）。
 *
 * 把本机指纹摆到界面上，就能直接和 AGC「应用信息 → 签名证书指纹(SHA-256)」比对，
 * 不用再让用户跑 hdc dump。
 */
export class SelfSignature {
  /** 是否调试签名（`appProvisionType === 'debug'`）。 */
  readonly debugSignature: boolean;
  /** 分发类型（`none` = 非应用市场分发 / `app_gallery` 等）。 */
  readonly distributionType: string;
  /** 签名证书指纹（SHA-256，系统给出的十六进制字符串；取不到为空串）。 */
  readonly fingerprint: string;
  /** 应用标识（与 AGC appId 对应）。 */
  readonly appIdentifier: string;

  constructor(debugSignature: boolean, distributionType: string, fingerprint: string, appIdentifier: string) {
    this.debugSignature = debugSignature;
    this.distributionType = distributionType;
    this.fingerprint = fingerprint;
    this.appIdentifier = appIdentifier;
  }

  /** 指纹转成 `AA:BB:…` 形式，便于与 AGC 控制台逐段比对。 */
  get fingerprintColon(): string {
    const raw: string = this.fingerprint.replace(/:/g, '').toUpperCase();
    if (raw.length === 0) {
      return '';
    }
    const parts: string[] = [];
    for (let i: number = 0; i + 1 < raw.length; i += 2) {
      parts.push(raw.substring(i, i + 2));
    }
    return parts.join(':');
  }
}

/** 读取当前安装包的签名信息（失败时返回"未知"快照，不抛异常）。 */
export class SelfSignatureReader {
  static read(): SelfSignature {
    try {
      const flags: number = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
        | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO;
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(flags);
      const provisionType: string = info.appInfo.appProvisionType;
      const distribution: string = info.appInfo.appDistributionType;
      const fingerprint: string = info.signatureInfo !== undefined ? info.signatureInfo.fingerprint : '';
      const appId: string = info.signatureInfo !== undefined ? info.signatureInfo.appIdentifier : '';
      return new SelfSignature(provisionType === 'debug', distribution, fingerprint, appId);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `read self signature failed: ${e.code} ${e.message}`);
      return new SelfSignature(false, 'unknown', '', '');
    }
  }
}
