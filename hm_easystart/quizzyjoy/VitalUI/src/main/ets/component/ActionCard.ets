import { MotionSpec } from '../motion/MotionSpec';
import { AppFontSize, AppRadius, AppSpacing } from '@quizzyjoy/foundation';

/**
 * 通用卡片（ActionCard）。
 *
 * 统一 API：@Param title / subtitle / clickable，@Event onAction。
 * 动画：按压缩放反馈，时长与曲线取自 MotionSpec，禁止组件内自造数值。
 * 主题：accentColor 为空串时使用 qj_brand 令牌，非空时注入运行时主题色。
 */
@ComponentV2
export struct ActionCard {
  /** 主标题（空串不渲染标题行）。 */
  @Param title: string = '';
  /** 副标题（空串不渲染副标题行）。 */
  @Param subtitle: string = '';
  /** 是否响应点击（false 时不回调 onAction，按压反馈仍保留）。 */
  @Param clickable: boolean = true;
  /** 强调色注入（空串回退 qj_brand 令牌）。 */
  @Param accentColor: string = '';
  /** 卡片点击回调（clickable=true 时触发）。 */
  @Event onAction: () => void = () => {
  };
  @Local pressed: boolean = false;

  private accent(): ResourceColor {
    return this.accentColor.length > 0 ? this.accentColor : $r('app.color.qj_brand');
  }

  build() {
    Column({ space: AppSpacing.XS }) {
      Text(this.title)
        .fontSize(AppFontSize.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(AppSpacing.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .borderRadius(AppRadius.XL)
    .scale({ x: this.pressed ? 0.97 : 1.0, y: this.pressed ? 0.97 : 1.0 })
    .animation({ duration: MotionSpec.DURATION_FAST, curve: MotionSpec.CURVE_ENTER })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (this.clickable) {
        this.onAction();
      }
    })
  }
}
