/**
 * 行高刻度（倍率，值随字号）。
 *
 * v3.0 新增。中文行高经验 1.5-1.65（西文 1.4-1.5 偏低，汉字满高需要更多呼吸）；
 * 官方《文本排版》未量化行高比值，此为经验刻度（M3 body large 16/24=1.5 可互证，
 * 但 M3 非 HarmonyOS 官方依据）。
 *
 * 消费：AppLineHeight.for(AppFontSize.BODY, AppLineHeight.NORMAL) → 24
 */
export class AppLineHeight {
  /** 单行标题 / 按钮（1.2 倍）。 */
  static readonly TIGHT: number = 1.2;
  /** 中文正文（1.5 倍，推荐起步档）。 */
  static readonly NORMAL: number = 1.5;
  /** 长文阅读页（1.65 倍）。 */
  static readonly RELAXED: number = 1.65;

  /** 按字号与倍率求行高（fp，取整）。 */
  static for(fontSize: number, ratio: number): number {
    return Math.round(fontSize * ratio);
  }
}
