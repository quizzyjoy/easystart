/**
 * @quizzyjoy/vitalui 统一导出入口。
 *
 * 纯表现层：依赖 @quizzyjoy/foundation（数值令牌与日志）与 AppScope 颜色令牌（$r），
 * 零 @kit 导入（Toast 实现由入口 Ability 注入），不依赖 platform / 业务。
 * 运行时主题通过 @Param accentColor 注入（空串 = 用令牌），组件不持有全局单例。
 */
export { MotionSpec } from './src/main/ets/motion/MotionSpec';
export { MotionEffects } from './src/main/ets/motion/MotionEffects';
export { SizeLevel, ViewState, FeedbackText } from './src/main/ets/component/CommonTypes';
export { ActionCard } from './src/main/ets/component/ActionCard';
export { SkeletonBlock } from './src/main/ets/component/SkeletonBlock';
export { StateContainer } from './src/main/ets/component/StateContainer';
export { CommonButton, ButtonVariant } from './src/main/ets/component/CommonButton';
export { CommonTag, TagTone } from './src/main/ets/component/CommonTag';
export { RefreshList, ListStatus } from './src/main/ets/component/RefreshList';
export { ColorMath, Rgb, Hsl } from './src/main/ets/util/ColorMath';
export {
  CommonColorPicker,
  ColorPickerTabType,
  ColorPickerOptions
} from './src/main/ets/component/CommonColorPicker';
export { CommonColorPickerSheet } from './src/main/ets/component/CommonColorPickerSheet';
export { ChartEntry, ChartSeries, ChartPalette, ChartStyle } from './src/main/ets/chart/ChartData';
export { RoseChart } from './src/main/ets/chart/RoseChart';
export { QuarterRoseChart } from './src/main/ets/chart/QuarterRoseChart';
export { PieChart } from './src/main/ets/chart/PieChart';
export { RadarChart } from './src/main/ets/chart/RadarChart';
export { CommonLoading, LoadingVariant } from './src/main/ets/component/CommonLoading';
export { UiThemeManager } from './src/main/ets/theme/UiThemeManager';
