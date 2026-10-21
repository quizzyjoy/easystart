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
  readonly title: string;
  readonly desc: string;

  constructor(id: string, title: string, desc: string) {
    this.id = id;
    this.title = title;
    this.desc = desc;
  }
}

/** 场景示例六行（与入口 `openSceneById` 的 switch 一一对应）。 */
export const SCENE_NAV_ROWS: SectionNavRow[] = [
  new SectionNavRow('feedback', '反馈流', '提交失败重试链路 / 危险确认 / 筛选 Sheet 多选回写'),
  new SectionNavRow('charts', '数据看板', '四图表断点栅格 + 深浅色联动重绘 + 选中详情联动'),
  new SectionNavRow('form', '表单范式', 'AppFormField 受控域 + 逐域校验红线 + 取色联动'),
  new SectionNavRow('list', '列表四态', 'StateContainer 四态切换 + RefreshList 刷新与分页'),
  new SectionNavRow('search', '搜索场景', 'CommonSearchBar 防抖受控 + 热词 / 结果 / 空态'),
  new SectionNavRow('hover', '悬停态分屏', '折叠屏半折叠（帐篷态）真实折痕分屏示例')
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
  return '';
}

/** 取某个入口下的子行（组件类走 GalleryGroup，场景走本文件）。 */
export function sectionNavRows(sectionId: string): SectionNavRow[] {
  if (sectionId === 'scene') {
    return SCENE_NAV_ROWS;
  }
  const source: GalleryGroupEntry[] = sectionId === 'vitalui' ? VITALUI_GROUPS : GALLERY_GROUPS;
  return source.map((group: GalleryGroupEntry): SectionNavRow =>
    new SectionNavRow(group.id, group.title, group.desc));
}
