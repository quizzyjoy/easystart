/**
 * 尺寸刻度（vp）：点按热区、图标与触摸目标。
 *
 * v3.0（2026-09-30）重构：
 * - 图标档位对齐官方骨干 16/24（navigation/textfield/toolbar icon=24，
 *   search/piece/subheader=16），补间 12/20/32/40；
 * - 触摸目标三档：MIN 40（HarmonyOS UX 标准「点击热区不得小于 40vp×40vp」，
 *   原 WCAG 24 底线 v3.5 上调）、
 *   STANDARD 48（M3 标准 / 官方列表行体系）、COMFORT 56（TV 遥控 / 手表手指）；
 * - 原 HIT_SM/HIT_MD/HIT_LG 收敛进 TOUCH_*（零消费，无迁移成本）。
 */
export class AppSize {
  /** 图标：极小（内联提示） */
  static readonly ICON_XS: number = 12;
  /** 图标：小（搜索清除 / 片段 / 副标题左图标，官方 16） */
  static readonly ICON_SM: number = 16;
  /** 图标：中（列表辅助，官方补间 20） */
  static readonly ICON_MD: number = 20;
  /** 图标：标准（导航 / 输入框 / 工具栏，官方 24） */
  static readonly ICON_LG: number = 24;
  /** 图标：大（空态插画 / 大按钮内） */
  static readonly ICON_XL: number = 32;
  /** 图标：特大（功能入口 / 卡片主图标） */
  static readonly ICON_XXL: number = 40;

  /**
   * 应用展示位档（v3.30，TODO-021）：官方图标骨干止于 24，以下为家族应用
   * 展示位惯例档（EasyMath / EasyRandom 设置页实证同值），登记后纳入刻度。
   */
  /** 展示位：设置行彩底图标贴片（家族惯例 36） */
  static readonly ICON_CHIP: number = 36;
  /** 展示位：头像 / 第三方登录图标（48） */
  static readonly AVATAR_SM: number = 48;
  /** 展示位：设置页应用头图标（64） */
  static readonly AVATAR_MD: number = 64;
  /** 展示位：关于页应用头图标（72） */
  static readonly AVATAR_LG: number = 72;

  /** 触摸目标：底线（40×40，HarmonyOS UX 体验标准：点击热区不得小于 40vp×40vp） */
  static readonly TOUCH_MIN: number = 40;
  /** 触摸目标：标准（48×48，列表行 / 设置项 / 常规按钮；官方列表行体系） */
  static readonly TOUCH_STANDARD: number = 48;
  /** 触摸目标：舒适（56×56，TV 遥控焦点 / 手表手指） */
  static readonly TOUCH_COMFORT: number = 56;
}
