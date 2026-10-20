/**
 * 应用级偏好持久化契约（零依赖常量注册表，@easystart/app-preferences）。
 *
 * 背景（v3.18 / TODO-008）：偏好键 / 字号系数 / 强调色校验此前分散在
 * AppCommon(AppBootstrap) 与 AppSettings(SettingKeys / SettingFontSize /
 * AccentColorSetting) 两处，因应用级域包互禁依赖（指南 §5.2）无法共享常量，
 * 只能靠注释「两处同改」纪律约束，历史上已出现强调色键名不一致导致的
 * 冷启动不恢复缺陷（v3.15）。现将持久化契约下沉为本零依赖包，
 * AppCommon 与 AppSettings 均依赖它，键名 / 系数 / 校验单一真相源。
 *
 * 落位判据（指南 §12.3 四档 / §3.1 按域分模块）：这是「应用级命名契约」，
 * 与 AppRoutes（路由名注册表）同类，故独立建包；不进三库（三库是组织级资产，
 * 偏好键带本应用语义）、不进 AppCommon（编排）/AppSettings（设置 UI）。
 *
 * 零依赖零 @kit：纯字符串 + 纯数值 + RegExp，保证 AppCommon（手表可用）与
 * AppSettings 均可安全依赖。
 */

/** 设置项持久化键名（新键统一 settings. 前缀，避免与业务 feature 键相撞）。 */
export class PreferenceKeys {
  /** 显示模式：number，值对齐 Platform AppColorMode（0 浅色 / 1 深色 / 2 跟随系统）。 */
  static readonly DISPLAY_COLOR_MODE: string = 'settings.display_color_mode';
  /** 应用语言：string，'' 跟随系统 / 'zh-Hans' / 'en-US'。 */
  static readonly APP_LANGUAGE: string = 'settings.app_language';
  /** 触感反馈总开关：boolean，默认 true。 */
  static readonly HAPTIC_ENABLED: string = 'settings.haptic_enabled';
  /** 屏幕常亮：boolean，默认 false。 */
  static readonly KEEP_SCREEN_ON: string = 'settings.keep_screen_on';
  /** 屏幕方向：number，0 跟随系统（自动旋转）/ 1 锁定竖屏 / 2 锁定横屏，默认 0。 */
  static readonly SCREEN_ORIENTATION: string = 'settings.screen_orientation';
  /** 应用内字号档位：number，0~4（见 FontSizeScale），标准档 index=2，默认 2。 */
  static readonly FONT_SIZE_INDEX: string = 'settings.font_size_index';

  /** 强调色（v2.2 起任意 #RRGGBB；v2.1 历史键不加前缀、不迁移）。 */
  static readonly ACCENT_COLOR: string = 'accent_color';
  /** 主题包 id（v3.43；空 = 默认主题包 brand） */
  static readonly THEME_PRESET: string = 'theme_preset';
  /** v2.1 预设枚举历史键（accent_color 为空时回退读取，值本身即 hex）。 */
  static readonly ACCENT_COLOR_LEGACY: string = 'accent_preset';
  /** 收藏色（逗号分隔 hex）。 */
  static readonly FAVORITE_COLORS: string = 'favorite_colors';

  /** 合法强调色：7 位小写 '#rrggbb'（与 UiThemeManager.setAccentColor 入参契约一致）。 */
  static readonly ACCENT_HEX_PATTERN: RegExp = /^#[0-9a-f]{6}$/;
  /** 收藏色上限。 */
  static readonly FAVORITE_MAX: number = 6;
}

/**
 * 应用内字号档位缩放（5 档，标准居中 index=2）。
 *
 * COEFFICIENTS 为各档的「绝对」缩放系数（小 / 较小 / 标准 / 较大 / 大），v3.19 起语义为绝对值——
 * 非标准档直接下发本系数（不叠乘系统字号），对齐官方 setFontSizeScale 的「绝对覆盖」语义；
 * 标准档（1.0）不接管、由 configuration followSystem 跟随系统。
 * 系数真机标定，本表为初值。
 */
export class FontSizeScale {
  /** 标准档索引（跟随系统）。 */
  static readonly STANDARD_INDEX: number = 2;
  /** 各档「绝对」缩放系数（小 / 较小 / 标准 / 较大 / 大）。 */
  static readonly COEFFICIENTS: number[] = [0.85, 0.93, 1.0, 1.12, 1.25];
  /** 档位总数。 */
  static readonly COUNT: number = FontSizeScale.COEFFICIENTS.length;

  /** clamp 档位到 [0, COUNT-1]；非法值（NaN/Infinity/越界）回标准档或最近边界。 */
  static clamp(index: number): number {
    if (!Number.isFinite(index)) {
      return FontSizeScale.STANDARD_INDEX;
    }
    const rounded: number = Math.round(index);
    if (rounded < 0) {
      return 0;
    }
    if (rounded > FontSizeScale.COUNT - 1) {
      return FontSizeScale.COUNT - 1;
    }
    return rounded;
  }
}
