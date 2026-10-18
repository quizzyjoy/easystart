import { MotionSpec } from '../motion/MotionSpec';

/**
 * 预置动效集合。
 *
 * 页面与组件只允许引用这里的动效，不允许就地写 TransitionEffect / animateTo。
 * 覆盖：列表增删、页面转场、加载态。
 */
export class MotionEffects {
  /** 列表项增删过渡 */
  static listItem(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect.OPACITY.animation({
        duration: MotionSpec.DURATION_NORMAL,
        curve: MotionSpec.CURVE_LIST
      }),
      TransitionEffect.OPACITY.animation({
        duration: MotionSpec.DURATION_FAST,
        curve: MotionSpec.CURVE_EXIT
      })
    );
  }

  /** 页面级转场（配合 router / 半模态使用） */
  static pageTransition(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect.OPACITY.animation({
        duration: MotionSpec.DURATION_SLOW,
        curve: MotionSpec.CURVE_ENTER
      }),
      TransitionEffect.OPACITY.animation({
        duration: MotionSpec.DURATION_NORMAL,
        curve: MotionSpec.CURVE_EXIT
      })
    );
  }

  /** 标准出现动画参数，供 animateTo 使用 */
  static appearParam(): AnimateParam {
    return {
      duration: MotionSpec.DURATION_NORMAL,
      curve: MotionSpec.CURVE_ENTER
    };
  }
}
