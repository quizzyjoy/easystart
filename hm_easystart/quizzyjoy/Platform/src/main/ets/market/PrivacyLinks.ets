import { StorePrivacyKind } from './AppGalleryHelper';

/**
 * 应用市场「隐私托管」协议地址（v3.52）。
 *
 * 应用在 AGC 上配置隐私政策 / 用户协议后，华为会托管一份可公网访问的协议页。
 * 这些地址由 AGC 分配（agreementId 与具体应用绑定），不能通配。
 *
 * 三层取址顺序（调用方 `AppGalleryHelper.getPrivacyLink` 实现）：
 * 1. `privacyManager.getAppPrivacyMgmtInfo()` 返回的官方链接（需设备装了应用市场、
 *    应用已上架且接入隐私托管服务）；
 * 2. **本文件的常量**（真实托管地址，未上架 / 未接入服务时的兜底，保证点开有内容）；
 * 3. 本地 rawfile 离线副本（无网络 / 无法拉起浏览器时由页面回退）。
 *
 * 维护约定：AGC 后台改了协议版本，托管地址可能变化——改这里一处即可全端生效。
 */
export class PrivacyLinks {
  /**
   * 托管协议地址（真实地址，2026-10-21 由产品侧提供）。
   *
   * 形如 `.../index.html?lang=zh&agreementId=<id>`：
   * - `lang=zh` 中文；如需英文版可替换为 `lang=en`；
   * - `agreementId` 与协议正文绑定，不能跨应用复用。
   */
  private static readonly HOSTED_URL: string =
    'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=2065909374747958976';

  /** 托管页的英文版（同 agreementId，仅语言参数不同）。 */
  private static readonly HOSTED_URL_EN: string =
    'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=en&agreementId=2065909374747958976';

  /**
   * 取某一类协议的托管地址（常量兜底）。
   *
   * 说明：当前 AGC 上只托管了一份「隐私政策/用户协议」文档，隐私声明与用户协议
   * 指向同一地址；后续二者拆分为两个 agreementId 时，在下方分别填写即可。
   */
  static hostedUrl(kind: StorePrivacyKind): string {
    if (kind === StorePrivacyKind.STATEMENT || kind === StorePrivacyKind.USER_AGREEMENT) {
      return PrivacyLinks.HOSTED_URL;
    }
    return PrivacyLinks.HOSTED_URL;
  }

  /** 英文环境下的托管地址（用于页面展示「在线版」入口）。 */
  static hostedUrlEn(): string {
    return PrivacyLinks.HOSTED_URL_EN;
  }
}
