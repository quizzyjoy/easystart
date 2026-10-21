import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';
import { AppEnvManager } from '../device/AppEnvManager';

const DOMAIN: string = 'platform';
const TAG: string = 'MarketHelper';

/** 华为应用市场·应用详情页 URI 前缀（评分 / 检查更新同入口）。 */
const STORE_DETAIL_PREFIX: string = 'store://appgallery.huawei.com/app/detail?id=';

/**
 * 应用市场跳转封装（v3.13，TODO-003 设置页「检查更新 / 给我们评分」配套）。
 *
 * 外部 Want 拉起属跨应用通用系统能力，落 Platform（F14）；无市场 / 未安装 AppGallery /
 * 设备不支持时 startWant reject，统一返回 false 由 UI 层 SnackBar 降级，不抛异常。
 *
 * 生命周期：attach / detach 成对（AppBootstrap.prepare / destroy 编排）。
 */
export class MarketHelper {
  private static instance: MarketHelper | undefined = undefined;

  private context: common.UIAbilityContext | undefined = undefined;

  private constructor() {
  }

  static getInstance(): MarketHelper {
    if (MarketHelper.instance === undefined) {
      MarketHelper.instance = new MarketHelper();
    }
    return MarketHelper.instance;
  }

  /** 注入上下文（UIAbility.onCreate 中调用，与 detach 成对）。 */
  attach(context: common.UIAbilityContext): void {
    this.context = context;
    Logger.info(DOMAIN, TAG, 'attached');
  }

  /** 解绑（onDestroy 中调用，与 attach 成对）。 */
  detach(): void {
    this.context = undefined;
    Logger.info(DOMAIN, TAG, 'detached');
  }

  /**
   * 拉起应用市场中本应用（或指定 bundleName 应用）的详情页。
   * @param bundleName 目标应用包名；省略时取本应用 bundleName（AppEnvManager 快照）
   * @returns 是否成功拉起（失败已内部降级记 WARN）
   */
  async openAppDetail(bundleName?: string): Promise<boolean> {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined) {
      Logger.warn(DOMAIN, TAG, 'not attached: call attach in AppBootstrap.prepare first');
      return false;
    }
    const target: string = (bundleName !== undefined && bundleName.length > 0)
      ? bundleName
      : AppEnvManager.get().bundleName;
    if (target.length === 0) {
      Logger.warn(DOMAIN, TAG, 'openAppDetail aborted: bundleName empty');
      return false;
    }
    const want: Want = { uri: STORE_DETAIL_PREFIX + target };
    try {
      await context.startAbility(want);
      Logger.info(DOMAIN, TAG, `appgallery detail opened: ${target}`);
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `openAppDetail failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'startAbility').toLog()}`);
      return false;
    }
  }

  /**
   * 打开任意 URI（http / https 等）——交给系统浏览器或已注册的处理方。
   *
   * 与 openAppDetail 同属「外部 Want 拉起」系统能力，统一落 Platform（F14）；
   * 失败（无处理方 / 未安装浏览器）返回 false，由 UI 层降级提示，不抛异常。
   *
   * @param uri 目标 URI（如 GitHub 仓库地址）
   * @returns 是否成功拉起
   */
  async openUri(uri: string): Promise<boolean> {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined) {
      Logger.warn(DOMAIN, TAG, 'openUri ignored: call attach in AppBootstrap.prepare first');
      return false;
    }
    if (uri.length === 0) {
      Logger.warn(DOMAIN, TAG, 'openUri aborted: empty uri');
      return false;
    }
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri
    };
    try {
      await context.startAbility(want);
      Logger.info(DOMAIN, TAG, `uri opened: ${uri}`);
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `openUri failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'startAbility').toLog()}`);
      return false;
    }
  }

  /**
   * 用**浏览器**打开链接（v3.81）。
   *
   * 为什么不用 `openUri`：`appgallery.huawei.com` 这类域名会被应用市场 App 接管，
   * 隐式 Want 会把用户送到市场首页而不是目标页（实测：邀测链接点开落到市场「探索」页）。
   * 内测邀测页只能在浏览器里登录华为账号后操作，因此这里显式指定浏览器。
   *
   * 策略：显式华为浏览器 → 系统任意浏览器（隐式）→ 全失败返回 false 由 UI 降级复制链接。
   *
   * @param uri 目标 URI
   * @returns 是否成功拉起浏览器
   */
  async openInBrowser(uri: string): Promise<boolean> {
    const context: common.UIAbilityContext | undefined = this.context;
    if (context === undefined || uri.length === 0) {
      Logger.warn(DOMAIN, TAG, 'openInBrowser ignored: no context or empty uri');
      return false;
    }
    // ① 显式华为浏览器：绕开"AppGallery 域名被市场接管"
    const explicit: Want = {
      bundleName: 'com.huawei.hmos.browser',
      abilityName: 'MainAbility',
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: uri
    };
    try {
      await context.startAbility(explicit);
      Logger.info(DOMAIN, TAG, `browser opened explicitly: ${uri}`);
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `explicit browser failed: ${ErrorMapper.fromBusiness(e, DOMAIN, 'startAbility').toLog()}`);
    }
    // ② 隐式 browsable（系统默认浏览器）
    const implicit: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: uri
    };
    try {
      await context.startAbility(implicit);
      Logger.info(DOMAIN, TAG, `browser opened implicitly: ${uri}`);
      return true;
    } catch (err2) {
      const e2: BusinessError = err2 as BusinessError;
      Logger.warn(DOMAIN, TAG, `implicit browser failed: ${ErrorMapper.fromBusiness(e2, DOMAIN, 'startAbility').toLog()}`);
      return false;
    }
  }
}
