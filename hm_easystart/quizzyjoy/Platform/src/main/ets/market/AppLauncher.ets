import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'AppLauncher';

/** 应用市场详情页 URI 模板（AppGallery 官方深链）。 */
const MARKET_DETAIL_URI: string = 'https://appgallery.huawei.com/app/detail?id=';

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
 * 跨应用启动器（v3.50）：设置页「应用矩阵」的统一跳转入口。
 *
 * 回退链（逐级降级，不向 UI 抛异常）：
 * 1. `startAbility` 直接拉起目标应用（依次尝试 EntryAbility / MainAbility）；
 * 2. 拉起失败（多为 16000001 目标不存在 = 未安装）→ 打开应用市场详情页；
 * 3. 市场详情也失败 → 返回 `UNAVAILABLE`，由调用方弹「介绍弹窗」。
 *
 * 用 startAbility 而不是 bundleManager 查安装状态：查询其他应用信息需要
 * `ohos.permission.GET_BUNDLE_INFO_PRIVILEGED` 权限，而"能否拉起"本身就是
 * 普通应用可用的判据，且不引入额外权限声明。
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
    if (await AppLauncher.tryOpenMarketDetail(context, bundleName)) {
      return LaunchResult.NEED_INSTALL;
    }
    return LaunchResult.UNAVAILABLE;
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
        // 只有"目标不存在/无匹配"才继续降级；其它错误（如被管控）也不再重试
        if (code !== 16000001 && code !== 16000019 && code !== 16000002) {
          return false;
        }
      }
    }
    return false;
  }

  /** 打开应用市场详情页。 */
  private static async tryOpenMarketDetail(context: common.UIAbilityContext, bundleName: string): Promise<boolean> {
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: `${MARKET_DETAIL_URI}${bundleName}`,
      entities: ['entity.system.browsable']
    };
    try {
      await context.startAbility(want);
      return true;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `market detail failed: ${(err as BusinessError).code}`);
      return false;
    }
  }
}
