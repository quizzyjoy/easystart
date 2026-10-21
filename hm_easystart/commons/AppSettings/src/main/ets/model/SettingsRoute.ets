/**
 * 设置域路由名常量 + 收口判据（v3.28 装配收口，TODO-019）。
 *
 * 域包互禁（指南 §5.2）：AppSettings 不得依赖 @easystart/app-routes，故域内
 * 自持一套与 AppRoute 逐字同值的常量（同 AppBootstrap 顶部常量「两处同值」纪律）：
 * - 值与 commons/AppRoutes 的 AppRoute.* 保持逐字一致，同值同改（互禁无法共享，
 *   漂移由 isSettingsRoute 收口判据 + SettingsDestination 未知路由兜底空态拦住）；
 * - 域外（入口 / feature）push 一律引用 AppRoute.*，禁止再写字面量；
 * - 域内子页间跳转引用本类常量 + **设置域内层导航栈**（v3.32 双层栈改造：域内跳转压
 *   设置域内层 `NavPathStack`，不再压外层应用栈；跨域跳转仍 @Event 上抛）。
 */
export class SettingsRoute {
  /** 设置主页（值同 AppRoute.SETTINGS） */
  static readonly SETTINGS: string = 'settings';
  /** 主题外观子页（值同 AppRoute.APPEARANCE） */
  static readonly APPEARANCE: string = 'appearance';
  /** 通用设置子页（值同 AppRoute.GENERAL） */
  static readonly GENERAL: string = 'general';
  /** 关于本应用子页（值同 AppRoute.ABOUT） */
  static readonly ABOUT: string = 'about';
  /** 政策文本子页（值同 AppRoute.POLICY；param: 'privacy' | 'terms' | 'sdk'） */
  static readonly POLICY: string = 'policy';
  /** 开源许可子页（值同 AppRoute.LICENSE） */
  static readonly LICENSE: string = 'license';
  /** 公告子页（v3.28 数据驱动；值同 AppRoute.ANNOUNCEMENT） */
  static readonly ANNOUNCEMENT: string = 'announcement';
  /** 帮助与反馈子页（v3.28 数据驱动；值同 AppRoute.HELP_FEEDBACK） */
  static readonly HELP_FEEDBACK: string = 'helpFeedback';
  /** 版本更新日志子页（v3.28 数据驱动；值同 AppRoute.VERSION_LOG） */
  static readonly VERSION_LOG: string = 'versionLog';
  /** 开发者团队子页（v3.28 数据驱动；值同 AppRoute.DEVELOPER） */
  static readonly DEVELOPER: string = 'developer';
  /** 第三方 SDK 清单子页（v3.28 PolicyView kind 扩展；值同 AppRoute.SDK_LIST） */
  static readonly SDK_LIST: string = 'sdkList';
  /** 应用矩阵子页（v3.50；趣开发系列应用聚合） */
  static readonly APPS: string = 'apps';
}

/**
 * 判断路由名是否属于设置域目的地。
 *
 * 入口 pageMap 以本函数收口：命中即整体交给 SettingsDestination 统一装配
 * （视图 + titleBar + 沉浸避让），入口不再逐路由手写分支。
 */
export function isSettingsRoute(name: string): boolean {
  return name === SettingsRoute.SETTINGS
    || name === SettingsRoute.APPEARANCE
    || name === SettingsRoute.GENERAL
    || name === SettingsRoute.ABOUT
    || name === SettingsRoute.POLICY
    || name === SettingsRoute.LICENSE
    || name === SettingsRoute.ANNOUNCEMENT
    || name === SettingsRoute.HELP_FEEDBACK
    || name === SettingsRoute.VERSION_LOG
    || name === SettingsRoute.DEVELOPER
    || name === SettingsRoute.SDK_LIST
    || name === SettingsRoute.APPS;
}
