import { Configuration, ConfigurationConstant, common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';
import { WindowAdapter } from '../window/WindowAdapter';

const DOMAIN: string = 'platform';
const TAG: string = 'ColorModeManager';

/** 应用侧颜色模式语义 */
export enum AppColorMode {
  LIGHT = 0,
  DARK = 1,
  /** 跟随系统 */
  SYSTEM = 2
}

/**
 * 颜色模式管理器（全局单例，V2）。
 *
 * 设计要点：
 * 1. 同步入口是 UIAbility.onConfigurationUpdate -> updateFromConfiguration()，
 *    本类不注册全局环境回调，避免 HAR 反向依赖 Ability 生命周期。
 * 2. 具体颜色值不使用函数返回，而是放在应用级颜色令牌里
 *    （AppScope/resources/base/element/color.json 与 .../dark/element/color.json），
 *    由系统按当前模式自动选择同名资源；本类只负责"模式"这一层。
 */
@ObservedV2
export class ColorModeManager {
  private static instance: ColorModeManager | undefined = undefined;

  /** 当前应用设置的模式 */
  @Trace appMode: AppColorMode = AppColorMode.SYSTEM;
  /** 当前系统实际生效的深浅色 */
  @Trace systemIsDark: boolean = false;

  private context: common.UIAbilityContext | undefined = undefined;

  private constructor() {
  }

  static getInstance(): ColorModeManager {
    if (ColorModeManager.instance === undefined) {
      ColorModeManager.instance = new ColorModeManager();
    }
    return ColorModeManager.instance;
  }

  /** 初始化，应在 UIAbility.onCreate 中调用 */
  attach(context: common.UIAbilityContext): void {
    this.context = context;
    this.syncFromConfig(context.config);
  }

  detach(): void {
    this.context = undefined;
  }

  /** 供 UIAbility.onConfigurationUpdate 调用，同步系统深浅色 */
  updateFromConfiguration(config: Configuration): void {
    this.syncFromConfig(config);
  }

  /** 设置颜色模式 */
  setMode(mode: AppColorMode): void {
    if (this.context === undefined) {
      Logger.warn(DOMAIN, TAG, 'setMode before attach, ignored');
      return;
    }
    this.appMode = mode;
    let target: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (mode === AppColorMode.LIGHT) {
      target = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (mode === AppColorMode.DARK) {
      target = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    try {
      this.context.getApplicationContext().setColorMode(target);
      WindowAdapter.getInstance().applySystemBarAppearance(this.isDarkNow());
      Logger.info(DOMAIN, TAG, `color mode set to ${mode}`);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `setColorMode failed: ${JSON.stringify(err)}`);
    }
  }

  /** 在浅色 / 深色间切换（跟随系统模式下以系统当前值为基准取反） */
  toggle(): void {
    const currentDark: boolean =
      this.appMode === AppColorMode.SYSTEM ? this.systemIsDark : this.appMode === AppColorMode.DARK;
    this.setMode(currentDark ? AppColorMode.LIGHT : AppColorMode.DARK);
  }

  private syncFromConfig(config: Configuration): void {
    this.systemIsDark = config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    WindowAdapter.getInstance().applySystemBarAppearance(this.isDarkNow());
    Logger.info(DOMAIN, TAG, `system color mode synced, dark=${this.systemIsDark}`);
  }

  /** 当前实际生效的深浅色（应用模式优先，跟随系统时取系统值）。
   * v3.0 起公开：Canvas 图表等无法消费 $r 自动切换的场景，
   * 由调用方读取本值注入（见图表组件 @Param isDark）。 */
  isDarkNow(): boolean {
    if (this.appMode === AppColorMode.DARK) {
      return true;
    }
    if (this.appMode === AppColorMode.LIGHT) {
      return false;
    }
    return this.systemIsDark;
  }
}