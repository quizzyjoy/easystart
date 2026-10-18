import {
  AppColorMode,
  CacheManager,
  ColorModeManager,
  HapticManager,
  I18nManager,
  OrientationManager,
  PreferencesStore,
  ScreenManager,
  SystemAppearanceManager,
  common
} from '@quizzyjoy/platform';
import { FontSizeScale } from '@easystart/app-preferences';
import { SettingKeys } from '../model/SettingKeys';
import { SettingDisplayMode, SettingLanguage, SettingOrientation } from '../model/SettingOption';

/**
 * 设置页视图模型（v3.13，TODO-003）。
 *
 * 收口全部偏好读写与缓存状态：Section 只做状态绑定与事件转发。
 * - 读：aboutToAppear 调 load()；缓存大小单独 loadCacheSize()（文件 IO，懒加载）；
 * - 写：即改即存（PreferencesStore 异步 put），同时调用对应 Manager 即时生效；
 * - Manager 不持偏好策略，默认值与持久化只在本 VM 与 AppBootstrap 恢复链两处。
 *
 * V2：@ObservedV2 + @Trace，全局单例（getInstance），跨设置子页共享同一份状态。
 */
@ObservedV2
export class SettingsViewModel {
  private static instance: SettingsViewModel | undefined = undefined;

  /**
   * 全局单例（TODO-021 收口修复）：v3.30 schema 化后 SettingsView 与各设置子页
   * 各自 new 一份实例，跨子页状态不互通——在外观子页切深色后返回主页，
   * 「主题外观」行后缀仍停留进页时的「跟随系统」（冷启动才随 load 纠正）。
   * 收敛为单例后与 v3.28「单个实例」设计一致，亦与 SchemaRowStore /
   * Platform 各 Manager 的单例惯例同构。
   */
  static getInstance(): SettingsViewModel {
    if (SettingsViewModel.instance === undefined) {
      SettingsViewModel.instance = new SettingsViewModel();
    }
    return SettingsViewModel.instance;
  }

  /** 显示模式（AppColorMode：SYSTEM/LIGHT/DARK）。 */
  @Trace displayMode: AppColorMode = AppColorMode.SYSTEM;
  /** 应用语言（'' 跟随系统 / zh-Hans / en-US）。 */
  @Trace language: string = SettingLanguage.FOLLOW_SYSTEM;
  /** 触感反馈总开关。 */
  @Trace hapticEnabled: boolean = true;
  /** 屏幕常亮开关。 */
  @Trace keepScreenOn: boolean = false;
  /** 屏幕方向（SettingOrientation：0 跟随 / 1 竖屏 / 2 横屏）。 */
  @Trace screenOrientation: number = SettingOrientation.AUTO;
  /** 应用内字号档位（0~4，标准档 2，见 FontSizeScale）。 */
  @Trace fontSizeIndex: number = FontSizeScale.STANDARD_INDEX;
  /** 缓存字节数；-1 表示尚未统计 / 计算中。 */
  @Trace cacheSizeBytes: number = -1;

  /** 启动读偏好（设置页 aboutToAppear 调用）。 */
  async load(): Promise<void> {
    // 先等 store 就绪：深链冷启动直达子页时 aboutToAppear 可能早于 init 完成，
    // 否则 getNumber/getString 会直接返回默认值（落盘偏好不生效）。
    await PreferencesStore.ready();
    this.displayMode =
      await PreferencesStore.getNumber(SettingKeys.DISPLAY_COLOR_MODE, AppColorMode.SYSTEM) as AppColorMode;
    this.language = await PreferencesStore.getString(SettingKeys.APP_LANGUAGE, SettingLanguage.FOLLOW_SYSTEM);
    this.hapticEnabled = await PreferencesStore.getBool(SettingKeys.HAPTIC_ENABLED, true);
    this.keepScreenOn = await PreferencesStore.getBool(SettingKeys.KEEP_SCREEN_ON, false);
    this.screenOrientation =
      await PreferencesStore.getNumber(SettingKeys.SCREEN_ORIENTATION, SettingOrientation.AUTO);
    const savedFontSize: number =
      await PreferencesStore.getNumber(SettingKeys.FONT_SIZE_INDEX, FontSizeScale.STANDARD_INDEX);
    this.fontSizeIndex = FontSizeScale.clamp(savedFontSize);
  }

  /** 显示模式 Select 选中索引。 */
  displayModeIndex(): number {
    const idx: number = SettingDisplayMode.VALUES.indexOf(this.displayMode);
    return idx >= 0 ? idx : 0;
  }

  /** 语言 Select 选中索引。 */
  languageIndex(): number {
    const idx: number = SettingLanguage.VALUES.indexOf(this.language);
    return idx >= 0 ? idx : 0;
  }

  /** 切换显示模式：即时生效 + 持久化。 */
  selectDisplayMode(index: number): void {
    const mode: AppColorMode = SettingDisplayMode.VALUES[index];
    this.displayMode = mode;
    PreferencesStore.put(SettingKeys.DISPLAY_COLOR_MODE, mode as number);
    ColorModeManager.getInstance().setMode(mode);
  }

