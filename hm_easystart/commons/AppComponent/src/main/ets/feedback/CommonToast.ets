import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'appcomponent';
const TAG: string = 'CommonToast';

/**
 * CommonToast —— 统一轻提示。
 *
 * 为什么封装：promptAction 的 message / duration 散落各处会不一致，
 * 这里收敛为语义化方法并统一时长。
 *
 * 【零 @kit 纪律】不直接触碰系统 API：Toast 实现由入口 Ability 注入，
 * 在 windowStage.loadContent 回调里调用：
 *      CommonToast.attach((message, duration) => {
 *        uiContext.getPromptAction().showToast({ message: message, duration: duration });
 *      });
 * 未 attach 时仅记 WARN 日志（不回退全局 promptAction 弃用 API）。
 *
 * 注意：showToast **不支持按钮**。需要「带按钮的确认/撤销」请用
 * CommonDialog（promptAction.openCustomDialog）或 bindSheet，不要用本类。
 */
export class CommonToast {
  /** Toast 时长规范（ms）——应用级默认：常规 2s。 */
  private static readonly DURATION_DEFAULT: number = 2000;
  /** 警示语义时长（ms）：2.5s。 */
  private static readonly DURATION_WARN: number = 2500;
  /** 错误语义时长（ms）：3s。 */
  private static readonly DURATION_ERROR: number = 3000;
  private static shower: ((message: ResourceStr, duration: number) => void) | undefined = undefined;

  /** 注入 Toast 实现（建议窗口加载完成后调用一次，与 detach 成对）。 */
  static attach(shower: (message: ResourceStr, duration: number) => void): void {
    CommonToast.shower = shower;
  }

  /** 解绑（与 attach 成对）。 */
  static detach(): void {
    CommonToast.shower = undefined;
  }

  static show(message: ResourceStr, duration: number = CommonToast.DURATION_DEFAULT): void {
    const shower = CommonToast.shower;
    if (shower === undefined) {
      Logger.warn(DOMAIN, TAG, 'not attached: call CommonToast.attach in loadContent first');
      return;
    }
    try {
      shower(message, duration);
    } catch (err) {
      // 轻提示失败不应影响业务流程
    }
  }

  static success(message: ResourceStr): void {
    CommonToast.show(message);
  }

  static info(message: ResourceStr): void {
    CommonToast.show(message);
  }

  static warn(message: ResourceStr): void {
    CommonToast.show(message, CommonToast.DURATION_WARN);
  }

  static error(message: ResourceStr): void {
    CommonToast.show(message, CommonToast.DURATION_ERROR);
  }
}
