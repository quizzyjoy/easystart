import { AppThemeController } from '@quizzyjoy/platform';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = '0xF015';
const TAG: string = 'AppThemeApplier';

/**
 * 主题落地器（v3.43）—— 把「主题包 + 强调色」一次性铺到三层。
 *
 * 为什么放在 AppComponent：它同时依赖 VitalUI（L3 单例）与 Platform（L4 控制器），
 * 而 AppCommon 不能依赖 VitalUI（手表要可用）、VitalUI 不能依赖 Platform（零 @kit）。
 * 入口 Ability 只调这一个方法，避免三端各写一遍顺序。
 *
 * 顺序：L3 先设（组件随之重渲染）→ L4 后设（系统组件默认色跟上），
 * 两者互不依赖，但先 L3 能让自绘组件在同一帧就取到新色。
 */
export class AppThemeApplier {
  /** 最近一次生效的强调色（'' = 未设置，modifier 回退静态令牌） */
  private static currentAccent: string = '';

  /**
   * 当前品牌色（供**无状态的 AttributeModifier** 取用）。
   *
   * 为什么用静态字段而不是让 modifier 读单例：`AttributeModifier` 是普通类，
   * 不在 ArkUI 的观察依赖图里，读 @Trace 不会触发重渲染；页面重建时 `new` 出的
   * modifier 会重新走 `applyNormalAttribute`，届时读静态值即为最新——因此在改色后
   * 需要页面重建（切换外观页返回、或系统深浅色切换）才刷新，属已知限制。
   */
  static brandColor(): ResourceColor {
    return AppThemeApplier.currentAccent.length > 0 ? AppThemeApplier.currentAccent : $r('app.color.qj_brand');
  }
  /**
   * 应用主题。
   *
   * @param presetId 主题包 id（空串 = 默认主题包）
   * @param accentHex 强调色 '#RRGGBB'（空串 = 用主题包基准色）
   * @returns 是否成功设置系统主题层（L4）；L3 一定被设置
   */
  static apply(presetId: string, accentHex: string): boolean {
    const theme: UiThemeManager = UiThemeManager.getInstance();
    theme.setPresetId(presetId);
    theme.setAccentColor(accentHex);
    AppThemeApplier.currentAccent = theme.effectiveAccent();
    const ok: boolean = AppThemeController.applyPreset(theme.presetId, theme.accentColor);
    Logger.info(DOMAIN, TAG, `theme applied: preset=${theme.presetId} accent=${theme.accentColor} systemLayer=${ok}`);
    return ok;
  }

  /** 只改强调色（外观页取色器确认时用）。 */
  static applyAccent(accentHex: string): boolean {
    const theme: UiThemeManager = UiThemeManager.getInstance();
    return AppThemeApplier.apply(theme.presetId, accentHex);
  }

  /** 只改主题包（外观页切换主题包时用；强调色保留为单点微调）。 */
  static applyPreset(presetId: string): boolean {
    const theme: UiThemeManager = UiThemeManager.getInstance();
    return AppThemeApplier.apply(presetId, theme.accentColor);
  }
}