  /**
   * 切换应用语言：即时生效 + 持久化。
   * @returns true 表示选择了「跟随系统」，官方约定清除偏好（'default'）后需重启才生效，
   *          UI 层应提示用户重启；具体语言官方称界面即时切换。
   */
  selectLanguage(index: number): boolean {
    const lang: string = SettingLanguage.VALUES[index];
    this.language = lang;
    PreferencesStore.put(SettingKeys.APP_LANGUAGE, lang);
    const systemValue: string = lang === SettingLanguage.FOLLOW_SYSTEM
      ? I18nManager.LANGUAGE_FOLLOW_SYSTEM
      : lang;
    I18nManager.setPreferredLanguage(systemValue);
    return lang === SettingLanguage.FOLLOW_SYSTEM;
  }

  /** 触感总开关：关闭后三档震动静默；重新开启时给一次轻反馈确认。 */
  toggleHaptic(enabled: boolean): void {
    this.hapticEnabled = enabled;
    HapticManager.getInstance().setEnabled(enabled);
    PreferencesStore.put(SettingKeys.HAPTIC_ENABLED, enabled);
    if (enabled) {
      HapticManager.getInstance().light();
    }
  }

  /** 屏幕常亮（需窗口已 attach，设置页打开时必然满足）。 */
  toggleKeepScreenOn(enabled: boolean): void {
    this.keepScreenOn = enabled;
    ScreenManager.getInstance().setKeepScreenOn(enabled);
    PreferencesStore.put(SettingKeys.KEEP_SCREEN_ON, enabled);
  }

  /** 屏幕方向 Select 选中索引（值顺序与 SettingOrientation.VALUES 一致）。 */
  orientationIndex(): number {
    const idx: number = SettingOrientation.VALUES.indexOf(this.screenOrientation);
    return idx >= 0 ? idx : 0;
  }

  /**
   * 切换屏幕方向（v3.14 收口自 DemoFeature 锁方向按钮；需窗口已 attach）：
   * 跟随系统=unlock()，下发 AUTO_ROTATION_UNSPECIFIED（随系统自动旋转设置、受控制中心
   * 旋转锁约束；v3.16 前误用 UNSPECIFIED 致选「跟随系统」仍不旋转）；竖/横屏走 lockPortrait /
   * lockLandscape。场景级 push/pop 策略栈留给业务页面，设置页只表达用户全局偏好。
   */
  selectOrientation(index: number): void {
    const orientation: number = SettingOrientation.VALUES[index];
    this.screenOrientation = orientation;
    const manager: OrientationManager = OrientationManager.getInstance();
    if (orientation === SettingOrientation.PORTRAIT) {
      manager.lockPortrait();
    } else if (orientation === SettingOrientation.LANDSCAPE) {
      manager.lockLandscape();
    } else {
      manager.unlock();
    }
    PreferencesStore.put(SettingKeys.SCREEN_ORIENTATION, orientation);
  }

  /**
   * 切换应用字号（即时生效 + 持久化，v3.17 / TODO-007；v3.19 改绝对值语义）：
   * - 标准档：alignToSystem() 下发系统当前值即时回正；冷启动不接管、由 configuration followSystem 持续跟随；
   * - 其他档：下发档位系数的「绝对值」（不叠乘系统字号，对齐官方 setFontSizeScale 绝对覆盖语义——
   *   选「大」即 1.25 倍，不再因系统关怀字号二次放大；覆盖系统关怀是 setFontSizeScale 固有行为，
   *   主动选非标准档即主动覆盖）。
   */
  selectFontSize(index: number): void {
    const target: number = FontSizeScale.clamp(index);
    this.fontSizeIndex = target;
    PreferencesStore.put(SettingKeys.FONT_SIZE_INDEX, target);
    const manager: SystemAppearanceManager = SystemAppearanceManager.getInstance();
    if (target === FontSizeScale.STANDARD_INDEX) {
      manager.alignToSystem();
      return;
    }
    manager.setAppFontScale(FontSizeScale.COEFFICIENTS[target]);
  }

  /** 统计缓存大小（进通用组时调用）。 */
  async loadCacheSize(context: common.Context): Promise<void> {
    this.cacheSizeBytes = -1;
    this.cacheSizeBytes = await CacheManager.getCacheSizeBytes(context);
  }

  /** 清空缓存后刷新大小。 */
  async clearCache(context: common.Context): Promise<void> {
    await CacheManager.clearCache(context);
    await this.loadCacheSize(context);
  }

  /** 字节数格式化为 B / KB / MB / GB（一位小数）。 */
  static formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    }
    const kb: number = bytes / 1024;
    if (kb < 1024) {
      return `${kb.toFixed(1)} KB`;
    }
    const mb: number = kb / 1024;
    if (mb < 1024) {
      return `${mb.toFixed(1)} MB`;
    }
    return `${(mb / 1024).toFixed(2)} GB`;
  }
}
