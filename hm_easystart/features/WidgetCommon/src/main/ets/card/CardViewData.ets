/**
 * 服务卡片展示数据契约（v3.27）。
 *
 * 设计要点（对标生产级做法，见 EasyMath 每日一题卡片）：
 * 1. **全部字段为可直接渲染的字符串**——卡片侧零计算、零 IO、零条件分支取数；
 * 2. 载荷键名集中在此（`CardPayloadKeys`），卡片页的 `@LocalStorageProp` 字面量须与之逐字一致
 *    （同值对齐纪律：改键名须同时改卡片页）；
 * 3. `CardLayout` 与 form_config 的 `supportDimensions` 语义对齐（紧凑 2×2 / 宽卡 2×4）。
 */

/** 卡片规格（与 form_config 的 supportDimensions 对齐）。 */
export enum CardLayout {
  /** 2×2 紧凑 */
  COMPACT,
  /** 2×4 宽卡 */
  WIDE
}

/**
 * 卡片载荷键名（formBindingData 与卡片页 @LocalStorageProp 的契约）。
 * 卡片页的装饰器参数是字面量、不能引用常量，故此处与卡片页之间以本表为「单一真相源」。
 */
export class CardPayloadKeys {
  static readonly TITLE: string = 'title';
  static readonly SUBTITLE: string = 'subtitle';
  static readonly THEME: string = 'themeText';
  static readonly LANGUAGE: string = 'languageText';
  static readonly FONT_SIZE: string = 'fontSizeText';
  static readonly HAPTIC: string = 'hapticText';
  static readonly ACCENT: string = 'accentText';
  static readonly UPDATED: string = 'updatedText';
  static readonly CTA: string = 'ctaText';
  static readonly IS_WIDE: string = 'isWide';
}

/** 卡片展示数据（组装结果；卡片侧只读渲染）。 */
export class CardViewData {
  /** 应用名（来自 AppScope 资源，失败回退字面量）。 */
  title: string = '';
  /** 副标题（含规格提示：宽卡会注明 2×4）。 */
  subtitle: string = '';
  /** 显示模式文案（浅色 / 深色 / 跟随系统）。 */
  themeText: string = '';
  /** 应用语言文案（简体中文 / English / 跟随系统）。 */
  languageText: string = '';
  /** 字号档位文案（标准（1×）等）。 */
  fontSizeText: string = '';
  /** 触感反馈文案（开 / 关）。 */
  hapticText: string = '';
  /** 强调色（小写 #rrggbb；空/非法已回退品牌色）。 */
  accentText: string = '';
  /** 最近刷新时间（hh:mm）——定时刷新与新装/尺寸变化都会更新。 */
  updatedText: string = '';
  /** 行动号召文案（点击整卡拉起应用）。 */
  ctaText: string = '';
  /** 当前规格。 */
  layout: CardLayout = CardLayout.COMPACT;
}

/** 展示数据 → 卡片载荷（纯数据转换，不碰 FormKit；FormAbility 侧再包成 formBindingData）。 */
export function toCardPayload(data: CardViewData): Record<string, string> {
  const payload: Record<string, string> = {
    'title': data.title,
    'subtitle': data.subtitle,
    'themeText': data.themeText,
    'languageText': data.languageText,
    'fontSizeText': data.fontSizeText,
    'hapticText': data.hapticText,
    'accentText': data.accentText,
    'updatedText': data.updatedText,
    'ctaText': data.ctaText,
    'isWide': data.layout === CardLayout.WIDE ? '1' : '0'
  };
  return payload;
}
