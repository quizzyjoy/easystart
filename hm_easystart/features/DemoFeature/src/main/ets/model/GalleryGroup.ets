/**
 * 组件示例分组元数据（v3.38 三级架构）。
 *
 * 唯一出处：L1 首页「组件示例」大卡的四行入口 + L2 分组页 titleBar 标题，
 * 分组名/文案/图标在本文件维护，避免索引卡、入口、标题三处漂移。
 * 分组内容本身仍在 ComponentGalleryView 内按 groupId 渲染（本文件只管元数据）。
 */
export class GalleryGroupEntry {
  readonly id: string;
  readonly title: string;
  readonly desc: string;
  readonly symbol: Resource;
  readonly tint: Resource;

  constructor(id: string, title: string, desc: string, symbol: Resource, tint: Resource) {
    this.id = id;
    this.title = title;
    this.desc = desc;
    this.symbol = symbol;
    this.tint = tint;
  }
}

/**
 * 四个分组（顺序即 L1 卡片行顺序、L2 长页顺序）。
 *
 * tint 一律饱和色：与 L1 首页 chip 的取色纪律一致（浅色下 qj_brand_light 配白图标对比度不足）。
 */
/**
 * 通用组件分组（顺序即 L1「组件示例」卡的行顺序、L2 长页顺序）。
 *
 * v3.65：VitalUI 组件单独成区（见 `VITALUI_GROUPS`），本数组只留应用级/平台级示例。
 */
/**
 * 通用组件分组（顺序即 L1「组件示例」卡的行顺序、L2 长页顺序）。
 *
 * v3.69：原三组（入口与基础 / 平台能力与令牌 / 应用组件与动效）按**实际内容**拆成七组，
 * 一组一页一事；VitalUI 组件仍单独成区（见 `VITALUI_GROUPS`）。
 */
export const GALLERY_GROUPS: GalleryGroupEntry[] = [
  new GalleryGroupEntry('act', '操作与状态',
    '按钮六形态（含加载 / 禁用）+ 标签五档语义（含可关闭）',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand')),
  new GalleryGroupEntry('input', '输入与检索',
    '搜索栏受控 + 300ms 防抖，回车与取消分流回调',
    $r('sys.symbol.ellipsis_circle'), $r('app.color.app_accent_teal')),
  new GalleryGroupEntry('feedback', '反馈与容器',
    '轻提示 / 失败提示 / 确认对话框 + ActionCard 卡片容器',
    $r('sys.symbol.checkmark_circle'), $r('app.color.app_accent_pink')),
  new GalleryGroupEntry('overlay', '弹层与选择器',
    '日期 / 农历 / 时间 / 日历 / 文本轮播 + Sheet（统一走 UIContext）',
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_purple')),
  new GalleryGroupEntry('responsive', '响应式与令牌',
    '响应式 DSL 规则求值 + 折叠态折痕 + 49 色彩令牌对照',
    $r('sys.symbol.display'), $r('app.color.app_accent_teal')),
  new GalleryGroupEntry('platform', '平台能力',
    '沉浸式避让 / 系统分享 / 选图 / 剪贴板与安全组件',
    $r('sys.symbol.doc_text'), $r('app.color.qj_brand')),
  new GalleryGroupEntry('app', '应用组件与动效',
    'AppComponent 反馈族 / modifier 族 / 控件工厂 + 动效规范',
    $r('sys.symbol.gearshape_fill'), $r('app.color.app_accent_purple'))
];

/**
 * VitalUI 组件分组（v3.65 独立成区）。
 *
 * 与 `GALLERY_GROUPS` 分开的理由：这两组属于模板自带 UI 库（`@quizzyjoy/vitalui`），
 * fork 后通常整库复用、只改主题；而上面三组是应用级/平台级示例。分开后首页一眼能分辨
 * 「库里的组件」与「应用怎么用库」。
 */
export const VITALUI_GROUPS: GalleryGroupEntry[] = [
  new GalleryGroupEntry('chart', '数据图表',
    '四图表聚合：玫瑰 / 饼 / 季度玫瑰 / 雷达（Canvas 自绘，可点选）',
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_pink')),
  new GalleryGroupEntry('loading', '加载与骨架',
    'CommonLoading 四形态 + SkeletonBlock 骨架屏',
    $r('sys.symbol.arrow_clockwise'), $r('app.color.app_accent_teal')),
  new GalleryGroupEntry('color', '颜色选择器',
    'CommonColorPicker + ColorMath 色彩数学（Hex / RGB / HSL 互转）',
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_purple')),
  new GalleryGroupEntry('state', '状态与列表',
    'StateContainer 四态 + RefreshList 下拉刷新状态机',
    $r('sys.symbol.ellipsis_circle'), $r('app.color.qj_brand'))
];

/** 全部分组（通用 + VitalUI，按展示顺序拼接；标题查找与长页遍历用）。 */
export const ALL_GALLERY_GROUPS: GalleryGroupEntry[] = GALLERY_GROUPS.concat(VITALUI_GROUPS);

/** 分组 id → 标题（入口 pageMap 的 titleBar 标题来源；未知 id 回落总标题）。 */
export function galleryGroupTitle(groupId: string): string {
  const hit: GalleryGroupEntry | undefined =
    ALL_GALLERY_GROUPS.find((entry: GalleryGroupEntry): boolean => entry.id === groupId);
  return hit === undefined ? '组件示例' : hit.title;
}
