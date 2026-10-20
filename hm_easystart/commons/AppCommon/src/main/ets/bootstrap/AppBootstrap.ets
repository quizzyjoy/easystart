import { FontSizeScale, PreferenceKeys } from '@easystart/app-preferences';
import { Logger } from '@quizzyjoy/foundation';
import {
  AppColorMode,
  AppEnvManager,
  AppGalleryHelper,
  BreakpointManager,
  ColorModeManager,
  GlobalErrorHandler,
  HapticManager,
  HoverStore,
  I18nManager,
  MarketHelper,
  NetworkMonitor,
  OrientationManager,
  PreferencesStore,
  ScreenManager,
  SystemAppearanceManager,
  ShareHelper,
  UIContext,
  WindowAdapter,
  common,
  window
} from '@quizzyjoy/platform';

const DOMAIN: string = 'app';
const TAG: string = 'AppBootstrap';

/**
 * 应用装配引导（项目 Common 示范）。
 *
 * 职责：把「换一个 app 也能用」的共享三库按本项目决策组合起来——
 * 这正是"项目 Common"层的语义：胶水与项目决策，不复造轮子。
 *
 * 【零 @kit 纪律】本模块不直接 import '@kit.*'：
 * 系统类型（UIContext / window）经 @quizzyjoy/platform 再导出获取。
 *
 * 【分层边界】表现层装配（CommonToast.attach、强调色注入 UiThemeManager，
 * 属 VitalUI）**不在这里**——AppCommon 不依赖 VitalUI（保持手表可用）。
 * 本层只负责把持久化的强调色「读出来」（restoreAccentColor），由各入口
 * Ability（表现层）拿到色值后自行注入 UiThemeManager。
 *
 * 生命周期配对（与 Ability 回调一一对应）：
 * - onCreate          → prepare(context)
 * - loadContent 回调  → attachWindow(uiContext, mainWindow)
 * - onWindowStageDestroy → detachWindow()
 * - onDestroy         → destroy()
 */
export class AppBootstrap {
  /** PreferencesStore.init 的就绪承诺；读取偏好前先 await，避免 store 未就绪拿到默认值。 */
  private static storeReady: Promise<void> = Promise.resolve();

  /** 非表现层装配：全局兜底 → 主题 → 环境快照 → 存储 → 网络 → 分享。 */
  static prepare(context: common.UIAbilityContext): void {
    GlobalErrorHandler.install();
    ColorModeManager.getInstance().attach(context);
    SystemAppearanceManager.getInstance().attach(context);
    AppEnvManager.init(context);
    // 存储就绪后恢复用户偏好（显示模式 / 语言 / 触感总开关）；全新安装无记录时走 Manager 默认
    AppBootstrap.storeReady = PreferencesStore.init(context);
    AppBootstrap.storeReady.then(() => {
      AppBootstrap.restorePreferences();
    });
    NetworkMonitor.init();
    ShareHelper.getInstance().attach(context);
    MarketHelper.getInstance().attach(context);
    // 上架后能力（检查更新 / 评分 / 隐私 / 动态图标）：canIUse 探测在 helper 内部完成
    AppGalleryHelper.getInstance().attach(context);
    Logger.info(DOMAIN, TAG, 'prepare done');
  }

