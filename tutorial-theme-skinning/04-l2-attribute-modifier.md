<a id="ch04"></a>

# 第 4 章 L2 AttributeModifier：无状态样式的取色通道

> 本章成稿目标字数：1800–2400 ｜ 预计阅读 9 分钟 ｜ 前置：第 1、3 章

## 本章要解决的问题

**用 `AttributeModifier` 封装的按钮，为什么改了主题色完全不生效？能不能让 modifier 读主题单例？**

本章回答两个都容易答错的点：modifier **读不到** `@Trace`（读了也白读），而**能读**静态字段（但需要页面重建才刷新）。把这条边界讲清楚，才能理解为什么本仓要引入一个静态中转。

## 读者收获

1. 明白 `AttributeModifier` 为什么不在 ArkUI 观察依赖图里；
2. 掌握「静态中转 + 重建刷新」的取舍与适用边界；
3. 知道何时该改用「构造参数传入」（更显式）而非静态。

---

## 正文要点

### 4.1 现象：同一页里，两个按钮两种命运

改造前的组件示例页有一个非常典型的对比（`A8-components-teal2.png` 是修复后的状态）：

- 用 `CommonButton`（VitalUI 原语）渲染的「主操作」→ 改主题后**变了**；
- 用 `SomeButton().attributeModifier(new AppButtonPrimaryModifier())` 渲染的按钮 → 改主题后**始终是默认品牌蓝**。

两者在同一屏、同一主题下行为不同。这不是渲染 bug，而是**取色路径不同**：前者读了 `@Trace` 单例，后者读的是写死的 `$r('app.color.qj_brand')`。

### 4.2 机制：modifier 是普通类，不在观察图里

`AttributeModifier<T>` 的本质是一个「样式函数容器」：ArkUI 在需要应用样式时调用 `applyNormalAttribute(instance)`，把属性写进去。它带来两件事：

1. **调用时机由框架决定**——组件首次构建、状态变更导致重建时；**主题单例变化不会触发它**；
2. **它没有组件上下文**——不是 `@ComponentV2`，没有 `@Local`，因此即使你在里面写 `UiThemeManager.getInstance().brandColor()`，拿到的也只是「那一刻的值」，且**不会**因为 `@Trace` 变化而重新调用。

这就是为什么「让 modifier 直接读单例」看起来能编译、实际不生效。它甚至不是错误——只是**静态求值**。

### 4.3 正解 A（本仓采用）：静态中转 + 重建刷新

`AppThemeApplier` 里加一个静态字段 `currentAccent`，并在 `apply()` 时写入：

- **写**：`apply()` 里 `currentAccent = theme.effectiveAccent()`，与 L3/L4 同一次调用完成；
- **读**：`AppThemeApplier.brandColor()` 返回 `currentAccent` 非空则用它，否则回退 `$r('app.color.qj_brand')`；
- **用**：所有 modifier 族在 `applyNormalAttribute` 里调这个静态方法。

为什么这样能刷新？因为 modifier 实例通常在页面 `build()` 里 `new` 出来，**页面重建时**会重新执行 `applyNormalAttribute`，此时读到的静态值已是最新。

对应的**已知限制**（源码注释里写明了）：改色后需要一次页面重建才刷新——典型触发是「从外观页返回」或「系统深浅色切换」。这不是偷懒，而是明确接受的行为边界。

### 4.4 正解 B（更显式）：构造参数注入

`AppProgressModifier` 提供了另一种写法——把颜色作为构造参数，默认值取静态中转：

```
constructor(color: ResourceColor = AppThemeApplier.brandColor(), ...)
```

好处是：调用点可以显式传一个色（例如某处想特调），不传时自动跟随。缺点是：**每个调用点都要决定传不传**，一旦有调用点在页面重建之外被复用，仍会遇到同一个刷新时机问题。

本仓的实际选择是「**静态中转做默认，构造参数留口子**」——两种都在，按需要选。

