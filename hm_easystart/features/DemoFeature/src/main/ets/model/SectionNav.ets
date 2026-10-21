import { GALLERY_GROUPS, GalleryGroupEntry, VITALUI_GROUPS } from './GalleryGroup';

/**
 * 示例 Tab 二级导航的数据（v3.66）。
 *
 * 背景：首页（L1）改为**只显示六个入口卡**，卡内不再内嵌子入口行；点子入口的动作
 * 统一收口到二级导航页 `SectionNavView`。本文件给该页提供：
 * - `sectionNavRows(id)`：某个入口下的子行（组件示例 3 行 / VitalUI 4 行 / 场景示例 6 行）；
 * - `sectionNavTitle(id)` / `sectionNavDesc(id)`：二级页标题与一句话说明。
 *
 * 行数据唯一出处：组件行来自 `GalleryGroup`（与首页卡同一份元数据），场景行在本文件。
 */
export class SectionNavRow {
  readonly id: string;
  /** 标题/描述走三语资源（v3.78）。 */
  readonly title: ResourceStr;
  readonly desc: ResourceStr;

  constructor(id: string, title: ResourceStr, desc: ResourceStr) {
    this.id = id;
    this.title = title;
    this.desc = desc;
  }
}

/** 场景示例六行（与入口 `openSceneById` 的 switch 一一对应）。 */
export const SCENE_NAV_ROWS: SectionNavRow[] = [
  new SectionNavRow('feedback', $r('app.string.scene_feedback_title'), $r('app.string.scene_feedback_desc')),
  new SectionNavRow('charts', $r('app.string.scene_charts_title'), $r('app.string.scene_charts_desc')),
  new SectionNavRow('form', $r('app.string.scene_form_title'), $r('app.string.scene_form_desc')),
  new SectionNavRow('list', $r('app.string.scene_list_title'), $r('app.string.scene_list_desc')),
  new SectionNavRow('search', $r('app.string.scene_search_title'), $r('app.string.scene_search_desc')),
  new SectionNavRow('hover', $r('app.string.scene_hover_title'), $r('app.string.scene_hover_desc'))
];

/**
 * 工程能力四行（v3.79）。
 *
 * 这四项都是"多段状态"型示例（权限四段、网络三型、性能两模式、无障碍四 API），
 * 因此各自独立成页；本文件只负责把它们注册进二级导航，与场景示例同构。
 */
export const ENGINEERING_NAV_ROWS: SectionNavRow[] = [
  new SectionNavRow('permission', $r('app.string.engineering_permission_title'),
    $r('app.string.engineering_permission_desc')),
  new SectionNavRow('network', $r('app.string.engineering_network_title'),
    $r('app.string.engineering_network_desc')),
  new SectionNavRow('listperf', $r('app.string.engineering_listperf_title'),
    $r('app.string.engineering_listperf_desc')),
  new SectionNavRow('a11y', $r('app.string.engineering_a11y_title'),
    $r('app.string.engineering_a11y_desc'))
];

/**
 * 布局示例四行（v3.80）。
 *
 * 对应官方「一多」四类响应式里的「重复布局」与「组件响应式」：
 * 瀑布流（重复）/ 列表分组多列（重复）/ 网格跨格（重复）/ 自适应七能力（连续变化）。
 */
export const LAYOUT_NAV_ROWS: SectionNavRow[] = [
  new SectionNavRow('waterflow', $r('app.string.layout_waterflow_title'), $r('app.string.layout_waterflow_desc')),
  new SectionNavRow('list', $r('app.string.layout_list_title'), $r('app.string.layout_list_desc')),
  new SectionNavRow('grid', $r('app.string.layout_grid_title'), $r('app.string.layout_grid_desc')),
  new SectionNavRow('adaptive', $r('app.string.layout_adaptive_title'), $r('app.string.layout_adaptive_desc'))
];

/** 二级页标题（未知 id 回落「示例」）。 */
export function sectionNavTitle(sectionId: string): string {
  if (sectionId === 'gallery') {
    return '组件示例';
  }
  if (sectionId === 'vitalui') {
    return 'VitalUI 组件';
  }
  if (sectionId === 'scene') {
    return '场景示例';
  }
  if (sectionId === 'engineering') {
    return '工程能力';
  }
  if (sectionId === 'layout') {
    return '布局示例';
  }
  return '示例';
}

/** 二级页一句话说明（与首页卡 desc 同口径，但更强调"进入后可选什么"）。 */
export function sectionNavDesc(sectionId: string): string {
  if (sectionId === 'gallery') {
    return '应用级单组件对照：选一组进入，组内按小节平铺示例。';
  }
  if (sectionId === 'vitalui') {
    return '@quizzyjoy/vitalui 库内组件：图表 / 加载 / 取色器 / 状态容器。';
  }
  if (sectionId === 'scene') {
    return '可整体复制的页面范式：选一个场景进入完整示例页。';
  }
  if (sectionId === 'engineering') {
    return '工程横切能力：权限 / 网络 / 长列表 / 无障碍，每项一个独立页，含真实设备实测结论。';
  }
  if (sectionId === 'layout') {
    return '一多布局范式：瀑布流 / 列表分组 / 网格跨格 / 自适应七能力，每项一个独立页。';
  }
  return '';
}

/** 取某个入口下的子行（组件类走 GalleryGroup，场景走本文件）。 */
export function sectionNavRows(sectionId: string): SectionNavRow[] {
  if (sectionId === 'scene') {
    return SCENE_NAV_ROWS;
  }
  if (sectionId === 'engineering') {
    return ENGINEERING_NAV_ROWS;
  }
  if (sectionId === 'layout') {
    return LAYOUT_NAV_ROWS;
  }
  const source: GalleryGroupEntry[] = sectionId === 'vitalui' ? VITALUI_GROUPS : GALLERY_GROUPS;
  return source.map((group: GalleryGroupEntry): SectionNavRow =>
    new SectionNavRow(group.id, group.title, group.desc));
}