  /**
   * 启动恢复用户偏好（v3.13）：只读 PreferencesStore 并注入各 Manager，
   * Manager 自身不持偏好策略。缺省值：颜色跟随系统 / 语言不覆盖 / 触感开。
   */
  private static async restorePreferences(): Promise<void> {
    try {
      const colorMode: number =
        await PreferencesStore.getNumber(PreferenceKeys.DISPLAY_COLOR_MODE, AppColorMode.SYSTEM);
      ColorModeManager.getInstance().setMode(colorMode as AppColorMode);

      const language: string = await PreferencesStore.getString(PreferenceKeys.APP_LANGUAGE, '');
      if (language.length > 0) {
        I18nManager.setPreferredLanguage(language);
      }

      const hapticEnabled: boolean = await PreferencesStore.getBool(PreferenceKeys.HAPTIC_ENABLED, true);
      HapticManager.getInstance().setEnabled(hapticEnabled);

      const fontSizeIndex: number =
        await PreferencesStore.getNumber(PreferenceKeys.FONT_SIZE_INDEX, FontSizeScale.STANDARD_INDEX);
      AppBootstrap.restoreFontSize(fontSizeIndex);

      Logger.info(DOMAIN, TAG,
        `preferences restored: colorMode=${colorMode}, language='${language}', haptic=${hapticEnabled}, fontIndex=${fontSizeIndex}`);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `restorePreferences failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 冷启动恢复字号（v3.17 / TODO-007；v3.19 改绝对值语义）：
   * - 标准档：不调用 setFontSizeScale，由 configuration followSystem 自然跟随系统；
   * - 其他档：下发档位系数的「绝对值」（不叠乘系统字号，与 selectFontSize 同语义）。
   */
  private static restoreFontSize(index: number): void {
    const target: number = FontSizeScale.clamp(index);
    const manager: SystemAppearanceManager = SystemAppearanceManager.getInstance();
    if (target === FontSizeScale.STANDARD_INDEX) {
      Logger.info(DOMAIN, TAG, 'font size: standard (follow system), no override');
      return;
    }
    const applied: number = FontSizeScale.COEFFICIENTS[target];
    manager.setAppFontScale(applied);
    Logger.info(DOMAIN, TAG, `font size restored: index=${target}, applied=${applied}`);
  }

  /**
   * 读取持久化强调色（v3.15 修复：冷启动停在首页/画廊时 accent 不恢复的缺口）。
   *
   * 仅「读」不「注入」：UiThemeManager 属 VitalUI，AppCommon 不依赖 VitalUI
   * （手表要可用），故由 phone/pc/tv 入口 Ability 在 onCreate 拿到本结果后
   * 调 UiThemeManager.getInstance().setAccentColor(hex) 完成表现层注入
   * （与 CommonToast.attach 同属"表现层装配在 Ability"范式）。手表入口不调用。
   *
   * 读取顺序：现行键 accent_color → 空则回退 v2.1 预设枚举键 accent_preset
   * （预设枚举值本身即 hex，直通；'default' 等非 hex 值视为无记录）。
   *
   * @returns 合法 7 位小写 '#rrggbb'；无记录或非法时返回 ''（控件回退品牌默认色）。
   */
  static async restoreAccentColor(): Promise<string> {
    try {
      await AppBootstrap.storeReady;
      let saved: string = await PreferencesStore.getString(PreferenceKeys.ACCENT_COLOR, '');
      if (saved.length === 0) {
        saved = await PreferencesStore.getString(PreferenceKeys.ACCENT_COLOR_LEGACY, '');
      }
      const normalized: string = saved.trim().toLowerCase();
      if (PreferenceKeys.ACCENT_HEX_PATTERN.test(normalized)) {
        Logger.info(DOMAIN, TAG, `accent color restored: ${normalized}`);
        return normalized;
      }
      Logger.info(DOMAIN, TAG, 'accent color not set or invalid, fallback to brand default');
      return '';
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `restoreAccentColor failed: ${JSON.stringify(err)}`);
      return '';
    }
  }

  /**
   * 读取持久化的「主题包 + 强调色」（v3.43）。
   *
   * 仍遵循「本层只读、表现层装配在 Ability」：返回纯数据，由入口 Ability 调
   * `AppThemeApplier.apply(presetId, accentHex)` 完成 L3（UiThemeManager）+ L4（ThemeControl）落地。
   * 手表入口不调用（保持默认主题）。
   */
  static async restoreTheme(): Promise<AppThemeState> {
    const accent: string = await AppBootstrap.restoreAccentColor();
    let presetId: string = '';
    try {
      await AppBootstrap.storeReady;
      presetId = await PreferencesStore.getString(PreferenceKeys.THEME_PRESET, '');
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `restoreTheme preset failed: ${JSON.stringify(err)}`);
    }
    Logger.info(DOMAIN, TAG, `theme restored: preset=${presetId.length > 0 ? presetId : 'brand'} accent=${accent}`);
    return new AppThemeState(presetId, accent);
  }
  /** 窗口链路装配：断点 → 安全区（沉浸默认开）→ 方向 → 屏幕（loadContent 完成后调用）。 */
  static attachWindow(uiContext: UIContext, win: window.Window): void {
    BreakpointManager.getInstance().attach(uiContext, win);
    WindowAdapter.getInstance().attach(win);
    // v2.6：沉浸式默认开启——内容延伸至系统栏下（底色统一），
    // 页面侧用 WindowAdapter.topAvoidVp/bottomAvoidVp padding 避让；
    // 系统栏内容色由 ColorModeManager 联动推送。不支持的形态内部降级 no-op。
    WindowAdapter.getInstance().setImmersive(true);
    OrientationManager.getInstance().attach(win);
    ScreenManager.getInstance().attach(win);
    // 折叠态 / 折痕采集（v3.31 恢复编排）：HoverStore 自 v2.5「骨架→实采」后一直
    // 没有启动点，foldStatus / crease 恒为初始值——折叠屏上画廊演示页也会显示
    // 「非折叠设备降级」。此处只启动采集、不接业务；悬停态由组件 onHover 经
    // reportHover 回写，不占用折叠数据链路。
    HoverStore.getInstance().attach();
    // 屏幕方向偏好需窗口就绪后 reapply（v3.14 收口自 Demo 锁方向按钮；v3.16 修复「跟随系统」）：
    // 仅手机 / 平板有手持旋转语义（与设置 GeneralView 方向项可见形态一致），三态都显式下发——
    // 跟随系统(0) 也必须显式 unlock()（AUTO_ROTATION_UNSPECIFIED），否则用户从竖/横锁定改回
    // 「跟随系统」后冷启动会停在旧锁定方向；TV / 2in1 / 手表无手持旋转，一律不干预方向。
    const orientationDeviceType: string = AppEnvManager.get().deviceType;
    if (orientationDeviceType === 'phone' || orientationDeviceType === 'tablet') {
      PreferencesStore.getNumber(PreferenceKeys.SCREEN_ORIENTATION, 0).then((orientation: number): void => {
        if (orientation === 1) {
          OrientationManager.getInstance().lockPortrait();
          Logger.info(DOMAIN, TAG, 'screen-orientation restored: portrait');
        } else if (orientation === 2) {
          OrientationManager.getInstance().lockLandscape();
          Logger.info(DOMAIN, TAG, 'screen-orientation restored: landscape');
        } else {
          OrientationManager.getInstance().unlock();
          Logger.info(DOMAIN, TAG, 'screen-orientation restored: follow-system');
        }
      });
    }
    // 屏幕常亮偏好需窗口就绪后 reapply（缺省关）
    PreferencesStore.getBool(PreferenceKeys.KEEP_SCREEN_ON, false).then((on: boolean) => {
      if (on) {
        ScreenManager.getInstance().setKeepScreenOn(true);
        Logger.info(DOMAIN, TAG, 'keep-screen-on restored: true');
      }
    });
    Logger.info(DOMAIN, TAG, 'attachWindow done');
  }

  /** 窗口链路解绑（onWindowStageDestroy，与 attachWindow 成对）。 */
  static detachWindow(): void {
    BreakpointManager.getInstance().detach();
    WindowAdapter.getInstance().detach();
    OrientationManager.getInstance().detach();
    ScreenManager.getInstance().detach();
    HoverStore.getInstance().detach();
    Logger.info(DOMAIN, TAG, 'detachWindow done');
  }

  /** 收尾清理（onDestroy，与 prepare 成对）。 */
  static destroy(): void {
    NetworkMonitor.destroy();
    ShareHelper.getInstance().detach();
    MarketHelper.getInstance().detach();
    AppGalleryHelper.getInstance().detach();
    HoverStore.getInstance().destroy();
    ColorModeManager.getInstance().detach();
    SystemAppearanceManager.getInstance().detach();
    Logger.info(DOMAIN, TAG, 'destroy done');
  }
}

/** 持久化主题快照（v3.43）：交给入口 Ability 落地，避免 AppCommon 依赖 VitalUI。 */
export class AppThemeState {
  /** 主题包 id（'' = 默认品牌紫） */
  presetId: string = '';
  /** 强调色 '#RRGGBB'（'' = 用主题包基准色） */
  accentHex: string = '';

  constructor(presetId: string, accentHex: string) {
    this.presetId = presetId;
    this.accentHex = accentHex;
  }
}