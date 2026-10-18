/**
 * @easystart/home-feature 统一导出入口。
 *
 * 业务特性层·MVVM 三分包示范（v3.3 收缩后仅存首页列表域）：
 * view / viewmodel / data 的结构样板，fork 后整包替换为真实 feature。
 * 只导出「视图组件 + ViewModel + 数据模型」，
 * 页面装配（Tab / 导航 / @Entry）一律放 product 入口模块。
 * 本层可依赖全部 commons，禁止被 commons 反向依赖。
 */
export { HomeRepository, HomeItem, HomeTarget } from './src/main/ets/data/HomeRepository';
export { HomeViewModel } from './src/main/ets/viewmodel/HomeViewModel';
export { HomeListView } from './src/main/ets/view/HomeListView';
export { HomeDetailView } from './src/main/ets/view/HomeDetailView';
