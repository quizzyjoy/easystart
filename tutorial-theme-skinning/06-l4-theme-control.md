<a id="ch06"></a>

# 第 6 章 L4 ThemeControl：CustomTheme 必须成对给 darkColors

> 本章成稿目标字数：2400–3200 ｜ 预计阅读 12 分钟 ｜ 前置：第 1、5 章

## 本章要解决的问题

**对话框主按钮、开关选中态、SnackBar 动作色——这些我没写颜色的地方，怎么让它们也跟着品牌色走？**

这是自绘体系（L1/L3）完全管不到的部分。答案是官方的 `ThemeControl.setDefaultTheme(CustomTheme)`：把「一个品牌色」翻译成 ArkUI 的 token 表。本章讲清翻译规则、为什么只覆盖 7 个 token、以及 `darkColors` 为什么必须成对。

## 读者收获

1. 能把一个 hex 翻译成合法的 `CustomTheme`（含暗色），并知道 7 个 token 的选择理由；
2. 理解 `applied` 缓存、`try/catch`、`undefined` 清除三个工程细节；
3. 明确 L4 的**能力边界**：它管不到的三种情况（显式属性、HDS 私有 token、V1 卡片）。

---

## 正文要点

### 6.1 现象：为什么必须补这一层

改造前全仓 `ThemeControl.setDefaultTheme` 调用数为 **0**。后果是：

- `AppDialog` / `CommonDialog` 的「确认」按钮走系统默认蓝；
- 原生 `Toggle` 选中轨道、填充 `Button` 底色走 `sys.color.*`；
- `HdsSnackBar` 的动作色同理。

这些组件你没有显式指定颜色——**所以它们读的是「应用默认主题」**。不设，就是系统蓝；设了，才跟随品牌。

`A9-dialog-teal.png` 是这一层生效最直接的证据：统一对话框的「确认」按钮是青碧 `#12A594`，而该对话框的代码里并没有传这个色。

### 6.2 API 形态与版本门槛

官方接口形态（`@ohos.arkui.theme`）：

| 类型 | 语义 |
|---|---|
| `CustomTheme` | `{ colors?: CustomColors; darkColors?: CustomDarkColors }` |
| `CustomColors` | `Partial<Colors>`——51 个 token 里**只覆盖你需要的** |
| `ThemeControl.setDefaultTheme(theme)` | 设置应用内默认主题；传 `undefined` 清除 |

版本要点：`CustomTheme.darkColors` 的引入版本**晚于** `colors`（`@since 20`）。这意味着：

- compatibleSdkVersion ≥ 20 时可以直接用；
- fork 方若把兼容版本降到 19 以下，`darkColors` 会编译失败，需要 `canIUse` 或版本分支。

> 本节版本门槛来自 `plan/换肤换主题-调研-2026-10-20.md`（本机 SDK `d.ts` 实录 + 官方文档）。正式发布前建议在自己的 SDK 上复核一次 `@since` 标记。

### 6.3 为什么只覆盖 7 个 token

51 个 token 全填看起来「更彻底」，实际会引发对比度事故：例如把 `fontPrimary` / `backgroundPrimary` 也刷成品牌色，正文与背景的关系就崩了。

本仓的选择是「**只覆盖强调语义的 7 个 token**，其余 40+ 交给系统默认」：

| token | 作用 |
|---|---|
| `brand` | 填充按钮底、开关选中等主强调 |
| `fontEmphasize` | 强调文本 |
| `iconEmphasize` | 强调图标 |
| `backgroundEmphasize` | 强调底 |
| `compEmphasizeSecondary` | 组件强调层（次级，浅） |
| `compEmphasizeTertiary` | 组件强调层（三级，更浅） |
| `interactiveSelect` | 选中态 |

判定原则：**只覆盖「品牌色应当出现」的 token；凡是承担「可读性基线」的 token（正文、背景、分隔线）一律不碰。**

### 6.4 浅色：品牌色 + 两档混合

浅色分支直接用品牌色填 4 个强调 token，再用**与白色线性混合**得到两档柔和层：

- `compEmphasizeSecondary` = `mix(hex, #FFFFFF, 0.82)`（82% 白）
- `compEmphasizeTertiary` = `mix(hex, #FFFFFF, 0.90)`
- `interactiveSelect` = 同 tertiary

`mix()` 的实现是标准线性插值：把两个 hex 拆成 RGB 三元组，按比例加权后取整再拼回 `#RRGGBB`。这段代码不到 15 行，但**它是整套「一个色生成一套色」的关键**（第 3 章说的「一套主题包只声明一个色」靠它兑现）。

### 6.5 深色：先提亮，再用黑混合

深色分支不是把浅色值照搬，而是两步：

1. **提亮品牌色**：`lifted = mix(hex, #FFFFFF, 0.28)`——把暗底上发闷的原色抬亮一档；
2. **用黑做柔和层**：`soft = mix(lifted, #000000, 0.72)`、`soft2 = mix(lifted, #000000, 0.82)`。

为什么柔和层在深色下要「往黑混」而不是「往白混」？因为在暗色界面里，「柔和」意味着**向背景靠拢**，而背景是暗的。这一步做反了，深色下所有 chip 会发光。

