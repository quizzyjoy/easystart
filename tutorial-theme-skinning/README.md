# HarmonyOS 完整换肤系统：从「只变一半」到四层颜色模型

> 一本写给 fork 者的实战教程。全部结论来自 **EasyStart 模板仓**（仓根 `D:\Project\EasyStart`，工程根 `hm_easystart/`）的真实代码与真机截图，不含臆造 API。

- 教程目录：`tutorial-theme-skinning/`（本目录）
- 对应工程：`hm_easystart/`（版本线 v3.43 → v3.46，versionCode 1000029–1000031）
- 截图目录：`tutorial-theme-skinning/assets/`（16 张真机截图已随教程入库，clone 后可直接显示）
- 适用读者：已能写 ArkTS/ArkUI 页面，想让「换主题」贯穿全应用（含系统组件与 HDS 组件）的开发者

---

## 一、这套教程解决什么问题

大多数鸿蒙应用的「换肤」最终都长这样：设置页改完颜色，回到首页——卡片图标还是蓝的、对话框按钮还是蓝的、设置页开关还是蓝的。开发者以为是自己漏改了某处，于是开始全仓搜索 `qj_brand`，越改越乱。

根因不是「漏改」，而是**颜色有四个互相独立的来源**，只动其中一个，必然只变一部分：

| 层 | 机制 | 谁在决定颜色 | 只改这一层时的表现 |
|---|---|---|---|
| **L1 静态令牌** | `$r('app.color.qj_*')` + `resources/dark` 限定词 | 资源编译器（编译期固化） | 只随深浅色变，不随主题变 |
| **L2 AttributeModifier** | `AttributeModifier` 族（无状态类） | 类里写死的值 | 完全不参与运行时换色 |
| **L3 运行时主题** | `UiThemeManager`（`@ObservedV2` 单例 + `@Trace`） | 运行时单例 | 只有「接了注入口」的组件会变 |
| **L4 系统组件默认色** | `ThemeControl.setDefaultTheme(CustomTheme)` | ArkUI 全局 token 表 | 不设则系统组件永远是系统蓝 |

本教程的主线就是把这四层**依次建起来、按正确顺序编排、并用真机截图逐层取证**，同时把 9 个实测踩过的坑写成「问题 → 现象 → 正解」。

---

## 二、两级目录

> 一级 = 篇章（Part），二级 = 章节。章节链接使用每章顶部的稳定锚点（`#ch01`…`#ch13`，不受标题改动影响）；章内另设小节标题作为二级定位。

### 第一部分 · 认知：先看清断在哪

