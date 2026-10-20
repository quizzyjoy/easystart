<a id="ch07"></a>

# 第 7 章 编排与冷启动恢复：一个方法铺满四层

> 本章成稿目标字数：2000–2600 ｜ 预计阅读 10 分钟 ｜ 前置：第 5、6 章

## 本章要解决的问题

**四层都建好了，谁负责按正确顺序调用？冷启动时怎么保证「打开就是上次的颜色」而不是「先闪一下默认蓝」？**

本章讲两个类：`AppThemeApplier`（落地器，一次调用铺四层）与 `AppBootstrap.restoreTheme()`（只读偏好、不碰表现层）。它们的分工是被**模块依赖方向**逼出来的，理解了这一点，你就不会想当然地把它塞进 `AppCommon`。

## 读者收获

1. 掌握「一次调用铺 L3 + L4」的顺序契约与幂等语义；
2. 理解「读偏好」与「注入表现层」为什么要拆成两个模块；
3. 能写出正确的冷启动恢复链路（含降级键兼容）。

---

## 正文要点

### 7.1 为什么编排类必须放在 `AppComponent`

这是全章最值得先讲的设计因果，因为它决定了你能不能复用这套结构。

约束链：

```
VitalUI  不能依赖 Platform   （原语库要零 @kit）
AppCommon 不能依赖 VitalUI    （手表端要能用，手表不接主题）
```

而「铺四层」这件事需要**同时**操作：

- L3 → `UiThemeManager`（在 VitalUI）
- L4 → `AppThemeController`（在 Platform）

于是没有任何一个「更底层」的模块能同时持有两者。`AppComponent` 恰好同时依赖 VitalUI 与 Platform，因此它是唯一合法位置。

**推论**：如果你的工程没有这种分层，编排逻辑可以放在任意「同时可见两者」的地方；但只要你有「零依赖的 UI 原语库」，就必然会出现同样的选择。

### 7.2 `apply()` 的顺序契约：先 L3，后 L4

```
① theme.setPresetId(presetId)             // 空串 → 默认包
② theme.setAccentColor(accentHex)         // 空串 → 清除覆盖
③ currentAccent = theme.effectiveAccent() // 写静态中转（第 4 章）
④ AppThemeController.applyPreset(...)     // 铺 L4
```

三条纪律：

1. **必须先写单例再取 `effectiveAccent()`**：反了就会把上一次的值塞进静态字段；
2. **L3 在前**：自绘组件在同一帧就能取到新色，不会出现「系统组件变了、自绘组件还旧」的错帧；
3. **两者互不依赖**：L4 失败不影响 L3（返回值只表示 L4 是否成功）。

`apply()` 的返回值语义也写清了：**返回 `false` 不代表「什么都没做」**——L3 一定被设置了，只是系统组件层没成功。调用方不应该因为 `false` 就回滚。

### 7.3 三个入口方法：apply / applyAccent / applyPreset

| 方法 | 何时用 | 行为 |
|---|---|---|
| `apply(presetId, accentHex)` | 冷启动恢复、进外观页幂等再落地 | 全量：L3 + L4 + 静态中转 |
| `applyAccent(accentHex)` | 取色器确认 | 保留当前 `presetId`，只换强调色 |
| `applyPreset(presetId)` | 切换主题包 | 保留当前 `accentColor`，只换主题包 |

注意 `applyPreset` 的行为：**它不替你清强调色**。清不清是**业务决策**——外观页在切包时显式清了（第 8 章），但那属于页面职责，不是落地器职责。这条边界划得很干净：落地器只做「按给定参数铺层」，不猜用户意图。

### 7.4 `restoreTheme()`：只读，不注入

`AppBootstrap.restoreTheme()` 返回一个纯数据对象 `AppThemeState { presetId, accentHex }`，**不调用任何表现层 API**。

读取顺序（含兼容）：

| 键 | 说明 |
|---|---|
| `accent_color` | 现行强调色键 |
| `accent_preset` | v2.1 历史枚举键，仅在现行键为空时回退；其值是 hex 直通，`'default'` 等非 hex 视为无记录 |
| `theme_preset` | 主题包 id |

强调色要先过 `ACCENT_HEX_PATTERN` 校验：合法才返回小写 `'#rrggbb'`，否则返回空串（控件回退主题包基准色）。

**为什么要校验而不是直接信任持久化值**：持久化数据可能来自旧版本、可能被外部写坏。一个非法 hex 传进 L4 会让 `normalize()` 返回空串、`applyPreset` 直接跳过，最终表现为「主题不生效」——在校验处拦掉，日志里还能看出一句明确的 warn。

### 7.5 「只读不注入」的代价与收益

代价很明显：**每个入口 Ability 都要自己写三行**（`restoreTheme().then(state => AppThemeApplier.apply(...))`）。

