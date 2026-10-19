/**
 * 应用级路由名注册表。
 *
 * 消除「同一路由名在多入口重复定义」的漂移风险（v3.3 前例：entry 与 entry_pc
 * 各自 const ROUTE_DETAIL）。入口 pageMap 注册与 push 调用一律引用本类常量，
 * 禁止入口/feature 内再定义路由名字面量（快速启动 §9 纪律）。
 */
export class AppRoute {
  /** 首页列表项详情页（pageMap 注册名） */
  static readonly HOME_DETAIL: string = 'homeDetail';
  /** 样例子页：令牌总览（v3.9，pageMap 注册名） */
  static readonly DEMO_TOKENS: string = 'demoTokens';
  /** 样例子页：反馈流（v3.9，pageMap 注册名） */
  static readonly DEMO_FEEDBACK: string = 'demoFeedback';
  /** 样例子页：数据看板（v3.9，pageMap 注册名） */
  static readonly DEMO_CHARTS: string = 'demoCharts';
  /** 样例子页：表单范式（v3.9，pageMap 注册名） */
  static readonly DEMO_FORM: string = 'demoForm';
  /** 样例子页：列表四态（v3.9，pageMap 注册名） */
  static readonly DEMO_LIST: string = 'demoListStates';
  /** 样例子页：搜索场景（v3.10，pageMap 注册名） */
  static readonly DEMO_SEARCH: string = 'demoSearch';
  /** 样例子页：悬停态分屏（v3.31 / FOLD-01，pageMap 注册名） */
  static readonly DEMO_FOLD_HOVER: string = 'demoFoldHover';
  /** 设置页（v3.12，独立子页；入口为首页 titleBar 齿轮，pageMap 注册名） */
  /** 示例·组件示例分组页（v3.37，pageMap 注册名；param = basic/visual/platform/app） */
  static readonly GALLERY_GROUP: string = 'GALLERY_GROUP';

  /** 示例·模板能力目录页（v3.37，pageMap 注册名） */
  static readonly HOME_CATALOG: string = 'HOME_CATALOG';

  /** 示例·关于模板（v3.38 三级架构 L3：这是什么 / 怎么用 / 如何 fork） */
  static readonly TEMPLATE_ABOUT: string = 'templateAbout';

  /** 学习·教学章节详情（v3.38，pageMap 注册名；param = 章节 id） */
  static readonly LEARN_CHAPTER: string = 'learnChapter';

  /** 开发工具·设备能力检测（v3.37，pageMap 注册名） */
  static readonly DEVICE_CAPABILITY: string = 'DEVICE_CAPABILITY';

  static readonly SETTINGS: string = 'settings';
  /** 设置·主题外观子页（v3.14：显示模式 + 强调色，pageMap 注册名） */
  static readonly APPEARANCE: string = 'appearance';
  /** 设置·通用设置子页（v3.14：语言 / 触感 / 常亮 / 屏幕方向 / 清缓存，pageMap 注册名） */
  static readonly GENERAL: string = 'general';
  /** 设置·关于本应用子页（v3.13，pageMap 注册名） */
  static readonly ABOUT: string = 'about';
  /** 设置·政策文本子页（v3.13，param: 'privacy' | 'terms' | 'sdk'，pageMap 注册名） */
  static readonly POLICY: string = 'policy';
  /** 设置·开源许可子页（v3.13，pageMap 注册名） */
  static readonly LICENSE: string = 'license';
  /** 设置·账号子页（v3.28 UI 占位，pageMap 注册名；值与 SettingsRoute.ACCOUNT 逐字同值） */
  static readonly ACCOUNT: string = 'account';
  /** 设置·公告子页（v3.28 数据驱动，pageMap 注册名；值与 SettingsRoute.ANNOUNCEMENT 逐字同值） */
  static readonly ANNOUNCEMENT: string = 'announcement';
  /** 设置·帮助与反馈子页（v3.28 数据驱动，pageMap 注册名；值与 SettingsRoute.HELP_FEEDBACK 逐字同值） */
  static readonly HELP_FEEDBACK: string = 'helpFeedback';
  /** 设置·版本更新日志子页（v3.28 数据驱动，pageMap 注册名；值与 SettingsRoute.VERSION_LOG 逐字同值） */
  static readonly VERSION_LOG: string = 'versionLog';
  /** 设置·开发者团队子页（v3.28 数据驱动，pageMap 注册名；值与 SettingsRoute.DEVELOPER 逐字同值） */
  static readonly DEVELOPER: string = 'developer';
  /** 设置·第三方 SDK 清单子页（v3.28，pageMap 注册名；值与 SettingsRoute.SDK_LIST 逐字同值） */
  static readonly SDK_LIST: string = 'sdkList';
}
