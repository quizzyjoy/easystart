/**
 * @easystart/widget-common 统一导出入口。
 *
 * 服务卡片数据域（v3.27，指南 §17.5「卡片公共 → WidgetCommon（首个真实需求出现时建包）」落地）：
 * - 卡片展示数据组装（两条读取路径按进程选择：卡片进程同步 + dropCache / UI 进程异步链）
 * - formId → 规格注册表（独立偏好文件；卡片进程写、UI 进程丢缓存读）
 *
 * **边界**：本包只做「数据」——**不引 `@kit.FormKit`**（`formBindingData` /
 * `formProvider` 等调用一律留在 product 入口层的能力里）。
 * 依赖 `@quizzyjoy/platform`（偏好读写 + i18n 24 小时制查询）与
 * `@easystart/app-preferences`（键名契约），因此卡片数据逻辑被
 * entry / entry_pc / entry_wearable 三入口共享，避免三份拷贝漂移。
 */
export { CardLayout, CardViewData, CardPayloadKeys, toCardPayload } from './src/main/ets/card/CardViewData';
export { buildWidgetCardData, buildWidgetCardDataAsync } from './src/main/ets/card/WidgetCardBuilder';
export { WidgetFormEntry, WidgetFormRegistry } from './src/main/ets/card/WidgetFormRegistry';
