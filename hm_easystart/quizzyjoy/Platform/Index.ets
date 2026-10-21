/**
 * @quizzyjoy/platform 统一导出入口。
 *
 * 平台能力层（跨应用通用 HAR 能力域）：**换一个 app 还能用的系统能力**在此复用。
 * 环境状态（断点/窗口/屏幕/设备形态/颜色模式/能力/兼容）与
 * 系统能力服务（网络/存储/权限/国际化/震动）都在本层封装。
 * 依赖 foundation；禁止出现业务语义；监听型能力一律 attach 与 detach 成对调用。
 * 纪律：跨应用通用的脆弱系统能力收敛于此（F14）；应用特定决策（带应用语义的系统调用）
 * 落应用级；类型/稳定工具 import 各层放开（v3.8）。
 */
export { window, UIContext, ComponentContent } from '@kit.ArkUI';
export { common } from '@kit.AbilityKit';
export {
  AppThemeController,
  CustomColors,
  CustomDarkColors,
  CustomTheme,
  Theme
} from './src/main/ets/theme/AppThemeController';
export { ErrorMapper } from './src/main/ets/error/ErrorMapper';
export { GlobalErrorHandler, ErrorReporter } from './src/main/ets/error/GlobalErrorHandler';
export { BreakpointType, BreakpointConstants } from './src/main/ets/breakpoint/BreakpointConstants';
export { BreakpointManager } from './src/main/ets/breakpoint/BreakpointManager';
export { WindowAdapter } from './src/main/ets/window/WindowAdapter';
export { OrientationManager, AppOrientation, AppOrientationStrategy } from './src/main/ets/window/OrientationManager';
export { HoverStore, HoverData, HoverListener, AppFoldStatus } from './src/main/ets/hover/HoverStore';
export { ShareHelper, ShareOptions } from './src/main/ets/share/ShareHelper';
export { MarketHelper } from './src/main/ets/market/MarketHelper';
export { AppLauncher, LaunchResult } from './src/main/ets/market/AppLauncher';
export { PrivacyLinks } from './src/main/ets/market/PrivacyLinks';
export { StoreProductView } from './src/main/ets/market/StoreProductView';
export { SelfSignature, SelfSignatureReader } from './src/main/ets/market/SelfSignature';
export {
  AppGalleryHelper,
  StoreCapabilityResult,
  StoreDynamicIcon,
  StorePrivacyKind,
  StorePrivacyLink,
  StorePrivacyLinkSnapshot,
  StorePrivacyRecord,
  StorePrivacySnapshot,
  StorePrivacyState,
  StoreSkill
} from './src/main/ets/market/AppGalleryHelper';
export { systemShare } from '@kit.ShareKit';
export { ScreenManager } from './src/main/ets/screen/ScreenManager';
export { HapticManager } from './src/main/ets/haptic/HapticManager';
export { ColorModeManager, AppColorMode } from './src/main/ets/theme/ColorModeManager';
export { SystemAppearanceManager } from './src/main/ets/theme/SystemAppearanceManager';
export { CapabilityManager } from './src/main/ets/capability/CapabilityManager';
export { FeatureGate, FeatureRequirement, GateResult, GateStatus } from './src/main/ets/capability/FeatureGate';
export { AppEnvManager, AppEnvSnapshot } from './src/main/ets/device/AppEnvManager';
export { DeviceType, FormFactor, DeviceManager } from './src/main/ets/device/FormFactor';
export { CompatManager } from './src/main/ets/compat/CompatManager';
export { UiMetrics } from './src/main/ets/ui/UiMetrics';
export { RouterManager } from './src/main/ets/router/RouterManager';
export { NetworkMonitor, NetworkStatus } from './src/main/ets/network/NetworkMonitor';
export { PreferencesStore } from './src/main/ets/storage/PreferencesStore';
export { CacheManager } from './src/main/ets/storage/CacheManager';
export { PermissionHelper } from './src/main/ets/permission/PermissionHelper';
export { I18nManager, LangType } from './src/main/ets/i18n/I18nManager';
