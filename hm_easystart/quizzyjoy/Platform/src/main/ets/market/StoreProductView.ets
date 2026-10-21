import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { productViewManager } from '@kit.AppGalleryKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'StoreProductView';

/** 详情页展示超时：超过该时长仍未 onAppear/onError 视为失败（走下一级回退）。 */
const APPEAR_TIMEOUT_MS: number = 4000;

/**
 * 应用详情页（应用内半模态，v3.54）。
 *
 * 与「跳应用市场」不同：`productViewManager.loadProduct` 由应用市场在**当前应用内**
 * 拉起一个详情面板，用户可当场下载安装，不用离开当前应用——这是应用矩阵里
 * 「未安装 → 去下载」最顺的路径。
 *
 * Want 的**入参位置很反直觉**：目标包名放在 `want.parameters.bundleName`，
 * 不是 `want.bundleName`（`want.bundleName` 是"由谁响应"，这里是交给应用市场处理）。
 *
 * 能力约束：`SystemCapability.AppGalleryService.Distribution.Recommendations`，
 * 需要设备安装应用市场；能力缺失 / 未登录 / 参数错误都会走 `onError` 或同步抛异常，
 * 调用方据此降级到「跳市场 → 介绍弹窗」。
 */
export class StoreProductView {
  /**
   * 在应用内展示目标应用详情页。
   *
   * @param context UIAbilityContext
   * @param bundleName 目标应用包名（放在 parameters 里传给应用市场）
   * @returns true = 详情页已展示；false = 能力不可用/被拒绝，调用方降级
   */
  static loadProductDetail(context: common.UIAbilityContext, bundleName: string): Promise<boolean> {
    return new Promise<boolean>((resolve: (value: boolean) => void) => {
      let settled: boolean = false;
      const finish = (ok: boolean): void => {
        if (settled) {
          return;
        }
        settled = true;
        resolve(ok);
      };
      // 超时兜底：面板没出现也没报错时不要一直挂着
      const timer: number = setTimeout((): void => {
        Logger.warn(DOMAIN, TAG, `loadProduct timeout for ${bundleName}`);
        finish(false);
      }, APPEAR_TIMEOUT_MS);

      const want: Want = {
        parameters: {
          bundleName: bundleName
        }
      };
      try {
        productViewManager.loadProduct(context, want, {
          onAppear: (): void => {
            clearTimeout(timer);
            finish(true);
          },
          onError: (err: BusinessError): void => {
            clearTimeout(timer);
            Logger.warn(DOMAIN, TAG, `loadProduct onError ${err.code}: ${err.message}`);
            finish(false);
          }
        });
      } catch (err) {
        clearTimeout(timer);
        const e: BusinessError = err as BusinessError;
        Logger.warn(DOMAIN, TAG, `loadProduct threw ${e.code}: ${e.message}`);
        finish(false);
      }
    });
  }

  /** 当前设备是否具备详情页能力（能力开关 + 应用市场已安装的粗判据）。 */
  static usable(): boolean {
    try {
      return canIUse('SystemCapability.AppGalleryService.Distribution.Recommendations');
    } catch (err) {
      return false;
    }
  }
}
