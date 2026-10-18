/**
 * @easystart/demo-feature 统一导出入口。
 *
 * 基建演示聚合域（§3.1 示范域定位）：组件画廊 + 6 个场景级样例子页
 * （v3.9-v3.10，可整体复制的页面范式）+ 设备能力面板等模板自检视图。
 * 【fork 必删】本包不含任何业务语义，fork 后整包删除并清理入口引用
 * （快速启动 §10 第 10 步）；真实 feature 请照 HomeFeature 的 MVVM 结构新建。
 */
export { ComponentGalleryView } from './src/main/ets/view/ComponentGalleryView';
export { DeviceCapabilityView } from './src/main/ets/view/DeviceCapabilityView';
export { DemoSample } from './src/main/ets/view/DemoSample';
export { DesignTokensView } from './src/main/ets/view/DesignTokensView';
export { FeedbackFlowView } from './src/main/ets/view/FeedbackFlowView';
export { ChartsDashboardView } from './src/main/ets/view/ChartsDashboardView';
export { FormSampleView } from './src/main/ets/view/FormSampleView';
export { ListStateView } from './src/main/ets/view/ListStateView';
export { SearchView } from './src/main/ets/view/SearchView';
export { HoverSplitView } from './src/main/ets/view/HoverSplitView';
