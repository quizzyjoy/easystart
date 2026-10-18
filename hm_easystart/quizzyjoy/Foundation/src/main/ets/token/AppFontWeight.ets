/**
 * 字重刻度（ArkUI FontWeight）。
 *
 * v3.6（2026-10-04）使用律对照官方《文本排版》字阶表修订（审计组 2）：
 * 官方字重指派——Display=Light、Title=Bold、Subtitle/Caption=Medium、
 * Body_L=Medium、Body_M/S=Regular；另 Button 默认字重 500（Medium，官方组件默认）。
 *
 * 使用律：
 * - 展示大字（DISPLAY 档）LIGHT；
 * - 标题（TITLE/HEADLINE 档）BOLD；
 * - 小标题 / 按钮 / 选中态 / 说明文字（CAPTION）MEDIUM；
 * - 正文（BODY/BODY_SM）REGULAR；
 * - 禁用 Bolder（Light 仅限展示大字，不用于正文）。
 */
export class AppFontWeight {
  /** 展示大字（官方 Display=Light；ArkUI 枚举无 Light 成员，以数值 300 表达）。 */
  static readonly LIGHT: number = 300;
  static readonly REGULAR: FontWeight = FontWeight.Normal;
  static readonly MEDIUM: FontWeight = FontWeight.Medium;
  static readonly BOLD: FontWeight = FontWeight.Bold;
}
