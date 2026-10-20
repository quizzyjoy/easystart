<a id="ch05"></a>

# 第 5 章 L3 UiThemeManager：一个能自动重渲染的单例

> 本章成稿目标字数：2600–3400 ｜ 预计阅读 14 分钟 ｜ 前置：第 1、3 章

## 本章要解决的问题

**怎么让「用户改了一个字符串」，就让全应用所有自绘组件在同一帧换色？**

答案是：把颜色放进一个 `@ObservedV2` 的 `@Trace` 字段里，让组件用 `@Local` 持有它。本章逐方法拆解这个单例，并给出**组件侧必须遵守的读取约定**——违反约定会出现「主题包不生效」的诡异结果。

## 读者收获

1. 能独立写出一个可被 V2 组件观测的全局主题单例；
2. 理解 `effectiveAccent()` / `brandColor()` / `onBrandColor()` / `brandSoftColor()` 四个方法各自的回退链；
3. 知道「空串 = 清除覆盖」这个语义为什么是必需的（第 8 章的根因）；
4. 能识别最常见的错误写法：`accentColor.length > 0 ? accentColor : $r(...)`。

---

## 正文要点

### 5.1 为什么是「单例 + @ObservedV2」，而不是 AppStorage

需求有三条硬约束：

1. **跨模块可见**：`VitalUI` 的原语要用、`AppComponent` 的工厂要用、`AppSettings` 的外观页要用；
2. **改动要能触发重渲染**，且**跨组件层级**（不是父子传参能解决的）；
3. **VitalUI 必须零 `@kit`**（这条决定了不能用带状态管理的系统设施）。

`@ObservedV2` 类 + 私有构造 + `getInstance()` 同时满足三条：它是纯 ArkTS（零 `@kit`），字段带 `@Trace` 就具备属性级观测能力，任何 `@ComponentV2` 里用 `@Local` 持有它即自动建立依赖。

> 反例提醒：`AppStorage` / `AppStorageV2` 也能做全局状态，但会把「表现层数据」推给平台层设施，且观测粒度是「键」而不是「类属性」，在本场景下不如 `@Trace` 直接。

### 5.2 字段设计：两个 `@Trace`，一套语义

| 字段 | 类型 | 语义 |
|---|---|---|
| `accentColor` | `string` | 用户自选强调色，`'#RRGGBB'`；**空串 = 没有覆盖** |
| `presetId` | `string` | 当前主题包 id（`AppThemePreset.id`）；空串按默认包处理 |

两者是**叠加关系而非互斥**：主题包是基线，强调色是单点微调。这个语义决定了所有取色方法的**优先级顺序**——强调色永远先于主题包。

### 5.3 `effectiveAccent()`：拿到「最终生效的品牌色」

逻辑只有两步：有强调色用它，否则取当前主题包的 `baseHex`。

它返回**纯字符串 hex**，用在两个地方：

1. 需要把颜色当数据用（持久化、比对、传给取色器显示）；
2. 传给只接受 `string` 的 `@Param accentColor` 口子。

`B1-presets-5.png` 里能看到它的一个可见后果：切到青碧后，取色块显示的是 `#12A594` 而不是空——因为取色器显示的是 `effectiveAccent()`，即「当前生效色」，而不是「用户是否设过强调色」。

### 5.4 `brandColor()`：组件侧取色的**唯一**推荐方法

它比 `effectiveAccent()` 多一层判断，返回 `ResourceColor`：

```
有强调色        → 返回强调色 hex
默认主题包      → 返回 $r('app.color.qj_brand')   ← 保住深浅色（第 3 章）
非默认主题包    → 返回该包的 baseHex
```

**为什么它必须存在**：如果组件都自己写「有就用强调色，否则用 `$r`」，那么**主题包这一层就被漏掉了**——切主题包（不设强调色）时，所有这样写的组件都不动。

源码注释专门警告了这一点：

> 组件**不要**写 `accentColor.length > 0 ? … : $r(...)` 这类三元——那会把「主题包」漏掉。

这是本章最重要的一句话。它解释了第 8 章「切主题包没反应」的第二个成因（第一个成因是空串语义）。

### 5.5 `onBrandColor()`：压在品牌色上的前景色

当文字/图标压在品牌色底上时，必须解决对比度：青碧底配白字尚可，桃粉底配白字就发糊，高对比（近黑）底配深色字则完全不可读。

实现方式是**感知亮度**：

```
luminance = 0.299·R + 0.587·G + 0.114·B      // R/G/B 归一到 0~1
luminance > 0.62 → 前景用 '#0A0A0A'（深）
否则           → 前景用 '#FFFFFF'（白）
```

三个细节值得学：

1. 权重是 sRGB 经典系数（人眼对绿最敏感），不是简单平均；
2. 阈值 `0.62` 是经验值，偏向「宁可早一点转深色字」；
3. **默认主题包 + 无强调色时直接回退 `$r('app.color.qj_on_brand')`**——把这件本该由设计决定的对比关系交给资源限定词，保证深浅色下都正确。

