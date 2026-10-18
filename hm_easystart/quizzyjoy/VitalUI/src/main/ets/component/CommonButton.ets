import { AppRadius, AppSpacing, AppFontSize, AppStroke, AppSize } from '@quizzyjoy/foundation';
import { MotionSpec } from '../motion/MotionSpec';

/** 加载指示器（内嵌菊花）边长（vp）——介于 ICON_LG(24) 与 ICON_MD(20) 之间的视觉适配值，命名保形。 */
const LOADING_INDICATOR_SIZE: number = 18;

/** 按钮视觉变体。 */
export enum ButtonVariant {
  /** 主操作：品牌色实心。 */
  PRIMARY = 'primary',
  /** 次操作：描边。 */
  SECONDARY = 'secondary',
  /** 弱操作：纯文字。 */
  TEXT = 'text',
  /** 危险操作：警示色。 */
  DANGER = 'danger'
}

/**
 * CommonButton —— 统一按钮组件。
 *
 * 覆盖状态：normal / pressed（缩放）/ disabled（专用禁用色）/ loading（内嵌菊花）。
 * 主题：颜色全部走 $r('app.color.qj_*')；accentColor 非空时注入运行时主题色。
 * 动效：按压缩放取自 MotionSpec。
 */
@ComponentV2
export struct CommonButton {
  /** 按钮文案。 */
  @Param text: ResourceStr = '';
  /** 视觉变体。 */
  @Param variant: ButtonVariant = ButtonVariant.PRIMARY;
  /** 是否禁用。 */
  @Param disabled: boolean = false;
  /** 是否加载中（加载中自动禁用点击）。 */
  @Param loading: boolean = false;
  /** 是否撑满父宽。 */
  @Param fullWidth: boolean = false;
  /** 自定义高度（vp，默认 AppSize.TOUCH_MIN=40，官方点击热区红线）。 */
  @Param buttonHeight: number = AppSize.TOUCH_MIN;
  /** 运行时主题色（空串 = 使用 qj_brand 令牌）。 */
  @Param accentColor: string = '';
  /** 点击回调。 */
  @Event onAction: () => void = () => {
  };

  @Local pressed: boolean = false;

  private accent(): ResourceColor {
    return this.accentColor.length > 0 ? this.accentColor : $r('app.color.qj_brand');
  }

  private bgColor(): ResourceColor {
    if (this.disabled) {
      return $r('app.color.app_button_disabled_bg');
    }
    if (this.variant === ButtonVariant.DANGER) {
      return $r('app.color.app_danger');
    }
    if (this.variant === ButtonVariant.PRIMARY) {
      return this.accent();
    }
    return Color.Transparent;
  }

  private fgColor(): ResourceColor {
    if (this.disabled) {
      return $r('app.color.app_button_disabled_fg');
    }
    if (this.variant === ButtonVariant.SECONDARY) {
      return this.accent();
    }
    if (this.variant === ButtonVariant.TEXT) {
      return $r('app.color.app_text_primary');
    }
    if (this.variant === ButtonVariant.PRIMARY) {
      return this.accentColor.length > 0 ? Color.White : $r('app.color.qj_on_brand');
    }
    return Color.White;
  }

  build() {
    Row({ space: AppSpacing.SM }) {
      if (this.loading) {
        LoadingProgress()
          .width(LOADING_INDICATOR_SIZE)
          .height(LOADING_INDICATOR_SIZE)
          .color(this.fgColor())
      }
      Text(this.text)
        .fontSize(AppFontSize.BODY)
        .fontColor(this.fgColor())
        .fontWeight(FontWeight.Medium)
    }
    .justifyContent(FlexAlign.Center)
    .width(this.fullWidth ? '100%' : undefined)
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
    .height(this.buttonHeight)
    .backgroundColor(this.bgColor())
    .borderRadius(AppRadius.XXL)
    .border(this.variant === ButtonVariant.SECONDARY
      ? { width: AppStroke.THIN, color: this.accent() } : { width: 0 })
    .opacity(this.disabled ? 0.6 : 1)
    .scale({ x: this.pressed ? 0.96 : 1.0, y: this.pressed ? 0.96 : 1.0 })
    .animation({ duration: MotionSpec.DURATION_FAST, curve: MotionSpec.CURVE_ENTER })
    .onTouch((event: TouchEvent) => {
      if (this.disabled || this.loading) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (this.disabled || this.loading) {
        return;
      }
      this.onAction();
    })
  }
}
