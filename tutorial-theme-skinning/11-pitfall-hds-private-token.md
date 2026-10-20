<a id="ch11"></a>

# 第 11 章 坑 7：HDS 私有 token 不吃 `ThemeControl`

> 本章成稿目标字数：2200–2800 ｜ 预计阅读 11 分钟 ｜ 前置：第 6、8 章

## 本章要解决的问题

**系统组件的默认色已经被我接管了，为什么设置页的开关轨道还是系统蓝？**

因为那个开关不是「系统组件」，而是 **HDS 组件**。它读的是 HDS 自己的私有 token，既不吃 `ThemeControl`，也不认识你的 `UiThemeManager`。本章讲清这条第三体系的边界，以及**唯一的正解：显式传色**。

## 读者收获

1. 能区分三类颜色体系：原生 `sys.color` / HDS 私有 token / 自绘；
2. 掌握「查 d.ts 找显式传色入口」的排查路径（不靠猜属性名）；
3. 学会用真机 A/B 取证「某个 token 到底吃不吃主题」。

---

## 现象

切到青碧主题后走查设置页，发现：

| 位置 | 结果 |
|---|---|
| 触感反馈开关 ON 轨道 | **系统蓝** `#0A59F7`（应为青碧 `#12A594`） |
| 屏幕常亮开关 ON 轨道 | 同上 |
| HDS 行卡片底色 | 中性灰（不变） |
| 行分割线 | 中性灰（不变） |
| 行尾 chevron 箭头 | 中性灰（不变） |

而同一页里，其它自绘元素（图标 chip、页码等）已经正确转成青碧。**同页两种行为**，说明不是主题没生效，而是这些元素不属于同一个体系。

---

## 一次真实的误判（这段比结论更值得读）

第一反应是：「这个开关是我们自绘的 `SettingsSwitchRow`，它的 `.selectedColor(this.theme.brandColor())` 应该生效，为什么没变？」

于是检查了 `SettingsSwitchRow` —— 那条路径**本来就是对的**，其它页面用它的开关都正常变色。

继续查才发现：设置域是 **schema 驱动**的（`SchemaSettingsSection` 按 `rawfile/settings_schema.json` 渲染），而 `builtin: 'haptic'` / `builtin: 'keepScreenOn'` 这两行走的是：

```
HdsListItemCard({
  prefixItem: …,
  textItem: …,
  suffixItem: new SuffixSwitch({ isCheck: …, onChange: … })   // ← 这里没有颜色参数
})
```

也就是说：**页面上看到的开关根本不是自绘组件**，它来自 HDS 的 `SuffixSwitch`。自绘那条路径没问题——是我看错了对象。

> 教训：schema 驱动的页面，「看到的控件」与「以为的组件」经常不是同一个。排查前先确认这个像素是谁画的。

---

## 根因：三类体系，三种吃色的方式

| 体系 | 颜色来源 | 吃 `ThemeControl`？ | 吃 `UiThemeManager`？ | 正解 |
|---|---|---|---|---|
| 原生组件（`Toggle` / `Button`…） | `sys.color.*` → 应用默认主题 | ✅ 是 | ❌ | L4（第 6 章） |
| **HDS 组件**（`HdsListItemCard` / `HdsTabs` / `SuffixSwitch`…） | **HDS 私有 token** | ❌ **否** | ❌ | **显式传色参数 / Modifier** |
| 自绘组件 | 你写的取色逻辑 | — | ✅（若接了） | L3（第 5 章） |

`ThemeControl.setDefaultTheme` 覆盖的是 ArkUI 的 token 表（51 个 `Colors` 字段）。HDS 组件虽然画在 ArkUI 之上，但它内部用的是**自己的一套 token**，不在这张表里——所以主题对它无效。

这也解释了为什么「HDS 行卡片的底色/分割线/chevron 完全不随主题」：它们全部由 HDS 私有 token 决定。

---

## 正解：查 d.ts，找到显式传色入口

不要猜属性名（猜错的成本是半小时），直接查 HDS 的类型声明：

- 目标文件：本机 SDK 里的 `@hms.hds.hdsBaseComponent.d.ets`
- 要找的东西：`SuffixSwitch` 的构造参数类型（`CheckOptions`）
- 找到的属性：`selectColor?: ResourceColor` —— **HDS 自己提供了显式传色的口子**

于是修改只有两处（对应两个 `SuffixSwitch` 实例）：

```
new SuffixSwitch({
  isCheck: this.vm.hapticEnabled,
  selectColor: this.theme.brandColor(),    // ← 新增
  onChange: …
})
```

同时给 `SchemaSettingsSection` 补上观测上下文：

```
@Local theme: UiThemeManager = UiThemeManager.getInstance();   // 新增
```

