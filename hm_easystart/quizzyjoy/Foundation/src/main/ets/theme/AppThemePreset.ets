/**
 * 主题包（v3.43）——「换肤」的预设色板。
 *
 * 设计取舍：
 * - 一个主题包只定义**一个品牌色**，其余层级（强调底/描边/选中态）由
 *   `AppThemeController`（Platform）按比例派生，避免每套主题手写几十个 token；
 * - 强调色（用户在取色器里自选）优先于主题包：`accentColor` 非空时以它为准；
 * - 因此「主题包」是整套基线，「强调色」是单点微调，二者叠加而不是互斥。
 *
 * 纯数据 + 纯函数，零 @kit（VitalUI 纪律）。
 */

export class AppThemePreset {
  /** 稳定 id（持久化用，勿改名） */
  id: string = '';
  /** 中文名（模板面向 fork 开发者，直给中文，不做三语） */
  label: string = '';
  /** 品牌基准色 '#RRGGBB' */
  baseHex: string = '';

  constructor(id: string, label: string, baseHex: string) {
    this.id = id;
    this.label = label;
    this.baseHex = baseHex;
  }
}

/** 默认主题包 id（= 现有 qj_brand 的品牌紫） */
export const DEFAULT_THEME_PRESET: string = 'brand';

/** 内置主题包（4 套：品牌紫 / 青碧 / 桃粉 / 高对比） */
export function appThemePresets(): AppThemePreset[] {
  return [
    // 默认主题包 = 原 qj_brand 令牌（#0A59F7 品牌蓝）：迁移后默认观感与改造前完全一致
    new AppThemePreset('brand', '品牌蓝', '#0A59F7'),
    new AppThemePreset('violet', '靛紫', '#6c4de8'),
    new AppThemePreset('teal', '青碧', '#12A594'),
    new AppThemePreset('pink', '桃粉', '#D6409F'),
    new AppThemePreset('contrast', '高对比', '#0A0A0A')
  ];
}

/** 按 id 取主题包（未知 id 回退默认）。 */
export function resolveThemePreset(id: string): AppThemePreset {
  const list: AppThemePreset[] = appThemePresets();
  for (let i = 0; i < list.length; i++) {
    if (list[i].id === id) {
      return list[i];
    }
  }
  return list[0];
}
