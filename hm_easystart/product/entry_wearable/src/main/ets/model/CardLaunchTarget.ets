/**
 * 卡片点击深链载荷（入口装配层轻量静态持有，v3.27）。
 *
 * 【为什么用静态持有而非 AppStorage】Ability.onCreate 早于页面 build
 * （此时 NavPathStack 尚未 attach），深链目标必须「先寄存、后消费」。
 *
 * 【两条消费路径（缺一不可）】
 * 1. **冷启动**：Ability.onCreate 寄存 → 页面首次 onPageShow 取走；
 * 2. **应用已在前台/后台**：Ability.onNewWant 只更新 want，页面**不会**重新触发
 *    onPageShow → 若仅寄存会永远不消费（v3.27 实测踩坑）。故页面在 aboutToAppear
 *    注册消费者，set() 时**主动回调**通知页面立即处理。
 */
export class CardLaunchTarget {
  private static target: string = '';
  private static consumer: (() => void) | undefined = undefined;

  /** 页面注册消费者（aboutToAppear；aboutToDisappear 需 clearConsumer 防悬挂）。 */
  static setConsumer(onTarget: () => void): void {
    CardLaunchTarget.consumer = onTarget;
  }

  /** 页面注销消费者（aboutToDisappear）。 */
  static clearConsumer(): void {
    CardLaunchTarget.consumer = undefined;
  }

  /** 卡片 / 外部拉起时写入并立即通知页面（Ability.onCreate / onNewWant）。 */
  static set(target: string): void {
    CardLaunchTarget.target = target;
    const notify: (() => void) | undefined = CardLaunchTarget.consumer;
    if (notify !== undefined) {
      notify();
    }
  }

  /** 取走并清空（返回 '' 表示无待处理目标）。 */
  static take(): string {
    const value: string = CardLaunchTarget.target;
    CardLaunchTarget.target = '';
    return value;
  }
}