**注意这一步不可省**：只传 `selectColor` 而不持有 `@Local theme`，首次渲染是对的，切主题时**不会重绘**（第 9 章坑 3 的同一机制）。

---

## 验证：真机 A/B

验证方式不是「看起来变了」，而是**取像素**：

| | 修复前 | 修复后 |
|---|---|---|
| 开关 ON 轨道 | `#0A59F7`（系统蓝，恒定） | `#12A594`（青碧，随主题） |

`G2-toggle-on-teal.png` 是修复后的取证：分栏右栏「通用设置」页里，「触感反馈」开关 ON 轨道为青碧，「屏幕常亮」为 OFF 灰态。

---

## 边界：修好开关 ≠ HDS 全部跟随

HDS 组件族里，**只有提供了显式传色参数的**才能跟随主题。当前状态：

| HDS 元素 | 能否跟随 | 路径 |
|---|---|---|
| `SuffixSwitch`（本仓两处） | ✅ 已跟随 | `CheckOptions.selectColor` |
| `HdsListItemCard` 卡片底色 / 分割线 / chevron | ❌ 仍不跟随 | 需 `HdsListItemCardModifier` 或显式 tint（**本仓未做**） |
| `HdsTabs` 页签选中色 | ⚠️ 未专门处理 | 需查其自身样式参数（**需复核**） |
| `HdsNavigation` titleBar 材质 | ⚠️ 计划以系统材质为主 | 材质色随系统，非品牌色（预期行为） |

教程口径：**HDS 的跟随是「逐组件、逐 token」的工程，不是一次开关**。谁提供了口子就接谁，没口子的不要硬试（下一节讲为什么）。

---

## 方法论：遇到「这块不吃主题」的四步法

1. **确认是谁画的**：schema 驱动 / 工厂封装 / 直接写——先定位到真实组件；
2. **判断体系**：原生 `sys.color` → 查 L4；HDS → 查私有 token；自绘 → 查是否读了单例；
3. **查 d.ts 找口子**：在 `@hms.hds.*.d.ets` 里搜组件名，看构造参数/Modifier 是否有 `ResourceColor` 字段；
4. **A/B 取像素验证**：不看「感觉变了」，看「色值变了」。

这套顺序能避免两种典型浪费：盲目给 HDS 组件套 `.backgroundColor()`（被其内部 token 覆盖），以及反复怀疑主题系统（其实是另一个体系）。

---

## 对应源码（不贴代码）

| 文件 | 关注点 |
|---|---|
| `commons/AppSettings/src/main/ets/view/SchemaSettingsSection.ets` | `@Local theme` 声明；`builtin: 'haptic'`（触感反馈）与 `builtin: 'keepScreenOn'`（屏幕常亮）两处 `SuffixSwitch` 的 `selectColor`；其余 builtin 行（语言/字体/方向/清缓存）作对照 |
| `commons/AppSettings/src/main/ets/view/AppearanceView.ets` | schema 驱动入口（`page: 'appearance'`），说明为什么控件来源可能出乎意料 |
| `commons/AppSettings/src/main/ets/component/AccentColorSetting.ets` | 同页的自绘部分（对比：它为什么一直是对的） |
| 本机 SDK `@hms.hds.hdsBaseComponent.d.ets` | `CheckOptions.selectColor?: ResourceColor` 的权威出处（不在仓库内，需按 SDK 路径查阅） |

## 配图

| 截图 | 说明 |
|---|---|
| `assets/G2-toggle-on-teal.png` | 修复后：分栏右栏「触感反馈」开关 ON 轨道为青碧 `#12A594` |
| `assets/C2-hds-teal.png` | 未跟随部分：切青碧后 HDS 行卡片底色/分割线/chevron 仍为中性灰 |

## 需复核 / 已知限制

- `HdsTabs` 页签选中色是否可显式传色：**需复核**（本章未查其样式参数）。
- `HdsListItemCard` 的 `HdsListItemCardModifier` 具体可覆盖项：**需复核**（未逐项验证）。
- 「设置域 builtin 行剩余迁移」：设置页仍有若干 builtin 行未接入显式传色路径 → 属遗留项，影响第 13 章「100% 跟随」的达成判定。
- `C2-hds-teal.png` 的判读依据是「行卡片/分割线/chevron 保持中性灰」；若要作为严格 A/B 证据，需补一张**同页、同滚动位置、品牌蓝主题**的对照图 → **待补**。

## 版本注记

- 坑 7 修复：v3.46（`SuffixSwitch.selectColor` + `@Local theme`），对应 versionCode 1000031 的走查修复。
- 此前 `ThemeControl` 对 HDS 私有 token 无效这一结论，已由真机 A/B 证实并记录。
