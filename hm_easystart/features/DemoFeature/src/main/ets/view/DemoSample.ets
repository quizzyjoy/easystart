/**
 * 样例子页路由载荷（v3.9）。
 *
 * 画廊 hub → 入口的 @Event 载荷类型：DemoFeature 不感知导航（零 RouterManager
 * import，@Event 上抛纪律），入口 switch 本枚举 → AppRoute 常量后 push——
 * 枚举到路由名的映射唯一出处在入口装配层。
 */
export enum DemoSample {
  /** 令牌总览（入口映射 AppRoute.DEMO_TOKENS） */
  TOKENS,
  /** 反馈流（入口映射 AppRoute.DEMO_FEEDBACK） */
  FEEDBACK,
  /** 数据看板（入口映射 AppRoute.DEMO_CHARTS） */
  CHARTS,
  /** 表单范式（入口映射 AppRoute.DEMO_FORM） */
  FORM,
  /** 列表四态（入口映射 AppRoute.DEMO_LIST） */
  LIST,
  /** 搜索场景（入口映射 AppRoute.DEMO_SEARCH） */
  SEARCH,
  /** 悬停态分屏（v3.31 / FOLD-01；入口启动独立 FoldHoverAbility，不走路由） */
  FOLD_HOVER,
  /** 运行时权限（v3.79 独立页：申请 → 弹窗 → 拒绝 → 去设置） */
  PERMISSION,
  /** 网络请求（v3.79 独立页：2xx / 非 2xx / 超时三型） */
  NETWORK,
  /** 长列表性能（v3.79 独立页：ForEach vs LazyForEach 计数对照） */
  LIST_PERF,
  /** 无障碍四件套（v3.79 独立页：text / level / group / description） */
  A11Y,
  /** 瀑布流布局（v3.80 独立页） */
  LAYOUT_WATERFLOW,
  /** 列表布局（v3.80 独立页） */
  LAYOUT_LIST,
  /** 网格布局（v3.80 独立页） */
  LAYOUT_GRID,
  /** 自适应七能力（v3.80 独立页） */
  LAYOUT_ADAPTIVE
}
