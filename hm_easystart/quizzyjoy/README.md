# quizzyjoy/ —— 跨 App 共享三库（@quizzyjoy/*）

本目录是 **quizzyjoy 组织级、跨 app 复用的三个 HAR**，与应用私有层 `commons/`（`@easystart/*`）物理隔离：

| 模块 | 包名 | 职责 | 边界 |
|---|---|---|---|
| `Foundation/` | `@quizzyjoy/foundation` | 工程基础原语：日志、异常、Result、断言、脱敏、数值/响应式令牌 | 零依赖；**零 `@ohos/@kit` 导入**（LocalUnit 可测） |
| `Platform/` | `@quizzyjoy/platform` | 脆弱系统能力的唯一包装层：断点、主题、设备/形态、网络、存储、权限、i18n、路由、窗口、震动、分享等 | 仅依赖 foundation |
| `VitalUI/` | `@quizzyjoy/vitalui` | 通用组件、动效规范、主题管理（Canvas 图表、取色器、Loading 等） | 仅依赖 foundation；零脆弱系统能力直调 |

## 修改权纪律（2026-10-08 用户裁定，2026-10-08 目录隔离强化）

**这三个库是跨项目级资产，任何 fork 出的应用工程（hm_easytools、hm_partynow 及后续 app）只消费、无权修改：**

1. **未经授权不得修改**——不新增文件、不改既有文件、不在 `Index.ets` 加导出、不改构建配置。
2. **唯一修改通道是本上游工程 趣开发 EasyStart 的模板轮次**：缺陷修复与能力增强以 `@quizzyjoy/*` 版本演进统一发布，各 app 按上游同步轮次整体更新，不在应用仓就地改。
3. **应用侧需求落位**（应用需要而三大件未提供的能力）：
   - 单一 feature 使用 → feature 域内 `util/`（域内为主）；
   - 本 app 多 feature 复用 → 建应用级 Common 包 `@<应用名>/common`（与 `AppCommon` 平级，可依赖三大件）；
   - 确认跨 app 复用的工程原语 → **提上游轮次**进本目录，不得在 fork 副本先行修改。
4. **违例判别**：应用仓中 `git diff` 触及本目录对应副本（`quizzyjoy/{Foundation,Platform,VitalUI}`）的提交即为越权（上游同步轮次的整体对齐除外）。

> 包名前缀即复用边界：`@quizzyjoy/` 前缀的包换一个 app 仍可原样使用；`@easystart/*`（`commons/`）包含模板工程自身的装配决策，fork 时应替换为新应用作用域。
>
> 完整条款见 PartyNow `docs/鸿蒙工程目录设计指南.md` §12.3「包命名规范 · 三库修改权 · 落位四档判据」。