### 5.6 `brandSoftColor()`：chip 底 / 选中底

原意是「品牌色的柔和层」。实际实现是：默认主题包 + 无强调色 → `$r('app.color.qj_brand_light')`；否则 → `effectiveAccent()`。

**这里有一处语义与名称不一致**：非默认主题包时返回的是**满强度色**，不是柔和色。`B1-presets-5.png` 中「品牌标签」的底偏深，与此一致。

教程在正文中的口径：**把它理解为「品牌底」，不要理解为「浅色叠层」**；若你的产品需要真正的柔和层，应自行按比例混合（第 6 章的 `mix()` 提供了现成算法）。

### 5.7 `setAccentColor('')`：空串是一个**语义**，不是「无效输入」

这段代码是全系统里最容易被误读的十行之一：

```
setAccentColor(color) {
  空串            → accentColor = ''      // 清除覆盖，回退主题包
  '#RRGGBB'       → accentColor = 该值
  其它            → 忽略（保持原值）
}
```

如果把空串当成「非法输入忽略」，就得到一个致命后果：**切主题包时无法清空上一次的强调色**。而强调色优先级更高，于是「切了包却看起来没反应」。这正是第 8 章要展开的坑 1。

### 5.8 组件侧的读取约定（必须遵守）

本仓把「谁读单例」按组件类型分成两种范式：

| 组件类型 | 范式 | 原因 |
|---|---|---|
| **VitalUI 原语**（`CommonButton` / `CommonTag` / `ActionCard` / `CommonLoading` / `CommonColorPickerSheet`） | 自己持有 `@Local theme` **且** 开 `@Param accentColor: string`（空串回退 `theme.brandColor()`） | 原语要保持「可被页面覆盖」的灵活性；同时不能因为页面忘传就丢主题 |
| **AppComponent 控件工厂**（`AppCheckbox` / `AppToggle` / `AppSlider` 等 13 个） | 内部 `@Local theme = UiThemeManager.getInstance()`，不给外部口子 | 原生控件的选中色要逐点覆盖，若让页面传参会**大量漏传** |

`CommonButton` 是这个范式的标准样本：

```
@Local theme = UiThemeManager.getInstance();     // 建立观察
@Param accentColor: string = '';                  // 允许页面覆盖
取色 = accentColor.length > 0 ? accentColor : this.theme.brandColor();
```

注意它与 §5.4 警告的区别：这里 `accentColor` 是**页面传入的覆盖值**，为空时才走 `brandColor()`（包含主题包判断）。所以这个三元是**正确**的；错误的三元是「为空时直接跳 `$r`，跳过单例」。

### 5.9 一个必须知道的类型约束

`@ObservedV2` 的观测只在 **`@ComponentV2`** 里通过 `@Local` 生效。

V1 的 `@Component`（以及 `@Entry @Component` 的卡片框架）**无法**接这个单例。这不是配置问题，而是两套状态管理不互通。第 10 章会给出这条约束导致的真实取舍。

---

## 对应源码（不贴代码）

| 文件 | 关注点 |
|---|---|
| `quizzyjoy/VitalUI/src/main/ets/theme/UiThemeManager.ets` | 全章主体：`@ObservedV2` + 两个 `@Trace`、四个取色方法、`setAccentColor` 空串语义、`reset()` |
| `quizzyjoy/VitalUI/src/main/ets/component/CommonButton.ets` | §5.8 范式样本：`@Local theme` + `@Param accentColor` + 三分支取色 |
| `quizzyjoy/Foundation/src/main/ets/theme/AppThemePreset.ets` | `effectiveAccent()` 依赖的 `resolveThemePreset()` 与默认包常量 |
| `commons/AppSettings/src/main/ets/component/AccentColorSetting.ets` | 使用方：取色器显示 `effectiveAccent()`、预览区传 `accentColor` |

## 配图

| 截图 | 说明 |
|---|---|
| `assets/A5-teal-applied.png` | 切青碧后的外观页：预览区三个控件全部转青碧（L3 生效） |
| `assets/B1-presets-5.png` | 取色块显示 `effectiveAccent()` = `#12A594`（选了主题包但没设强调色） |
| `assets/A8-components-teal2.png` | 原语层跟随效果全览 |

## 需复核 / 已知限制

- **`brandSoftColor()` 语义偏差**（§5.6）：非默认主题包返回满强度色。是简化还是遗留缺陷，**需发布前裁定**；正文暂按「品牌底」表述。
- `@ObservedV2` 单例在多 UIAbility / 多窗口场景下是否共享（同进程静态实例）本轮未验证 → **需复核**。
- 感知亮度阈值 `0.62` 的具体取值依据无设计文档支撑，仅为经验值 → **需复核**（若产品有对比度规范，应替换为规范值）。

## 版本注记

- v3.43 扩展为「主题包 + 强调色」双层；在此之前只有强调色一层。
- `setAccentColor('')` 的清除语义同为 v3.43 新增，动机见源码注释（「切换主题包时必须能清空」）。
