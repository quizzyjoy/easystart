import { CustomColors, CustomDarkColors, CustomTheme, Theme, ThemeControl } from '@kit.ArkUI';
import { Logger, resolveThemePreset } from '@quizzyjoy/foundation';

const DOMAIN: string = '0xF014';
const TAG: string = 'AppThemeController';

/** 主题相关类型统一从本层再导出（F14：@kit 触点在 Platform 收口，上层零 @kit）。 */
export { CustomColors, CustomDarkColors, CustomTheme, Theme };

/**
 * 应用级主题控制器（v3.43）。
 *
 * 职责：把「一个品牌色 hex」翻译成 ArkUI 的 `CustomTheme`（含 `darkColors`），
 * 并调用官方 `ThemeControl.setDefaultTheme` 让**系统组件默认色**跟随品牌色
 * —— 这是自绘色票（`$r('app.color.*')`）与运行时强调色注入（UiThemeManager）
 * 之外的第三层，补齐「对话框主按钮 / SnackBar 动作色 / Toggle 选中色」不换色的断层。
 *
 * 纪律：
 * - 只在 ArkUI 初始化之后调用（入口 `windowStage.loadContent` 回调内）；
 * - 每次改色**重新调用一次**即可覆盖上一次（官方 API 支持重复调用，传 undefined 清除）；
 * - 全程 try/catch：主题失败不得影响启动，失败时上层保持现状（自绘色仍生效）。
 *
 * 覆盖的 token 选择理由（其余 40+ token 交给系统默认，避免过度覆盖导致对比度问题）：
 * brand（填充按钮/开关选中）、fontEmphasize（强调文本）、iconEmphasize（强调图标）、
 * backgroundEmphasize（强调底）、compEmphasizeSecondary/Tertiary（组件强调层）、
 * interactiveSelect（选中态）。
 */
export class AppThemeController {
  private static applied: string = '';

  /**
   * 应用主题：`accentHex` 非空时以它为准，否则用主题包基准色。
   *
   * `darkColors` 由系统按当前色彩模式自动选用，因此**不需要**传 dark 标志；
   * 但必须与 `colors` 成对提供，否则暗色下会亮底亮字。
   *
   * @returns 是否成功设置（false = 参数非法或平台调用失败，上层可忽略）
   */
  static applyPreset(presetId: string, accentHex: string): boolean {
    const base: string = accentHex.length > 0 ? accentHex : resolveThemePreset(presetId).baseHex;
    const normalized: string = AppThemeController.normalize(base);
    if (normalized.length === 0) {
      Logger.warn(DOMAIN, TAG, 'applyPreset skipped: invalid hex');
      return false;
    }
    if (normalized === AppThemeController.applied) {
      return true;
    }
    try {
      ThemeControl.setDefaultTheme(AppThemeController.buildTheme(normalized));
      AppThemeController.applied = normalized;
      Logger.info(DOMAIN, TAG, `theme applied: ${normalized} preset=${presetId}`);
      return true;
    } catch (err) {
      const e = err as BusinessError;
      // 主题失败不阻塞启动：L1 令牌与 L3 注入仍然有效
      Logger.warn(DOMAIN, TAG, `applyPreset failed: code=${e.code} ${e.message}`);
      return false;
    }
  }

  /** 清除自定义主题，回到系统默认。 */
  static clear(): void {
    try {
      ThemeControl.setDefaultTheme(undefined);
      AppThemeController.applied = '';
      Logger.info(DOMAIN, TAG, 'theme cleared');
    } catch (err) {
      const e = err as BusinessError;
      Logger.warn(DOMAIN, TAG, `clear failed: code=${e.code} ${e.message}`);
    }
  }

  /** hex → CustomTheme（colors + darkColors 成对，避免暗色下亮底亮字）。 */
  static buildTheme(hex: string): CustomTheme {
    return {
      colors: AppThemeController.lightColors(hex),
      darkColors: AppThemeController.darkColors(hex)
    };
  }

  /** 浅色模式：直接用品牌色 + 系统可读的强调层。 */
  private static lightColors(hex: string): CustomColors {
    const soft: string = AppThemeController.mix(hex, '#FFFFFF', 0.82);
    const soft2: string = AppThemeController.mix(hex, '#FFFFFF', 0.9);
    return {
      brand: hex,
      fontEmphasize: hex,
      iconEmphasize: hex,
      backgroundEmphasize: hex,
      compEmphasizeSecondary: soft,
      compEmphasizeTertiary: soft2,
      interactiveSelect: soft2
    };
  }

  /** 深色模式：品牌色提亮一档（暗底上原色会发闷），强调层改为低透明叠色。 */
  private static darkColors(hex: string): CustomDarkColors {
    const lifted: string = AppThemeController.mix(hex, '#FFFFFF', 0.28);
    const soft: string = AppThemeController.mix(lifted, '#000000', 0.72);
    const soft2: string = AppThemeController.mix(lifted, '#000000', 0.82);
    return {
      brand: lifted,
      fontEmphasize: lifted,
      iconEmphasize: lifted,
      backgroundEmphasize: lifted,
      compEmphasizeSecondary: soft,
      compEmphasizeTertiary: soft2,
      interactiveSelect: soft2
    };
  }

  /** '#RRGGBB' / '#AARRGGBB' → 规范化 '#RRGGBB'；非法返回空串。 */
  private static normalize(hex: string): string {
    const lower: string = hex.trim().toLowerCase();
    if (lower.length === 7 && lower.startsWith('#')) {
      return lower;
    }
    if (lower.length === 9 && lower.startsWith('#')) {
      return `#${lower.substring(3)}`;
    }
    return '';
  }

  /** 两色线性混合（ratio = 目标色占比）。 */
  private static mix(from: string, to: string, ratio: number): string {
    const a: number[] = AppThemeController.rgbOf(from);
    const b: number[] = AppThemeController.rgbOf(to);
    const r: number = Math.round(a[0] + (b[0] - a[0]) * ratio);
    const g: number = Math.round(a[1] + (b[1] - a[1]) * ratio);
    const bl: number = Math.round(a[2] + (b[2] - a[2]) * ratio);
    return `#${AppThemeController.hex2(r)}${AppThemeController.hex2(g)}${AppThemeController.hex2(bl)}`;
  }

  private static rgbOf(hex: string): number[] {
    const h: string = AppThemeController.normalize(hex).substring(1);
    return [parseInt(h.substring(0, 2), 16), parseInt(h.substring(2, 4), 16), parseInt(h.substring(4, 6), 16)];
  }

  private static hex2(v: number): string {
    const s: string = v.toString(16);
    return s.length === 1 ? `0${s}` : s;
  }
}
