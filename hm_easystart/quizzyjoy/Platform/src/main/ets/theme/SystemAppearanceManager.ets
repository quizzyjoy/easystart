import { uiAppearance } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'platform';
const TAG: string = 'SystemAppearanceManager';

/**
 * 系统外观（字体缩放）管理器（全局单例，V2，v3.17 / TODO-007）。
 *
 * 收口应用字体大小缩放的两类官方能力（API23 基线均已覆盖，零降级）：
 * 1. 读「系统」字体缩放：`uiAppearance.getFontScale()`（API20，@kit.ArkUI）——对应用户在
 *    系统设置 / 关怀模式里调的字体大小；失败回退 `context.config.fontSizeScale`，再回退 1。
 * 2. 写「应用」字体缩放：`ApplicationContext.setFontSizeScale(scale)`（API13，@kit.AbilityKit）——
 *    一处设置、全应用 fp 字号与布局自动缩放；设置后应用接管、不再跟随系统。
 *
 * 【跟随系统的声明前提】应用是否允许字体跟随系统，由 AppScope/resources/base/profile/
 * configuration.json 的 `fontSizeScale=followSystem` 控制（app.json5 挂 configuration 引用）；
 * 系统缺省为 nonFollowSystem。
 *
 * 【无运行时 reset】setFontSizeScale 调用后，运行期无法撤销回 followSystem（官方未提供 reset）。
 * 标准档做法：冷启动不调用本方法（让 followSystem 自然生效）；运行时从其他档切回标准，
 * 先 alignToSystem() 下发系统当前值即时回正，下次冷启动彻底恢复跟随。
 *
 * 【字重】应用侧无字重可写 API（WritableEnvKey 仅 DIRECTION / FONT_SCALE），跟随系统关怀模式时
 * 字重由系统自动加粗，本类不承载字重设置。
 */
@ObservedV2
export class SystemAppearanceManager {
  private static instance: SystemAppearanceManager | undefined = undefined;

  /** 最近一次读取的系统字体缩放（标准档基准）。 */
  @Trace systemFontScale: number = 1;
  /** 当前应用是否已被 setFontSizeScale 接管（true = 不再跟随系统）。 */
  @Trace appOverridden: boolean = false;

  private context: common.UIAbilityContext | undefined = undefined;

  private constructor() {
  }

  static getInstance(): SystemAppearanceManager {
    if (SystemAppearanceManager.instance === undefined) {
      SystemAppearanceManager.instance = new SystemAppearanceManager();
    }
    return SystemAppearanceManager.instance;
  }

  /** 初始化：UIAbility.onCreate / AppBootstrap.prepare 中调用。 */
  attach(context: common.UIAbilityContext): void {
    this.context = context;
    this.systemFontScale = this.readSystemFontScale(context);
  }

  detach(): void {
    this.context = undefined;
    this.appOverridden = false;
  }

  /**
   * 重置为初始状态（测试隔离 / 复用场景）。
   * 解绑并清空全部 @Trace 状态字段；生产生命周期（onDestroy）仍走 detach()。
   */
  reset(): void {
    this.detach();
    this.systemFontScale = 1;
  }

  /** 读取系统字体缩放（API20 uiAppearance；失败回退 config.fontSizeScale，再回退 1）。 */
  private readSystemFontScale(context: common.UIAbilityContext): number {
    try {
      const scale: number = uiAppearance.getFontScale();
      if (Number.isFinite(scale) && scale >= 0) {
        return scale;
      }
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getFontScale failed: ${JSON.stringify(err)}`);
    }
    const fromConfig: number = context.config?.fontSizeScale ?? 1;
    return Number.isFinite(fromConfig) && fromConfig >= 0 ? fromConfig : 1;
  }

  /** 刷新并返回系统当前字体缩放（设置页选档 / 冷启动恢复前调用）。 */
  getSystemScale(): number {
    if (this.context !== undefined) {
      this.systemFontScale = this.readSystemFontScale(this.context);
    }
    return this.systemFontScale;
  }

  /**
   * 设置应用字体缩放（全应用即时生效）。
   * @param scale 非负缩放倍数；内部经 ApplicationContext.setFontSizeScale 下发。
   */
  setAppFontScale(scale: number): void {
    if (this.context === undefined) {
      Logger.warn(DOMAIN, TAG, 'setAppFontScale before attach, ignored');
      return;
    }
    const safe: number = Number.isFinite(scale) && scale >= 0 ? scale : 1;
    try {
      this.context.getApplicationContext().setFontSizeScale(safe);
      this.appOverridden = true;
      Logger.info(DOMAIN, TAG, `app font scale set to ${safe}`);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `setFontSizeScale failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 运行时切回「标准 / 跟随系统」的视觉回正：下发系统当前值（即时回正）。
   * 真正的持续跟随在下次冷启动恢复（标准档不调用 setFontSizeScale）。
   */
  alignToSystem(): void {
    this.setAppFontScale(this.getSystemScale());
  }
}
