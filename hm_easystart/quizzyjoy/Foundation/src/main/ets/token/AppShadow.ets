/**
 * 阴影刻度（官方 ShadowStyle 预设 + 原始数值表）。
 *
 * v3.0 新增。与 OpenHarmony 官方系统资源表对表：
 * default 族 xs/sm/md/lg（blur 20/40/60/100，offsetY 0/10/10/20）、
 * floating 族 sm/md（blur 120/160，offsetY 0）；深浅模式同值（阴影不随模式变）。
 *
 * 首选消费：`.shadow(AppShadow.SM)`（系统预设，等效官方 default_sm）；
 * 自定义组合时用 BLUR_ 与 OFFSET_Y_ 前缀的原始值 + $r('app.color.app_shadow')。
 *
 * 克制律：同一屏 ≤2 档阴影；TV 形态弱化（靠描边与亮度分层）。
 */
export class AppShadow {
  /** 静态微影（卡片默认）。 */
  static readonly XS: ShadowStyle = ShadowStyle.OUTER_DEFAULT_XS;
  /** 悬浮卡 / 下拉。 */
  static readonly SM: ShadowStyle = ShadowStyle.OUTER_DEFAULT_SM;
  /** 对话框。 */
  static readonly MD: ShadowStyle = ShadowStyle.OUTER_DEFAULT_MD;
  /** 全屏模态。 */
  static readonly LG: ShadowStyle = ShadowStyle.OUTER_DEFAULT_LG;
  /** 浮动按钮 / 气泡。 */
  static readonly FLOAT_SM: ShadowStyle = ShadowStyle.OUTER_FLOATING_SM;
  /** Toast / 悬浮预览。 */
  static readonly FLOAT_MD: ShadowStyle = ShadowStyle.OUTER_FLOATING_MD;

  /** 原始 blur 值（vp），自定义 ShadowOptions 用。 */
  static readonly BLUR_XS: number = 20;
  static readonly BLUR_SM: number = 40;
  static readonly BLUR_MD: number = 60;
  static readonly BLUR_LG: number = 100;
  static readonly BLUR_FLOAT_SM: number = 120;
  static readonly BLUR_FLOAT_MD: number = 160;

  /** 原始 offsetY 值（vp）。 */
  static readonly OFFSET_Y_XS: number = 0;
  static readonly OFFSET_Y_SM: number = 10;
  static readonly OFFSET_Y_MD: number = 10;
  static readonly OFFSET_Y_LG: number = 20;
}
