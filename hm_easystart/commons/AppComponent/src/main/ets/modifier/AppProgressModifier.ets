import { AppThemeApplier } from '../theme/AppThemeApplier';

/**
 * 应用级进度条 AttributeModifier（v3.21，简单换色封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Progress 是系统结构原语，其进度色 / 轨道底色是应用样式决策——本 modifier 提供
 * 「可传色的简单封装」（默认进度 qj_brand + 轨道 app_fill_medium），方便调用方按
 * 语义换色（如成功进度 / 警告进度）。与 AppProgress 组件的关系：AppProgress 是
 * 「绑运行时强调色」的控件工厂件；本 modifier 是「显式传色」的简单样式件，
 * 供需要固定语义色（非运行时换肤）的场景。
 *
 * 【用法】Progress({ value: 60, total: 100 }).attributeModifier(new AppProgressModifier())
 *         Progress({ value: 60, total: 100 })
 *           .attributeModifier(new AppProgressModifier($r('app.color.app_success')))
 *
 * 【@kit 纪律】AttributeModifier / ProgressAttribute 为全局类型，零 @kit。
 */
export class AppProgressModifier implements AttributeModifier<ProgressAttribute> {
  /** 进度色（默认 qj_brand 令牌）。 */
  color: ResourceColor;
  /** 轨道底色（默认 app_fill_medium 令牌）。 */
  backgroundColor: ResourceColor;

  constructor(color: ResourceColor = AppThemeApplier.brandColor(),
    backgroundColor: ResourceColor = $r('app.color.app_fill_medium')) {
    this.color = color;
    this.backgroundColor = backgroundColor;
  }

  applyNormalAttribute(instance: ProgressAttribute): void {
    instance.color(this.color)
      .backgroundColor(this.backgroundColor);
  }
}