收益是分层不被破坏：`AppCommon` 保持对 VitalUI 零依赖，手表端可以完全不用主题而共享同一套 bootstrap。

实际调用面：

| 入口 | 是否恢复主题 |
|---|---|
| `entry`（手机/平板/折叠） | ✅ `EntryAbility.onCreate` |
| `entry_pc`（2in1） | ✅ `PcAbility` 同样三行 |
| `entry_tv` | ✅ `EntryTvAbility` |
| `entry_wearable`（手表） | ❌ 明确不调用，保持默认主题 |

手表这条不是遗漏，而是**产品决策**：手表界面小、色块少，强行套主题收益低而风险高（HDS/XComponent 在小屏上的表现未验证）。

### 7.6 幂等再落地：进外观页再铺一次

`AccentColorSetting.aboutToAppear()` 会做一串动作：读强调色（含 legacy 回退）→ 读主题包 → `setAccentColor` / `setPresetId` → **再调一次 `AppThemeApplier.apply()`**。

最后这一句是防御式的：**万一某个入口没调（例如新增端漏了）**，用户只要进一次外观页，四层就会被补齐。

这个模式值得抄：把「关键状态落地」做成**幂等 + 多触发点**，比追求「只在启动时调一次」更抗遗漏。

### 7.7 冷启动时序与「闪一下」的可能

完整时序（手机端）：

```
onCreate
 ├─ AppBootstrap.prepare(context)               // 错误兜底、色彩模式、存储 init…
 ├─ AppBootstrap.restoreTheme()                 // 异步读偏好 → AppThemeState
 │    └─ .then(state => AppThemeApplier.apply)  // L3 + L4
 └─ captureCardTarget(want)                     // 卡片深链

onWindowStageCreate
 └─ loadContent('pages/Index', cb)              // 首帧渲染发生在这里
```

问题在于：**`restoreTheme()` 是异步的，首帧可能在它完成之前就渲染了**。此时页面看到的是默认主题色，等 `apply()` 完成后再刷新——观感上就是「闪一下」。

本仓在真机上未观察到明显闪色（Preferences 读取很快），但这是一个**结构性风险**，不是「已验证不会发生」。缓解方案（按代价排序）：

1. 把 `apply()` 提前到能同步拿到值的位置（需把主题值缓存进内存，代价是持久化层改造）；
2. 在 `loadContent` 回调里再调一次 `apply()`（幂等，几乎零成本）；
3. 启动页/骨架屏遮住首帧（成本最低，但只是掩盖）。

第 13 章把「冷启动不闪色」列入验收清单。

---

## 对应源码（不贴代码）

| 文件 | 关注点 |
|---|---|
| `commons/AppComponent/src/main/ets/theme/AppThemeApplier.ets` | 全章主体：`apply()` 顺序、`applyAccent` / `applyPreset`、`brandColor()` 静态中转、注释中的分层理由 |
| `commons/AppCommon/src/main/ets/bootstrap/AppBootstrap.ets` | `restoreTheme()`、`restoreAccentColor()`（legacy 回退 + 正则校验）、`AppThemeState` |
| `product/entry/src/main/ets/entryability/EntryAbility.ets` | 手机入口三行调用（`onCreate`） |
| `product/entry_pc/src/main/ets/pcability/PcAbility.ets` | 2in1 入口同样三行 |
| `product/entry_tv/src/main/ets/entryability/EntryTvAbility.ets` | TV 入口同样三行 |
| `commons/AppSettings/src/main/ets/component/AccentColorSetting.ets` | 进页幂等再落地 + 持久化写入 |
| `commons/AppPreferences/.../PreferenceKeys` | `accent_color` / `accent_preset`（legacy）/ `theme_preset` / `favorite_colors` |

## 配图

| 截图 | 说明 |
|---|---|
| `assets/D3-2in1-appearance.png` | 2in1 宽屏外观页（分栏内嵌设置子页，验证编排在 PC 入口同样生效） |
| `assets/A5-teal-applied.png` | 手机端外观页应用后状态 |

## 需复核 / 已知限制

- **首帧闪色风险**（§7.7）：异步恢复与首帧渲染的先后顺序未做严格时序取证（无逐帧录屏）→ **需复核**。
- **多入口一致性**：手机 / 2in1 / TV 三端分别在各自 Ability 调用；是否三端行为完全一致本轮仅做了构建与部分真机走查，**未逐端截图 A/B** → **需复核**。
- 手表端不接主题是决策；若未来要支持，需单独设计（小屏 + 无 `loadContent` 同款链路的差异）。

## 版本注记

- v3.15 起有「冷启动恢复强调色」链路（`restoreAccentColor`），v3.43 扩展为「主题包 + 强调色」（`restoreTheme` + `AppThemeState`）。
- 「进外观页幂等再落地」也是 v3.43 加入的防御措施。
