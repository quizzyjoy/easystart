/**
 * 组件示例分组元数据（v3.38 三级架构）。
 *
 * 唯一出处：L1 首页「组件示例」大卡的四行入口 + L2 分组页 titleBar 标题，
 * 分组名/文案/图标在本文件维护，避免索引卡、入口、标题三处漂移。
 * 分组内容本身仍在 ComponentGalleryView 内按 groupId 渲染（本文件只管元数据）。
 */
export class GalleryGroupEntry {
  readonly id: string;
  /** 标题/描述走三语资源（v3.78）。 */
  readonly title: ResourceStr;
  readonly desc: ResourceStr;
  readonly symbol: Resource;
  readonly tint: Resource;

  constructor(id: string, title: ResourceStr, desc: ResourceStr, symbol: Resource, tint: Resource) {
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
  new GalleryGroupEntry('act', $r('app.string.gallery_group_act_title'),
    $r('app.string.gallery_group_act_desc'),
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand')),
  new GalleryGroupEntry('input', $r('app.string.gallery_group_input_title'),
    $r('app.string.gallery_group_input_desc'),
    $r('sys.symbol.ellipsis_circle'), $r('app.color.app_accent_teal')),
  new GalleryGroupEntry('feedback', $r('app.string.gallery_group_feedback_title'),
    $r('app.string.gallery_group_feedback_desc'),
    $r('sys.symbol.checkmark_circle'), $r('app.color.app_accent_pink')),
  new GalleryGroupEntry('overlay', $r('app.string.gallery_group_overlay_title'),
    $r('app.string.gallery_group_overlay_desc'),
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_purple')),
  new GalleryGroupEntry('responsive', $r('app.string.gallery_group_responsive_title'),
    $r('app.string.gallery_group_responsive_desc'),
    $r('sys.symbol.display'), $r('app.color.app_accent_teal')),
  new GalleryGroupEntry('platform', $r('app.string.gallery_group_platform_title'),
    $r('app.string.gallery_group_platform_desc'),
    $r('sys.symbol.doc_text'), $r('app.color.qj_brand')),
  new GalleryGroupEntry('app', $r('app.string.gallery_group_app_title'),
    $r('app.string.gallery_group_app_desc'),
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
  new GalleryGroupEntry('chart', $r('app.string.vitalui_group_chart_title'),
    $r('app.string.vitalui_group_chart_desc'),
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_pink')),
  new GalleryGroupEntry('loading', $r('app.string.vitalui_group_loading_title'),
    $r('app.string.vitalui_group_loading_desc'),
    $r('sys.symbol.arrow_clockwise'), $r('app.color.app_accent_teal')),
  new GalleryGroupEntry('color', $r('app.string.vitalui_group_color_title'),
    $r('app.string.vitalui_group_color_desc'),
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_purple')),
  new GalleryGroupEntry('state', $r('app.string.vitalui_group_state_title'),
    $r('app.string.vitalui_group_state_desc'),
    $r('sys.symbol.ellipsis_circle'), $r('app.color.qj_brand'))
];

/** 全部分组（通用 + VitalUI，按展示顺序拼接；标题查找与长页遍历用）。 */
export const ALL_GALLERY_GROUPS: GalleryGroupEntry[] = GALLERY_GROUPS.concat(VITALUI_GROUPS);

/** 分组 id → 标题（入口 pageMap 的 titleBar 标题来源；未知 id 回落总标题）。 */
export function galleryGroupTitle(groupId: string): ResourceStr {
  const hit: GalleryGroupEntry | undefined =
    ALL_GALLERY_GROUPS.find((entry: GalleryGroupEntry): boolean => entry.id === groupId);
  return hit === undefined ? $r('app.string.examples_card_gallery_title') : hit.title;
}
