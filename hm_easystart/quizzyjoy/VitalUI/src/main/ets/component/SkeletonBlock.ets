import { MotionSpec } from '../motion/MotionSpec';
import { AppRadius, AppSpacing } from '@quizzyjoy/foundation';

/**
 * 骨架屏占位块（SkeletonBlock）。
 *
 * 动画：透明度呼吸，用于加载态，避免页面在数据到达前出现空白跳动。
 */
@ComponentV2
export struct SkeletonBlock {
  /** 占位块宽度（Length，默认占满父宽）。 */
  @Param widthValue: Length = '100%';
  /** 占位块高度（vp，默认 AppSpacing.LG=16 即正文行视觉档）。 */
  @Param heightValue: Length = AppSpacing.LG;
  /** 圆角（vp）。 */
  @Param radius: number = AppRadius.MD;
  @Local private dim: boolean = false;

  aboutToAppear(): void {
    this.dim = true;
  }

  build() {
    Row()
      .width(this.widthValue)
      .height(this.heightValue)
      .borderRadius(this.radius)
      .backgroundColor($r('app.color.app_skeleton'))
      .opacity(this.dim ? 0.45 : 1.0)
      .animation({
        duration: MotionSpec.DURATION_SLOW * 2,
        curve: Curve.Linear,
        iterations: -1,
        playMode: PlayMode.Alternate
      })
  }
}
