/**
 * @easystart/app-component 统一导出入口。
 *
 * 应用级组件公共包（§17.4 AppUI 档首个落地，v3.4）：
 * - feedback/：应用交互规范载体（SnackBar / Dialog / Sheet）
 * - layout/：应用页面分区规范（AppSection；v3.21 增 AppCard 卡片容器 + AppEmptyState 空态）
 * - form/：应用表单交互规范（AppFormField；v3.21 增 AppTextArea 多行 / AppSelectField 下拉 /
 *   AppSwitchRow 开关行 / AppRadioGroup 单选组 / AppCheckboxGroup 多选组）
 * - modifier/：应用样式 AttributeModifier 族（Button / Text，**分文件**——
 *   吸取 EasyMath ComponentStyles.ets 783 行单文件混 20+ modifier 的教训；
 *   v3.21 增 AppInputModifier 输入框 + AppIconButtonModifier 图标按钮）
 * - control/：主题化原生控件工厂（Toggle / Slider / Progress / Checkbox / Radio /
 *   Segment 两形态；v3.21 增 Counter 计数器）——把系统原生控件的选中 / 激活态统一
 *   收口到运行时 accent，补齐「自由页面原生控件不随强调色变色」的换肤缺口
 *   （设置页 HDS 开关走 HDS 原生范式，不在此列）
 *
 * 分界判据（§17「换一个 app 还能用吗」）：
 * 纯结构原语 → VitalUI（组织级 @quizzyjoy）；应用规范载体 → 本包（@easystart）。
 * @kit 触点全部经 @quizzyjoy/platform 再导出（F14），本包零直接 @kit import。
 */
export { AppSnackBar } from './src/main/ets/feedback/AppSnackBar';
export { AppDialog, DialogSemantic } from './src/main/ets/feedback/AppDialog';
export { AppSheetOptions, AppSheetContainer, AppSheetConfig } from './src/main/ets/feedback/AppSheet';
export { CommonDialog, DialogAction } from './src/main/ets/feedback/CommonDialog';
export { CommonButton, ButtonVariant } from './src/main/ets/control/CommonButton';
export { CommonTag, TagTone } from './src/main/ets/control/CommonTag';
export { ActionCard } from './src/main/ets/layout/ActionCard';
export { CommonToast } from './src/main/ets/feedback/CommonToast';
export { AppProgressDialog } from './src/main/ets/feedback/AppProgressDialog';
export { AppOverlay } from './src/main/ets/feedback/AppOverlay';
export { AppSection } from './src/main/ets/layout/AppSection';
export { AppCard } from './src/main/ets/layout/AppCard';
export { AppEmptyState } from './src/main/ets/layout/AppEmptyState';
export { AppHoverSplit } from './src/main/ets/layout/AppHoverSplit';
export { AppFormField } from './src/main/ets/form/AppFormField';
export { AppTextArea } from './src/main/ets/form/AppTextArea';
export { AppSelectField } from './src/main/ets/form/AppSelectField';
export { AppSwitchRow } from './src/main/ets/form/AppSwitchRow';
export { AppRadioGroup } from './src/main/ets/form/AppRadioGroup';
export { AppCheckboxGroup } from './src/main/ets/form/AppCheckboxGroup';
export {
  AppButtonPrimaryModifier,
  AppButtonSecondaryModifier,
  AppButtonGhostModifier,
  AppButtonDangerModifier
} from './src/main/ets/modifier/AppButtonModifier';
export {
  AppTextHeadlineModifier,
  AppTextTitleModifier,
  AppTextBodyModifier,
  AppTextCaptionModifier,
  AppTextDisplayModifier,
  AppTextColorModifier
} from './src/main/ets/modifier/AppTextModifier';
export { AppInputModifier } from './src/main/ets/modifier/AppInputModifier';
export { AppIconButtonModifier } from './src/main/ets/modifier/AppIconButtonModifier';
export { AppDividerModifier } from './src/main/ets/modifier/AppDividerModifier';
export { AppImageModifier } from './src/main/ets/modifier/AppImageModifier';
export { AppProgressModifier } from './src/main/ets/modifier/AppProgressModifier';
export { AppToggle } from './src/main/ets/control/AppToggle';
export { AppSlider } from './src/main/ets/control/AppSlider';
export { AppProgress } from './src/main/ets/control/AppProgress';
export { AppCheckbox } from './src/main/ets/control/AppCheckbox';
export { AppRadio } from './src/main/ets/control/AppRadio';
export { AppTabSegment, AppCapsuleSegment } from './src/main/ets/control/AppSegment';
export { AppCounter } from './src/main/ets/control/AppCounter';
export { AppLoadingProgress } from './src/main/ets/control/AppLoadingProgress';
export { AppGauge } from './src/main/ets/control/AppGauge';
export { AppSelect } from './src/main/ets/control/AppSelect';
export { AppSearch } from './src/main/ets/control/AppSearch';
export { CommonSearchBar } from './src/main/ets/control/CommonSearchBar';
export { AppRefresh } from './src/main/ets/control/AppRefresh';
export { AppBadge } from './src/main/ets/control/AppBadge';

/**
 * ArkUI 高级组件 SegmentButtonV2 的**数据类型转导出**（v3.27.1，F16/E6 口径）。
 *
 * 框架组件本体（AppTabSegment / AppCapsuleSegment）由本包封装；其 items 数据类型
 * `SegmentButtonV2Items` 一并转出，**上层（features / 入口）一律经本包取用**，
 * 勿裸引 `@ohos.arkui.advanced.SegmentButtonV2`——features 层零 @ohos/@kit 纪律。
 */
export { SegmentButtonV2Items } from '@ohos.arkui.advanced.SegmentButtonV2';

export { AppThemeApplier } from './src/main/ets/theme/AppThemeApplier';
