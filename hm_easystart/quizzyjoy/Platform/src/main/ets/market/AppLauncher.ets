import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'AppLauncher';

/** 华为应用市场包名（判断市场是否可用的探针目标）。 */
const MARKET_BUNDLE: string = 'com.huawei.appmarket';

/** 应用市场自家 scheme 深链（需在 module.json5 的 querySchemes 声明 appmarket）。 */
const MARKET_SCHEME_PREFIX: string = 'appmarket://details?id=';

/** 应用市场 Web 详情页（scheme 拉不起来时的兜底，querySchemes 需含 https）。 */
const MARKET_WEB_PREFIX: string = 'https://appgallery.huawei.com/app/detail?id=';

/** 常见入口 Ability 名（模板默认 EntryAbility，部分老工程用 MainAbility）。 */
const CANDIDATE_ABILITIES: string[] = ['EntryAbility', 'MainAbility'];

/**
 * 跨应用跳转的语义化结果（UI 只消费本枚举，错误码不出 Platform）。
 */
export enum LaunchResult {
  /** 目标应用已安装并成功拉起。 */
  OPENED,
  /** 目标应用未安装：已尝试拉起应用市场详情页并成功。 */
  NEED_INSTALL,
  /** 目标未安装且市场详情也拉不起来（无市场 / 无网络 / 未上架）。 */
  UNAVAILABLE
}

/**
 * 跨应用启动器（v3.50 / v3.51）：设置页「应用矩阵」的统一跳转入口。
 *
 * 回退链（逐级降级，不向 UI 抛异常）：
 * 1. `startAbility` 直接拉起目标应用（依次尝试 EntryAbility / MainAbility）；
 * 2. 拉起失败（16000001 / 16000019 / 16000002 = 未安装）→ **先判断市场是否存在**：
 *    `bundleManager.canOpenLink('appmarket://…')` 为 true 才去开市场详情，否则直接进第 3 步；
 * 3. 市场不存在或详情页也失败 → 返回 `UNAVAILABLE`，由调用方弹「介绍弹窗」。
 *
 * 【为什么用 startAbility 判安装态】查询其他应用信息需要
 * `ohos.permission.GET_BUNDLE_INFO_PRIVILEGED`；"能否拉起"本身是普通应用可用的判据。
 *
 * 【为什么用 canOpenLink 判市场】这是系统提供的"某链接是否有应用可响应"的官方接口
 * （API 12+，`@ohos.bundle.bundleManager`），必须先在 module.json5 的 `querySchemes`
 * 声明 scheme，否则抛 17700056；链接格式非法抛 17700055。它不依赖特权权限。
 */
export class AppLauncher {
  /**
   * 打开目标应用，失败时按回退链降级。
   *
   * @param context UIAbilityContext（页面侧 getUIContext().getHostContext()）
   * @param bundleName 目标应用包名
   */
  static async open(context: common.UIAbilityContext, bundleName: string): Promise<LaunchResult> {
    if (await AppLauncher.tryStartApp(context, bundleName)) {
      return LaunchResult.OPENED;
    }
    if (!AppLauncher.isMarketAvailable()) {
      Logger.warn(DOMAIN, TAG, 'market not available, skip to fallback dialog');
      return LaunchResult.UNAVAILABLE;
    }
    if (await AppLauncher.tryOpenMarketDetail(context, bundleName)) {
      return LaunchResult.NEED_INSTALL;
    }
    return LaunchResult.UNAVAILABLE;
  }

  /**
   * 应用市场是否可用（能否响应 `appmarket://` 深链）。
   *
   * 依赖 `module.json5` 的 `querySchemes` 声明 `appmarket`；未声明或系统不支持时
   * 一律返回 false（按"市场不可用"处理，直接走介绍弹窗）。
   */
  static isMarketAvailable(): boolean {
    try {
      return bundleManager.canOpenLink(`${MARKET_SCHEME_PREFIX}${MARKET_BUNDLE}`);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `canOpenLink failed: ${(err as BusinessError).code}`);
      return false;
    }
  }

  /** 依次尝试候选 Ability 名拉起目标应用。 */
  private static async tryStartApp(context: common.UIAbilityContext, bundleName: string): Promise<boolean> {
    for (const abilityName of CANDIDATE_ABILITIES) {
      const want: Want = {
        bundleName: bundleName,
        abilityName: abilityName
      };
      try {
        await context.startAbility(want);
        return true;
      } catch (err) {
        const code: number = (err as BusinessError).code;
        Logger.warn(DOMAIN, TAG, `start ${bundleName}/${abilityName} failed: ${code}`);
        // 只有"目标不存在/无匹配/类型不符"才继续降级；其它错误（如被管控）也不再重试
        if (code !== 16000001 && code !== 16000019 && code !== 16000002) {
          return false;
        }
      }
    }
    return false;
  }

  /** 打开应用市场详情页：先试 appmarket:// 深链，再退 https 详情页。 */
  private static async tryOpenMarketDetail(context: common.UIAbilityContext, bundleName: string): Promise<boolean> {
    const uris: string[] = [`${MARKET_SCHEME_PREFIX}${bundleName}`, `${MARKET_WEB_PREFIX}${bundleName}`];
    for (const uri of uris) {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: uri,
        entities: ['entity.system.browsable']
      };
      try {
        await context.startAbility(want);
        return true;
      } catch (err) {
        Logger.warn(DOMAIN, TAG, `market detail ${uri} failed: ${(err as BusinessError).code}`);
      }
    }
    return false;
  }
}
