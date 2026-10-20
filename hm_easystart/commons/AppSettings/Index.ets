/**
 * @easystart/app-settings 统一导出入口。
 *
 * 应用级公共·设置域（§3.1）：v3.28 起设置域目的地经 SettingsDestination
 * 统一装配（视图 + titleBar + 沉浸避让域内收口，TODO-019），入口 pageMap
 * 只保留一个 isSettingsRoute 分支；本包同时保留各路由页的独立导出，
 * 供 fork 需要自定义装配时单独引用。
 *
 * 导出面纪律：路由目的地页面 + 装配组件对外导出；model / viewmodel /
 * component / section 为域内私有，不对外导出。依赖 Foundation/Platform/
 * VitalUI；手表入口不依赖本包。
 */
export { SettingsDestination } from './src/main/ets/view/SettingsDestination';
export { isSettingsRoute, SettingsRoute } from './src/main/ets/model/SettingsRoute';
export { SettingsView } from './src/main/ets/view/SettingsView';
export { AppearanceView } from './src/main/ets/view/AppearanceView';
export { GeneralView } from './src/main/ets/view/GeneralView';
export { AnnouncementView } from './src/main/ets/view/AnnouncementView';
export { VersionLogView } from './src/main/ets/view/VersionLogView';
export { HelpFeedbackView } from './src/main/ets/view/HelpFeedbackView';
export { DeveloperView } from './src/main/ets/view/DeveloperView';
export { AboutView } from './src/main/ets/view/about/AboutView';
export { PolicyView } from './src/main/ets/view/about/PolicyView';
export { LicenseView } from './src/main/ets/view/about/LicenseView';