### 4.5 为什么不让页面传 `theme.accentColor` 进去

这是最直觉的方案：页面已经有 `@Local theme`，调用点写 `new AppButtonPrimaryModifier(this.theme.accentColor)` 就行。

它的问题在**维护成本**：

1. 34 个使用点全部要确认所在页面有 `@Local theme`（否则拿不到）；
2. 新增一个使用点就要记得传，忘传就静默回退到默认色——**没有编译期保护**；
3. 强调色变化时，页面重建才会重读 `this.theme.accentColor`——依然需要重建，**没有比静态方案更好**。

结论：静态中转在「正确性相同、改动面更小」的条件下胜出。

### 4.6 静态状态的代价与纪律

引入静态字段换来了简洁，也带来两个必须守住的纪律：

1. **单一写入点**：只允许 `AppThemeApplier.apply()` 写 `currentAccent`，其它任何地方不得赋值。否则会出现「页面用自己的颜色覆盖了全局」的隐蔽 bug。
2. **静态值必须与单例同步**：`apply()` 里先 `setPresetId` / `setAccentColor`，**再**取 `effectiveAccent()` 写静态——顺序反了会写入上一次的值。

这两条在代码里是靠「唯一入口 + 注释」维持的，没有类型系统保护。第 13 章的验收清单把「modifier 与控制台颜色一致」列为必测项，就是为了兜住这个风险。

### 4.7 判定：什么时候该用 modifier，什么时候别用

| 场景 | 建议 |
|---|---|
| 一组属性要复用到多处（描边 + 圆角 + 内边距） | 用 modifier + 静态中转 |
| 需要**即时**响应主题（不重建页面就变） | **别用 modifier**，改自绘组件读 `@Local theme` |
| 令牌对照/演示（要展示固定色） | 用 modifier，但色值写死（B 类，第 3 章） |
| 单个属性 | 直接写属性，不必上 modifier |

---

## 对应源码（不贴代码）

| 文件 | 关注点 |
|---|---|
| `commons/AppComponent/src/main/ets/theme/AppThemeApplier.ets` | `currentAccent` 静态字段、`brandColor()`、`apply()` 内的写入顺序、注释里的刷新时机说明 |
| `commons/AppComponent/src/main/ets/modifier/AppButtonModifier.ets` | 4 档按钮样式在 `applyNormalAttribute` 中调用静态取色 |
| `commons/AppComponent/src/main/ets/modifier/AppProgressModifier.ets` | 正解 B：构造参数默认值取静态中转 |
| `commons/AppComponent/src/main/ets/modifier/AppDividerModifier.ets` / `AppIconButtonModifier.ets` / `AppInputModifier.ets` | 同类接入方式的一致性 |
| `features/DemoFeature/src/main/ets/view/ComponentGalleryView.ets` | modifier 与 VitalUI 原语同页并排的演示场景 |

## 配图

| 截图 | 说明 |
|---|---|
| `assets/A8-components-teal2.png` | 修复后：modifier 路径与 `CommonButton` 路径在同页颜色一致（青碧） |

## 需复核 / 已知限制

- **刷新时机**：改色后 modifier 需页面重建才刷新（源码注释已声明）。若产品要求「改完立即变」，必须把这些组件迁到 L3 自绘路径 → 需做取舍评审。
- 34 处 modifier 使用点中，有多少属于 B 类（演示固定色、应当保留写死）**未逐点分类** → **需复核**，会影响第 13 章回归范围。
- 静态字段带来的并发风险（多 Ability / 多窗口共用进程）本轮未验证 → **需复核**。

## 版本注记

- 改造前 modifier 族一律写死 `$r('app.color.qj_brand')`（全仓 34 处使用点，见 `plan/颜色注入机制-现状分析-2026-10-20.md`）。
- v3.44 起改为读 `AppThemeApplier.brandColor()`。
