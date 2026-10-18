/**
 * 圆角刻度（vp）。
 *
 * v3.6（2026-10-04）对照官方《圆角参数》修订场景映射（审计组 2）：
 * - 数值档全部与官方 token 表一致（level1=2/level4=8/level8=16/level10=20/
 *   level12=24/level16=32）；
 * - 官方场景表：标签角标=4、图片图标=8、通知卡片/普通卡片/内容容器=16、
 *   按钮菜单选项卡=20、半模态弹窗/大型弹出框=32；
 * - 卡片由 24 改 16（原值违反官方场景表，且与对话框同为 24 违反
 *   「层级正相关」原则：顶层元素圆角应大于内容层）；
 * - 对话框保持 24：与 ArkUI AlertDialog 组件默认一致；官方 32 场景指
 *   半模态与大型弹出框（AppSheet 的 32 已覆盖）。
 *
 * 组件映射（契约见设计文档 §II.2）：
 * 按钮 XXL(20) / 卡片 XL(16) / 对话框 XXXL(24) / 半模态 sheet HUGE(32)
 * 输入框 XXL(20) / 菜单 XXL(20) / 图标容器·徽标 MD(8) 或 FULL / 标签 FULL
 */
export class AppRadius {
  static readonly NONE: number = 0;
  /** 进度条、极小标记（官方 corner_radius_level1）。 */
  static readonly XS: number = 2;
  /** 复选框、小标签内圆角（官方 level2 / check_box / subtab）。 */
  static readonly SM: number = 4;
  /** 图标容器、点击态（官方 level4 / icon / clicked）。 */
  static readonly MD: number = 8;
  /** 网格项、小卡片（官方 level6 / grid）。 */
  static readonly LG: number = 12;
  /** 中卡片、通知、普通卡片、内容容器（官方场景表 / notification）。 */
  static readonly XL: number = 16;
  /** 按钮、输入框、菜单（官方 level10 / button / text_field / menu）。 */
  static readonly XXL: number = 20;
  /** 对话框（官方 token level12；标准确认框与 ArkUI AlertDialog 默认一致）。 */
  static readonly XXXL: number = 24;
  /** 半模态 sheet、面板（官方 level16 / panel）。 */
  static readonly HUGE: number = 32;
  static readonly FULL: number = 999;
}