### 6.6 `darkColors` 不设会怎样（这是本章最重要的一节）

`CustomTheme` 的 `darkColors` 语义是：**不提供时，深色模式沿用 `colors` 的值**，不会自动变暗。

后果是「暗底亮字」——在深色模式下，品牌色的强调底仍按浅色逻辑算（偏亮），压在上面的前景色却按深色的白字渲染，对比度全崩。

所以本章有一条**硬规则**：

> `colors` 与 `darkColors` **必须成对提供**。只要其中一个存在，另一个就不能省。

本仓把这条规则固化在 `buildTheme()` 里——它一次性返回 `{ colors, darkColors }`，**从结构上让「只给一半」变得不可能**。这是比写注释更可靠的防错方式，值得照抄。

### 6.7 三个工程细节

**① 归一化与拒绝非法值**：`normalize()` 接受 `#RRGGBB`，也接受 `#AARRGGBB`（去掉前两位 alpha）。非法输入返回空串，调用方据此**跳过设置**并记一条 warn——而不是把非法值塞给系统组件（那会得到一批不可预测的颜色）。

**② 重复调用短路**：静态 `applied` 记录上次生效值，值没变就直接返回 `true`。`setDefaultTheme` 本身支持重复调用，但每次调用都可能触发全局重算；短路能省掉「打开外观页又点了一次同色」这类无效重刷。

**③ 失败不阻塞启动**：整个调用包在 `try/catch` 里，失败只记 `warn` 并返回 `false`。理由是 L4 只是**兜底层**——它失败了，L1/L3 仍然工作，界面「大部分是对的」，绝不该因为主题失败导致白屏。

### 6.8 调用时机：官方样例 vs 本仓实际

官方样例把 `setDefaultTheme` 放在 `windowStage.loadContent(...)` 的回调里，理由是「必须在 ArkUI 初始化之后」。

本仓把它放在 `EntryAbility.onCreate` 里通过 `AppBootstrap.restoreTheme().then(...)` 调用。这是**异步的**，实际执行时机取决于 Preferences 读取完成的时刻——可能早于也可能晚于 `loadContent`。

真机结果是可用的（`A9-dialog-teal.png` 取证：对话框按钮确实变了），但这属于「在另一个调用点验证通过」，与官方样例的严格姿势不同。教程把这条列为**需复核项**：

- 若出现「冷启动首屏闪一下系统蓝」的反馈，应把调用点迁到 `loadContent` 回调内；
- 迁移代价很小（`AppThemeApplier.apply` 是幂等的），属于低风险改动。

### 6.9 L4 的能力边界（三条）

| 边界 | 表现 | 后续章节 |
|---|---|---|
| **显式设置过的属性不会被覆盖** | 你写了 `.backgroundColor('#xxx')`，主题改不动它 | 第 3 章（分级） |
| **HDS 私有 token 不吃这套** | `HdsListItemCard` 底色/分割线/chevron 不变 | 第 11 章 |
| **V1 卡片框架不参与** | ArkTS 卡片保持令牌色 | 第 10 章 |

把这三条写进文档，能省掉后来者大量「明明设了主题为什么这块不变」的排查时间。

---

## 对应源码（不贴代码）

| 文件 | 关注点 |
|---|---|
| `quizzyjoy/Platform/src/main/ets/theme/AppThemeController.ets` | 全章主体：`applyPreset()`、`clear()`、`buildTheme()`、`lightColors()`、`darkColors()`、`normalize()`、`mix()` |
| `quizzyjoy/Platform/src/main/ets/theme/AppThemeController.ets`（文件头） | 7 个 token 的选择理由（原文注释即为权威说明） |
| `quizzyjoy/Platform/src/main/ets/theme/AppThemeController.ets`（类型再导出） | `CustomColors` / `CustomTheme` / `Theme` 从本层再导出，保证上层零 `@kit` |

## 配图

| 截图 | 说明 |
|---|---|
| `assets/A9-dialog-teal.png` | L4 生效证据：对话框「确认」主按钮为青碧（代码未显式传该色） |
| `assets/A8-components-teal2.png` | 对照：自绘原语（L3）与系统组件（L4）同一主题下观感一致 |

## 需复核 / 已知限制

- **调用时机**（§6.8）：本仓在 `onCreate` 异步链路调用，与官方 `loadContent` 回调姿势不同；已真机可用，但**首屏闪色的可能性未排除** → **需复核**。
- **`@since` 版本号**（§6.2）：`darkColors @since 20` 来自调研文档的 d.ts 实录，建议在自己的 SDK 上复核一次。
- **`interactiveSelect` 在浅色下取 `soft2`** 是否会导致选中态过淡（对比度不足）**未做可读性评估** → **需复核**。
- 手表端（`entry_wearable`）不调用本层，保持默认主题——这是有意设计（第 7 章），非缺陷。

## 版本注记

- L4 于 v3.43 建立；改造前全仓调用数为 0。
- `darkColors` 成对提供是本层建立时就定下的硬规则，未出现「先只给 colors」的中间态。
