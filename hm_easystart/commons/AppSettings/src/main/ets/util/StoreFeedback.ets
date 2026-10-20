import { MarketHelper, StoreCapabilityResult } from '@quizzyjoy/platform';
import { CommonToast } from '@easystart/app-component';

/**
 * 上架后能力的**用户可见反馈**（v3.39）：更新 / 评分的失败分档文案与市场兜底动作。
 *
 * 设置页行动作与「关于本应用」子页按钮共用本类，避免同一错误码在两处给不同说法。
 * 纪律：错误码不出现给用户；能解释的给一句人话，不能解释的统一退到应用市场详情页。
 */
export class StoreFeedback {
  /** 更新类结果的提示文案；'' 表示不需要提示。 */
  static updateMessage(result: StoreCapabilityResult): ResourceStr {
    if (result === StoreCapabilityResult.UP_TO_DATE) {
      return $r('app.string.settings_update_none');
    }
    if (result === StoreCapabilityResult.NOT_FOREGROUND) {
      return $r('app.string.settings_update_not_foreground');
    }
    if (result === StoreCapabilityResult.PRIVACY_NOT_AGREED) {
      return $r('app.string.settings_update_privacy');
    }
    if (result === StoreCapabilityResult.NETWORK) {
      return $r('app.string.settings_update_network');
    }
    if (result === StoreCapabilityResult.THROTTLED) {
      return $r('app.string.settings_update_throttled');
    }
    return '';
  }

  /** 评分类结果的提示文案；'' 表示不需要提示（成功时不打扰）。 */
  static rateMessage(result: StoreCapabilityResult): ResourceStr {
    if (result === StoreCapabilityResult.NOT_SIGNED_IN) {
      return $r('app.string.settings_rate_not_signed_in');
    }
    if (result === StoreCapabilityResult.ALREADY_DONE) {
      return $r('app.string.settings_rate_already');
    }
    return '';
  }

  /** 兜底：打开应用市场详情页；连详情页都打不开时提示「无应用市场」。 */
  static openMarket(message: ResourceStr): void {
    MarketHelper.getInstance().openAppDetail().then((ok: boolean): void => {
      if (ok) {
        if (`${message}`.length > 0) {
          CommonToast.info(message);
        }
      } else {
        CommonToast.info($r('app.string.settings_market_unavailable'));
      }
    });
  }
}