1. **[第 1 章 换肤只变一半的真相：四层颜色模型](./01-four-layer-model.md#ch01)**
   职责：用一张图 + 一次真机对照，建立「四层」心智模型，说明为什么必须四层而不是一个大 token 表。
   成稿目标字数：2200–3000

2. **[第 2 章 全仓取证：把「注入面」量出来](./02-audit-injection-surface.md#ch02)**
   职责：教一套可复现的取证方法（递归计数而非抽样），量出「硬引用 / 注入面 / 口号与实现的漂移」。
   成稿目标字数：2000–2800

### 第二部分 · 建层：四层各自怎么落

3. **[第 3 章 L1 静态令牌：哪些该跟主题，哪些永远不跟](./03-l1-static-tokens.md#ch03)**
   职责：给出令牌分级规则（品牌主体 / 演示对照 / 语义色）与「保留 `$r` 是正解」的判定条件。
   成稿目标字数：1800–2400

4. **[第 4 章 L2 AttributeModifier：无状态样式的取色通道](./04-l2-attribute-modifier.md#ch04)**
   职责：解释 modifier 为何读不到 `@Trace`，以及用静态字段中转的取舍与刷新时机。
   成稿目标字数：1800–2400

5. **[第 5 章 L3 UiThemeManager：一个能自动重渲染的单例](./05-l3-ui-theme-manager.md#ch05)**
   职责：讲透 `@ObservedV2` + `@Trace` 单例的设计、四件取色方法（含感知亮度选前景）、空串语义。
   成稿目标字数：2600–3400

6. **[第 6 章 L4 ThemeControl：CustomTheme 必须成对给 darkColors](./06-l4-theme-control.md#ch06)**
   职责：把「一个 hex」翻译成 7 个 token 的 `colors` + `darkColors`，讲清覆盖范围与边界。
   成稿目标字数：2400–3200

7. **[第 7 章 编排与冷启动恢复：一个方法铺满四层](./07-orchestration-and-restore.md#ch07)**
   职责：`AppThemeApplier` 的顺序契约、`AppBootstrap.restoreTheme` 的「只读不注入」、四入口差异。
   成稿目标字数：2000–2600

### 第三部分 · 踩坑实录：9 个真机实测的坑

8. **[第 8 章 坑 1–2：切主题包「没反应」与「只改单例按钮仍蓝」](./08-pitfall-preset-no-effect.md#ch08)**
   职责：`setAccentColor('')` 的空串语义、切包必须清强调色；VitalUI 原语要自己接单例。
   成稿目标字数：2400–3200

9. **[第 9 章 坑 3–4：`@Param` 默认值读单例不响应，顶层 `@Builder` 用不了 `this`](./09-pitfall-param-and-builder.md#ch09)**
   职责：讲清「默认值只求值一次」与「顶层 Builder 无组件上下文」两条硬约束及两种正解。
   成稿目标字数：2000–2800

10. **[第 10 章 坑 5–6：不设 `darkColors` 暗色沿用浅色；卡片 V1 接不上 V2 单例](./10-pitfall-dark-and-card-v1.md#ch10)**
    职责：暗色下亮底亮字的机制与修法；ArkTS 卡片 `$r` 取舍为何是正解而非妥协。
    成稿目标字数：2000–2600

11. **[第 11 章 坑 7：HDS 私有 token 不吃 `ThemeControl`](./11-pitfall-hds-private-token.md#ch11)**
    职责：`HdsListItemCard` + `SuffixSwitch` 的显式传色方案（`CheckOptions.selectColor`）与 A/B 取证法。
    成稿目标字数：2200–2800

12. **[第 12 章 坑 8–9：响应式不能按窗口断点算栏宽/列数，页签不能按断点切位置](./12-pitfall-responsive-layout.md#ch12)**
    职责：分栏后容器仅 ~420vp 的实测、`navBarWidth` 的 32% clamp 340–420 与容器宽分档，`barPosition` 恒 `End`。
    成稿目标字数：2400–3000

### 第四部分 · 交付

13. **[第 13 章 验收清单、回归矩阵与 fork 接入顺序](./13-acceptance-and-fork.md#ch13)**
    职责：把「换肤是否真的完整」变成可勾选的验收项 + 四端回归矩阵 + 最小接入步骤。
    成稿目标字数：2000–2600

**全书成稿目标：约 2.6 万–3.4 万字。**

> **当前版本说明（重要）**：本目录交付的是**可发布级章节骨架**——每章均已含「要解决的问题 / 读者收获 / 正文要点（分节到可扩写粒度）/ 对应源码 / 配图 / 需复核」六段，正文要点已写成可直接发布的论述，但尚未逐节扩写到目标字数（当前每章约 1.4k–1.8k 汉字，13 章合计约 2.1 万汉字）。
> 因此章头的「成稿目标字数」是**扩写上限指引**，不是当前实测值。扩写时按节补案例、对比与边界讨论，**不要靠注水凑字数**。

---

## 三、学习路径（按你的目标三选一）

### 路径 A：我要给自己的应用加换肤（推荐 5 小时）

```
第 1 章（模型）→ 第 2 章（取证，只读你关心的模块）→ 第 5 章（L3 单例）
→ 第 6 章（L4 系统色）→ 第 7 章（编排 + 冷启动）→ 第 13 章（验收清单）
→ 出问题再回第 8–12 章按症状查
```

关键判断：**先建 L3 + L4 并跑通冷启动恢复**，再逐页替换硬编码色。反过来做（先改页面）会在每一页重复踩同一个坑。

### 路径 B：我只想搞懂「为什么改了没反应」（推荐 80 分钟）

```
第 1 章 §1.2 → 第 8 章（切包没反应 / 按钮仍蓝）
→ 第 11 章（HDS 不吃主题）→ 第 9 章（@Param 与 @Builder 两条硬约束）
```

### 路径 C：我要做「四端 + 分栏」的换肤适配（推荐 3 小时）

```
第 5 章 → 第 6 章 → 第 12 章（容器宽 vs 窗口断点、barPosition）
→ 第 13 章 §四端回归矩阵
```

避坑顺序提醒：**先把布局问题（第 12 章）修掉再看主题**。分栏后容器变窄会让「主题没生效」的错觉叠加「文字被截断」，两者混在一起极难定位。

---

## 四、截图索引（`assets/`）

本教程引用的全部截图，均为真机或模拟器实测，文件名与仓库内一致。

| 截图 | 场景 | 用于章节 |
|---|---|---|
| `A1-appearance.png` | 外观页：主题包行 + 取色块 + 预览（早期 4 套主题包状态，选中「品牌紫」、取色块显示 `#6c4de8`） | 第 8 章（现象取证） |
| `A5-teal-applied.png` | 切到青碧后的外观页 | 第 5 章 |
| `A8-components-teal2.png` | 组件示例页：按钮/标签/Toast 全部转青碧 | 第 4 章、第 9 章 |
| `A9-dialog-teal.png` | 统一对话框：「确认」主按钮为青碧（L4 生效证据） | 第 6 章 |
| `B1-presets-5.png` | 五套主题包齐备，选中「青碧」，取色块显示 `#12A594` | 第 3 章、第 5 章 |
| `B2-home-brandblue.png` | 首页基线：品牌蓝 | 第 1 章 |
| `C2-hds-teal.png` | 切青碧后回到设置页：HDS 行卡片底色/分割线/chevron 仍为中性灰 | 第 11 章 |
| `D1-2in1-tools.png` | 2in1 宽屏：开发工具网格 | 第 12 章 |
| `D3-2in1-appearance.png` | 2in1 宽屏：外观页 | 第 7 章、第 12 章 |
| `D5-2in1-teal2.png` | 2in1 宽屏：青碧主题下的分栏 | 第 12 章 |
| `E2-pura-navwide.png` | 阔折叠分栏：页签被挤到左栏**顶部**（`barPosition` 按断点切换的缺陷现场） | 第 12 章 |
| `E3-pura-tools.png` | 阔折叠：工具卡按窗口断点算列数 → 左栏挤压 | 第 12 章 |
| `E4-pura-tools-fixed.png` | 同上，改按容器宽分档后的 2 列 | 第 12 章 |
| `E7-pura-teal.png` | 阔折叠：青碧主题整体效果 | 第 13 章 |
| `G0-pura-tabbar-bottom.png` | 修复后：页签回到左栏底部浮动胶囊 | 第 13 章 |
| `G2-toggle-on-teal.png` | 分栏 + 「触感反馈」开关 ON 轨道为青碧（`selectColor` 生效证据） | 第 11 章、第 13 章 |

**注**：`E*` 系列与 `G*` 系列分属两次修复的取证——`E4` 修的是网格列数，此时页签仍在顶部；`G0/G2` 才是页签位置修复后的状态。两者不可混用作同一结论的证据。

---

## 五、术语表

| 术语 | 含义 | 出处 |
|---|---|---|
| 主题包（preset） | 整套配色基线，只声明**一个**品牌色 `baseHex` | `AppThemePreset` |
| 强调色（accent） | 用户在取色器里选的单点覆盖，优先级**高于**主题包 | `UiThemeManager.accentColor` |
| 注入面 | 会读 `UiThemeManager` 从而跟随主题的文件集合 | 第 2 章 |
| 落地器 | 把「主题包 + 强调色」一次铺到 L3 + L4 的编排类 | `AppThemeApplier` |
| 感知亮度 | sRGB 加权 `0.299R+0.587G+0.114B`，用于自动选前景色 | `UiThemeManager.onBrandColor` |
| 容器宽 | 组件**实际**可用的宽度（分栏后可能远小于窗口宽） | 第 12 章 |

---

## 六、附录 D：链接清单与核实状态

### 6.1 开源仓库

| 平台 | 地址 | 状态 |
|---|---|---|
| GitCode | <https://gitcode.com/quizzyjoy/easystart> | 已给出（用户提供） |
| Gitee | <https://gitee.com/quizzyjoy/easystart> | 已给出（用户提供） |
| GitHub | `https://github.com/<TODO: 待填 owner>/easystart` | **占位，待补** |

### 6.2 HarmonyOS 官方文档

核实方法：① 用本机官方文档库 `devecocli docs search` 命中条目（给出 doc id）；② 对 URL 发起请求确认可达（HTTP 200）。
**说明**：华为文档站为 SPA，抓取只能拿到页面骨架（`文档中心`），因此「HTTP 200」只能证明**路径存在**，内容真值以 doc id 命中的本地文档库条目为准。

| 主题 | doc id | URL | 核实状态 |
|---|---|---|---|
| `@ohos.arkui.theme`（ThemeControl / CustomTheme / CustomColors） | `js-apis-arkui-theme` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-arkui-theme> | ✅ 已核实（doc id 命中 + HTTP 200） |
| 设置应用内主题换肤 | `theme-skinning` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/theme-skinning> | ✅ 已核实（doc id 命中 + HTTP 200） |
| `@ObservedV2` / `@Trace`：类属性变化观测 | `arkts-new-observedv2-and-trace` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-new-observedv2-and-trace> | ✅ 已核实（doc id 命中 + HTTP 200） |
| `HdsTabs`（底部页签，含 `barPosition` / `barFloatingStyle`） | `ui-design-hdstabs` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs> | 🟡 doc id 已核实（本地文档库命中），URL 前缀未逐条请求 → **路径需复核** |
| `HdsNavigation`（导航根视图容器，含 `navBarWidth` / `mode`） | `ui-design-hdsnavigation` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdsnavigation> | 🟡 doc id 已核实，URL 前缀**需复核** |
| UI Design Kit 简介 | `ui-design-introduction` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-introduction> | 🟡 doc id 已核实，URL 前缀**需复核** |
| Navigation 单栏/分栏动态切换（FAQ） | `faqs-arkui-1644` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-arkui-1644> | 🟡 doc id 已核实；FAQ 的 URL 前缀（`harmonyos-faqs`）**需复核** |
| Navigation 分栏右栏默认页（FAQ） | `faqs-arkui-1276` | <https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-arkui-1276> | 🟡 同上，**需复核** |
| 深色模式适配（最佳实践） | `bpta-dark-mode-adaptation` | <https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-dark-mode-adaptation> | 🟡 doc id 已核实；`best-practices` 前缀**需复核** |
| 状态管理 V2 概述 | `arkts-new-state-management` | — | ⚠️ **需复核**：本轮未在本地文档库命中该 id，正式发布前须重新检索确认 |
| `Navigation` 组件参考（ArkUI 原生） | — | — | ⚠️ **需复核**：本轮未定位到确切 doc id；本仓实际使用的是 `HdsNavigation` 包装 |

> 结论口径：标 ✅ 的可直接引用；标 🟡 的**引用 doc id 与标题**，URL 由读者站内搜索；标 ⚠️ 的**不得在正文中出现具体链接**，需发布前补核。

### 6.3 本仓相关文档（可交叉阅读）

| 文档 | 作用 |
|---|---|
| `plan/换肤换主题-调研-2026-10-20.md` | 官方能力边界（`ThemeControl` / `WithTheme` / `onWillApplyTheme`）的 API 调研 |
| `plan/颜色注入机制-现状分析-2026-10-20.md` | 改造前的断点量化（92 处 / 48 文件 / 21 个注入面 / `setDefaultTheme` 0 处） |
| `docs/鸿蒙工程目录设计指南.md` | 分层与目录约定（控件工厂纪律的出处） |
| `assets/` | 全部取证截图 |

---

## 七、写作与取证约定（给协作同学）

1. **不臆造 API**：出现任何属性名/方法签名，必须能在 `hm_easystart/` 源码或本机 SDK `d.ts` 中找到；找不到就写「需复核」。
2. **不贴大段代码**：正文用「文件名 + 符号名 + 一句话机制」描述，代码片段不超过 5 行且只用于对比错误/正确写法。
3. **每条结论带证据**：真机截图（文件名）或可复现命令。
4. **区分「设计取舍」与「缺陷」**：例如卡片保留 `$r` 是取舍，不是 bug；写成缺陷会误导 fork 者。
5. **版本锚定**：结论对应 v3.43–v3.46；后续版本若改动，须在章末「版本注记」标注。
