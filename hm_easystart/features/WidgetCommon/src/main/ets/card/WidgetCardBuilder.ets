import { common, I18nManager, PreferencesStore } from '@quizzyjoy/platform';
import { FontSizeScale, PreferenceKeys } from '@easystart/app-preferences';
import { CardLayout, CardViewData } from './CardViewData';

/**
 * 服务卡片展示数据组装（v3.27）。
 *
 * 【两条读取路径——按**进程**选择，不可混用】
 * 1. `buildWidgetCardData`（**卡片/Extension 进程**）：同步 + `dropCache`。
 *    卡片进程与 UI 进程不共享内存态，必须丢缓存才能读到 UI 进程刚落盘的值。
 * 2. `buildWidgetCardDataAsync`（**UI 进程**，应用内主动刷新）：走 `PreferencesStore`
 *    异步链——它与「设置页写入」是**同一个实例**，天然读到最新值；
 *    UI 进程**禁止**丢缓存（会打 detached，见 PreferencesStore 头注）。
 *
 * 【v3.27.1 真机实测修正】UI 进程原走同步实例 → 读到的是该实例的**陈旧快照**
 * （真机现象：设置为「浅色」后卡片仍显示「跟随系统」）；改异步链后跟随正常。
 *
 * 【时间格式】跟随系统 12/24 小时制（`I18nManager.is24HourClock()`，该机型为 12 小时制，
 * 卡片原固定 24 小时制导致与系统时间显示不一致——同为真机走查发现）。
 *
 * 展示数据一律在提供方**组装为字符串**（含回退），卡片侧零计算、零 IO。
 */

/** 显示模式值（对齐 Platform AppColorMode：0 浅色 / 1 深色 / 2 跟随系统）。 */
const COLOR_MODE_LIGHT: number = 0;
const COLOR_MODE_DARK: number = 1;
const COLOR_MODE_SYSTEM: number = 2;

/** 强调色非法/缺失时的回退（品牌蓝，与 AppScope qj_brand 同值）。 */
const BRAND_FALLBACK_HEX: string = '#0a59f7';

/** 字号五档标签（与设置页 GeneralView 选项文案一致）。 */
const FONT_LABELS: string[] = ['小', '较小', '标准', '较大', '大'];

function colorModeText(mode: number): string {
  if (mode === COLOR_MODE_DARK) {
    return '深色';
  }
  if (mode === COLOR_MODE_SYSTEM) {
    return '跟随系统';
  }
  if (mode === COLOR_MODE_LIGHT) {
    return '浅色';
  }
  return '跟随系统';
}

function languageText(lang: string): string {
  if (lang === 'zh-Hans') {
    return '简体中文';
  }
  if (lang === 'en-US') {
    return 'English';
  }
  return '跟随系统';
}

function fontSizeTextOf(index: number): string {
  const i: number = FontSizeScale.clamp(index);
  return `${FONT_LABELS[i]}（${FontSizeScale.COEFFICIENTS[i]}×）`;
}

function pad2(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

/** 当前时间文案：跟随系统 12/24 小时制。 */
function nowText(): string {
  const now: Date = new Date();
  const hour: number = now.getHours();
  const minute: string = pad2(now.getMinutes());
  if (I18nManager.is24HourClock()) {
    return `${pad2(hour)}:${minute}`;
  }
  const period: string = hour < 12 ? '上午' : '下午';
  let hour12: number = hour % 12;
  if (hour12 === 0) {
    hour12 = 12;
  }
  return `${period} ${hour12}:${minute}`;
}

/** 强调色归一（主键 → 历史预设键 → 品牌回退），校验正则来自契约包。 */
function normalizeAccent(accent: string, legacy: string): string {
  const hex: string = accent.length > 0 ? accent : legacy;
  const normalized: string = hex.toLowerCase();
  return PreferenceKeys.ACCENT_HEX_PATTERN.test(normalized) ? normalized : BRAND_FALLBACK_HEX;
}

/** 应用名：读 AppScope 资源，任何异常回退字面量（Extension 进程同样可读资源）。 */
function appName(context: common.Context): string {
  try {
    const name: string = context.resourceManager.getStringSync($r('app.string.app_name'));
    return name.length > 0 ? name : '趣开发';
  } catch (err) {
    return '趣开发';
  }
}

/** 纯组装：两条读取路径共用（布局 + 已读出的偏好值 → 卡片展示数据）。 */
function assemble(layout: CardLayout, title: string, mode: number, lang: string,
  fontIndex: number, haptic: boolean, accent: string): CardViewData {
  const data = new CardViewData();
  data.layout = layout;
  data.title = title;
  data.subtitle = layout === CardLayout.WIDE ? '偏好摘要 · 2×4 宽卡' : '偏好摘要';
  data.themeText = colorModeText(mode);
  data.languageText = languageText(lang);
  data.fontSizeText = fontSizeTextOf(fontIndex);
  data.hapticText = haptic ? '开' : '关';
  data.accentText = accent;
  data.updatedText = nowText();
  data.ctaText = '打开设置 ›';
  return data;
}

/**
 * 卡片进程读取路径（**仅 FormExtensionAbility 可调用**）：同步 + dropCache。
 *
 * @param context 卡片进程的 FormExtensionContext
 * @param layout 当前卡片规格
 */
export function buildWidgetCardData(context: common.Context, layout: CardLayout): CardViewData {
  PreferencesStore.dropCache(context);
  const mode: number = PreferencesStore.getNumberSync(PreferenceKeys.DISPLAY_COLOR_MODE, COLOR_MODE_SYSTEM);
  const lang: string = PreferencesStore.getStringSync(PreferenceKeys.APP_LANGUAGE, '');
  const fontIndex: number = PreferencesStore.getNumberSync(PreferenceKeys.FONT_SIZE_INDEX,
    FontSizeScale.STANDARD_INDEX);
  const haptic: boolean = PreferencesStore.getBoolSync(PreferenceKeys.HAPTIC_ENABLED, true);
  const accent: string = normalizeAccent(
    PreferencesStore.getStringSync(PreferenceKeys.ACCENT_COLOR, ''),
    PreferencesStore.getStringSync(PreferenceKeys.ACCENT_COLOR_LEGACY, ''));
  return assemble(layout, appName(context), mode, lang, fontIndex, haptic, accent);
}

/**
 * UI 进程读取路径（应用内主动刷新，如切后台时）：异步偏好链（与写入同实例，无需丢缓存）。
 *
 * @param context UIAbilityContext
 * @param layout 当前卡片规格
 */
export async function buildWidgetCardDataAsync(context: common.Context,
  layout: CardLayout): Promise<CardViewData> {
  const mode: number = await PreferencesStore.getNumber(PreferenceKeys.DISPLAY_COLOR_MODE, COLOR_MODE_SYSTEM);
  const lang: string = await PreferencesStore.getString(PreferenceKeys.APP_LANGUAGE, '');
  const fontIndex: number = await PreferencesStore.getNumber(PreferenceKeys.FONT_SIZE_INDEX,
    FontSizeScale.STANDARD_INDEX);
  const haptic: boolean = await PreferencesStore.getBool(PreferenceKeys.HAPTIC_ENABLED, true);
  const accent: string = await PreferencesStore.getString(PreferenceKeys.ACCENT_COLOR, '');
  const legacy: string = await PreferencesStore.getString(PreferenceKeys.ACCENT_COLOR_LEGACY, '');
  return assemble(layout, appName(context), mode, lang, fontIndex, haptic, normalizeAccent(accent, legacy));
}
