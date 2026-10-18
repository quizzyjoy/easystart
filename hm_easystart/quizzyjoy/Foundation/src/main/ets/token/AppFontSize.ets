/**
 * 字号刻度（fp，跟随用户字体缩放）。
 *
 * v3.6（2026-10-04）对照官方《文本排版》字阶表全面对齐（审计组 2）：
 * - 官方 phone 阶：Caption_M 10 / Caption_L 12 / Body_S 12 / Body_M 14 / Subtitle_S 14 /
 *   Body_L 16 / Subtitle_M 16 / Subtitle_L 18 / Title_S 20 / Title_M 24 /
 *   Title_L 30 / Display_S 38 / Display_M 48 / Display_L 56；
 * - 原TITLE_LG(22)/DISPLAY_SM(28)/DISPLAY(32) 为 Apple 借位非官方阶，已归位：
 *   TITLE_LG 22→24（Title_M）、HEADLINE 24→30（Title_L）、
 *   DISPLAY_SM 28→38（Display_S）、DISPLAY 32→48（Display_M）；
 * - PC/watch 阶不同（PC Title_M=22、Title_L=28 等；watch 另有 Caption_S=8），
 *   穿戴入口用 CAPTION_XS=10 与官方 watch Caption_M=10 一致；
 * - 大字体适配：1.75 倍系统字体下布局不得错乱（官方排版体验要求）。
 *
 * 伴生刻度：字重 AppFontWeight、行高 AppLineHeight（见同目录）。
 */
export class AppFontSize {
  /** 极辅助信息（角标、时间戳），禁用于正文（官方 Caption_M=10）。 */
  static readonly CAPTION_XS: number = 10;
  /** 辅助说明（官方 Caption_L=12 / Body_S=12）。 */
  static readonly CAPTION: number = 12;
  /** 次要正文（官方 Body_M=14 / Subtitle_S=14）。 */
  static readonly BODY_SM: number = 14;
  /** 正文（官方 Body_L=16 / Subtitle_M=16）。 */
  static readonly BODY: number = 16;
  /** 小标题（官方 Subtitle_L=18）。 */
  static readonly TITLE_SM: number = 18;
  /** 标题、对话框标题（官方 Title_S=20）。 */
  static readonly TITLE: number = 20;
  /** 大标题（官方 Title_M=24）。 */
  static readonly TITLE_LG: number = 24;
  /** 页面主标题（官方 Title_L=30）。 */
  static readonly HEADLINE: number = 30;
  /** 展示数字（官方 Display_S=38）。 */
  static readonly DISPLAY_SM: number = 38;
  /** 首屏大字（官方 Display_M=48；Display_L=56 需要时再补档）。 */
  static readonly DISPLAY: number = 48;
}
