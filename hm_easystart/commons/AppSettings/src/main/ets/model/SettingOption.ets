import { AppColorMode } from '@quizzyjoy/platform';

/**
 * 设置项枚举与取值（v3.13，TODO-003）。
 *
 * 只放「值」与顺序；显示标签（ResourceStr）在各 Section 内以 $r 资源组装，
 * model 不碰 UI 资源，保持纯数据。
 */

/** 显示模式选项（顺序即设置行 Select 中的顺序；值对齐 AppColorMode）。 */
export class SettingDisplayMode {
  static readonly VALUES: AppColorMode[] =
    [AppColorMode.SYSTEM, AppColorMode.LIGHT, AppColorMode.DARK];
}

/** 应用语言选项（'' = 跟随系统，落库值；传给系统时 '' 映射为 'default'）。 */
export class SettingLanguage {
  static readonly FOLLOW_SYSTEM: string = '';
  static readonly ZH_HANS: string = 'zh-Hans';
  static readonly EN_US: string = 'en-US';
  static readonly VALUES: string[] =
    [SettingLanguage.FOLLOW_SYSTEM, SettingLanguage.ZH_HANS, SettingLanguage.EN_US];
}

/** 屏幕方向选项（顺序即设置行 Select 中的顺序；v3.14 收口自 DemoFeature 锁方向按钮）。 */
export class SettingOrientation {
  /** 跟随系统（AUTO_ROTATION_UNSPECIFIED：随系统自动旋转设置、受控制中心旋转锁约束；OrientationManager.unlock）。 */
  static readonly AUTO: number = 0;
  /** 锁定竖屏（lockPortrait）。 */
  static readonly PORTRAIT: number = 1;
  /** 锁定横屏（lockLandscape）。 */
  static readonly LANDSCAPE: number = 2;
  static readonly VALUES: number[] =
    [SettingOrientation.AUTO, SettingOrientation.PORTRAIT, SettingOrientation.LANDSCAPE];
}

/**
 * 政策文本子页类型（AppRoute.POLICY 的 param）。 */
export type PolicyKind = 'privacy' | 'terms';
