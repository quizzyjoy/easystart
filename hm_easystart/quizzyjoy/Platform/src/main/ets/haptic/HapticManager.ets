import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'HapticManager';

/**
 * 触觉反馈（V2 单例）：语义化三档震动。
 *
 * 档位映射（SDK d.ts VibratorPreset 预设）：
 * light  → haptic.effect.soft；medium → haptic.effect.hard；heavy → haptic.effect.sharp。
 *
 * 【降级纪律】震动是体验增强：任何失败（无振动器 / 权限 / 效果不支持）
 * 只记 WARN 不抛异常、不影响业务流程。
 * 需要在入口 module.json5 声明 ohos.permission.VIBRATE（system_grant，无需 reason）。
 * 无监听、无窗口绑定，故不设 attach/detach 生命周期。
 *
 * 【总开关】enabled 默认 true；设置页「触感反馈」关闭后三档全部静默。
 * Manager 只持门控状态、不读写偏好——默认值与持久化由应用装配层（AppBootstrap）
 * 读 PreferencesStore 后经 setEnabled 注入，保持三库无偏好策略。
 */
export class HapticManager {
  private static instance: HapticManager | undefined = undefined;

  private static readonly EFFECT_LIGHT: string = 'haptic.effect.soft';
  private static readonly EFFECT_MEDIUM: string = 'haptic.effect.hard';
  private static readonly EFFECT_HEAVY: string = 'haptic.effect.sharp';

  private enabled: boolean = true;

  private constructor() {
  }

  static getInstance(): HapticManager {
    if (HapticManager.instance === undefined) {
      HapticManager.instance = new HapticManager();
    }
    return HapticManager.instance;
  }

  /** 设置触感总开关（false 后 light/medium/heavy 全部静默）。 */
  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
    Logger.info(DOMAIN, TAG, `haptic enabled=${enabled}`);
  }

  /** 当前触感总开关状态。 */
  isEnabled(): boolean {
    return this.enabled;
  }

  /** 轻反馈：列表选中、开关切换。 */
  light(): void {
    this.vibrate(HapticManager.EFFECT_LIGHT, 'light');
  }

  /** 中反馈：按钮确认、操作完成。 */
  medium(): void {
    this.vibrate(HapticManager.EFFECT_MEDIUM, 'medium');
  }

  /** 重反馈：删除确认、到达关键节点。 */
  heavy(): void {
    this.vibrate(HapticManager.EFFECT_HEAVY, 'heavy');
  }

  private vibrate(effectId: string, level: string): void {
    if (!this.enabled) {
      // 触感总开关关闭：静默短路，不触发系统调用
      return;
    }
    const effect: vibrator.VibratePreset = { type: 'preset', effectId: effectId, count: 1 };
    const attribute: vibrator.VibrateAttribute = { usage: 'touch' };
    vibrator.startVibration(effect, attribute).then(() => {
      Logger.info(DOMAIN, TAG, `haptic.${level} triggered`);
    }).catch((err: BusinessError) => {
      // 无振动器 / 效果不支持 / 权限缺失：降级为 WARN，不打断业务
      Logger.warn(DOMAIN, TAG, `haptic.${level} failed: ${ErrorMapper.fromBusiness(err, DOMAIN, 'vibrate').toLog()}`);
    });
  }
}
