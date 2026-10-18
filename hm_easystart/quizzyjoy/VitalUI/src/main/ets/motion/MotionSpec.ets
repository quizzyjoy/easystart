/**
 * 全工程动效时长与曲线常量。
 *
 * 统一动效语言是"看起来像一个产品"的前提：禁止各页面自造时长与曲线。
 * 时长参考：短反馈 150ms、常规 250ms、大范围转场 350ms。
 */
export class MotionSpec {
  /** 即时反馈：按钮按下、勾选 */
  static readonly DURATION_FAST: number = 150;
  /** 常规动画：卡片展开、列表增删 */
  static readonly DURATION_NORMAL: number = 250;
  /** 转场动画：页面切换、大范围布局变化 */
  static readonly DURATION_SLOW: number = 350;
  /** 循环动画：Loading 旋转 / 呼吸 / 扫掠（iterations: -1 专用） */
  static readonly DURATION_LOOP: number = 800;

  /** 标准缓动：进入 */
  static readonly CURVE_ENTER: Curve = Curve.Friction;
  /** 标准缓动：退出 */
  static readonly CURVE_EXIT: Curve = Curve.FastOutSlowIn;
  /** 强调缓动：锐利收尾（Curve.Sharp 并非弹簧曲线；真弹簧需 @ohos.curves springCurve） */
  static readonly CURVE_SPRING: Curve = Curve.Sharp;

  /** 列表项增删的统一插值曲线 */
  static readonly CURVE_LIST: Curve = Curve.Friction;
}
