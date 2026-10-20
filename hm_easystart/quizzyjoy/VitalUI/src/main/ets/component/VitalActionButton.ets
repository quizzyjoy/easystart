import { UiThemeManager } from '../theme/UiThemeManager';
import { AppRadius, AppSpacing, AppFontSize, AppStroke, AppSize } from '@quizzyjoy/foundation';
import { MotionSpec } from '../motion/MotionSpec';

/**
 * VitalUI 内部按钮原语（**不对外导出**）。
 *
 * 为什么留在 VitalUI：本库的 `CommonColorPickerSheet` / `StateContainer` / `RefreshList`
 * 需要在自身内部放「确定 / 取消 / 重试」这类按钮，而 VitalUI 不能反向依赖
 * `@easystart/app-component`（依赖方向是 AppComponent → VitalUI）。
 *
 * 与应用级 `CommonButton`（已迁至 AppComponent）的分工：
 * - 本原语：只覆盖 VARIANT 三档 + 主题色，供库内组件自用，API 故意收窄；
 * - `CommonButton`：应用级按钮，额外提供 loading / fullWidth / 自定义高度 / 危险档，
 *   页面与业务一律用它，不要用本原语。
 */
export enum VitalActionVariant {
  PRIMARY = 'primary',
  SECONDARY = 'secondary',
  TEXT = 'text'
}

/**
 * VitalUI 内部按钮（描边 / 实心 / 文字三档）。
 */
@ComponentV2
export struct VitalActionButton {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local pressed: boolean = false;

  /** 文案。 */
  @Param text: ResourceStr = '';
  /** 视觉档位。 */
  @Param variant: VitalActionVariant = VitalActionVariant.PRIMARY;
  /** 是否禁用。 */
  @Param disabled: boolean = false;
  /** 运行时主题色（空串 = 主题包基准色）。 */
  @Param accentColor: string = '';
  /** 点击回调。 */
  @Event onAction: () => void = () => {
  };

  private accent(): ResourceColor {
    return this.accentColor.length > 0 ? this.accentColor : this.theme.brandColor();
  }

  private bgColor(): ResourceColor {
    if (this.disabled) {
      return $r('app.color.app_button_disabled_bg');
    }
    return this.variant === VitalActionVariant.PRIMARY ? this.accent() : Color.Transparent;
  }

  private fgColor(): ResourceColor {
    if (this.disabled) {
      return $r('app.color.app_button_disabled_fg');
    }
    if (this.variant === VitalActionVariant.SECONDARY) {
      return this.accent();
    }
    if (this.variant === VitalActionVariant.TEXT) {
      return $r('app.color.app_text_primary');
    }
    return this.accentColor.length > 0 ? Color.White : $r('app.color.qj_on_brand');
  }

  build() {
    Row() {
      Text(this.text)
        .fontSize(AppFontSize.BODY)
        .fontColor(this.fgColor())
        .fontWeight(FontWeight.Medium)
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
    .height(AppSize.TOUCH_MIN)
    .backgroundColor(this.bgColor())
    .borderRadius(AppRadius.XXL)
    .border(this.variant === VitalActionVariant.SECONDARY
      ? { width: AppStroke.THIN, color: this.accent() } : { width: 0 })
    .opacity(this.disabled ? 0.6 : 1)
    .scale({ x: this.pressed ? 0.96 : 1.0, y: this.pressed ? 0.96 : 1.0 })
    .animation({ duration: MotionSpec.DURATION_FAST, curve: MotionSpec.CURVE_ENTER })
    .onTouch((event: TouchEvent) => {
      if (this.disabled) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (this.disabled) {
        return;
      }
      this.onAction();
    })
  }
}
