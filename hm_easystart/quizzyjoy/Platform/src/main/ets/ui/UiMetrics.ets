import { LengthMetrics } from '@kit.ArkUI';

/**
 * ArkUI 尺寸值工厂。
 *
 * 【零 @kit 纪律】本类只是「构造 LengthMetrics 运行时值」的跨应用通用便捷工厂：
 * features / VitalUI 需要 LengthMetrics **运行时值**时经本工厂构造，
 * 而 LengthMetrics / FlexSpaceOptions 作为全局环境类型可直接引用、无需导入。
 */
export class UiMetrics {
  /** 构造 vp 单位的 LengthMetrics。 */
  static vp(value: number): LengthMetrics {
    return LengthMetrics.vp(value);
  }

  /** 构造 main / cross 相同的 Flex 间距（FlexOptions.space 专用）。 */
  static uniformFlexSpace(vpValue: number): FlexSpaceOptions {
    return { main: LengthMetrics.vp(vpValue), cross: LengthMetrics.vp(vpValue) };
  }
}
