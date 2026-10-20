<a id="ch01"></a>

# 第 1 章 换肤只变一半的真相：四层颜色模型

> 本章成稿目标字数：2200–3000 ｜ 预计阅读 12 分钟 ｜ 前置：能用 ArkTS 写页面

## 本章要解决的问题

**为什么我在设置页改完颜色，回首页时「一部分变了、一部分没变」？**

这一章不写代码，只解决一个认知问题：把「颜色」拆成四个互不重叠的来源，让你在遇到「没变」时能立刻判断是哪一层没接上，而不是全仓搜索色值。

## 读者收获

1. 能用四层模型给任意一处「没跟着变」的颜色**归位**；
2. 知道为什么不存在「一个大 token 表解决一切」的方案；
3. 能看懂本仓 `theme/` 目录为什么要分「Foundation / Platform / VitalUI / AppComponent」四层放置（第 7 章展开）。

---

## 正文要点

### 1.1 现象：一次改色，四种结果

设置页把品牌色改成青碧（`#12A594`），然后逐页检查，你会同时看到四种结果：

| 观察点 | 结果 | 说明 |
|---|---|---|
| 首页卡片图标底 | **变了** | 走运行时主题单例 |
| 首页大标题 / 正文 | **没变**（本来就该不变） | 文本色属于语义层，不跟品牌色 |
| 空态插画圆底、卡片强调块 | **变了** | 同上（运行时） |
| 统一对话框「确认」按钮 | **变了**（`A9-dialog-teal.png`） | 系统组件默认色被覆盖 |
| 组件示例页的按钮 / 标签 / Toast | **变了**（`A8-components-teal2.png`） | 自绘原语读了注入色 |
| 设置页 HDS 行卡片底色 / 分割线 / chevron | **没变**（`C2-hds-teal.png`） | HDS 私有 token，不吃系统主题（第 11 章） |
| ArkTS 卡片（桌面卡片） | **没变** | 卡片框架只有 V1，接不上 V2 单例（第 10 章） |

**同一屏里并存「变」与「不变」，这就是「只变一半」的观感来源。**

### 1.2 为什么会这样：颜色有四个来源，且互不覆盖

把「某个像素最终是什么颜色」拆开，会落到四个不同的决策点：

**L1 静态令牌** —— `$r('app.color.qj_brand')`。值在**编译期**由资源限定词（`base` / `dark`）决定。它天然支持深浅色，但**永远不知道你在设置页点了什么**。它的权限边界是「编译期常量」。

**L2 AttributeModifier** —— `class AppXxxModifier implements AttributeModifier<XxxAttribute>`。它是**普通类实例**，不在 ArkUI 的观察依赖图里。它在 `applyNormalAttribute` 里写下什么，就是什么；改主题不会让它重跑，除非页面重建、重新 `new` 一个实例。

**L3 运行时主题** —— `UiThemeManager`（`@ObservedV2` 单例，字段带 `@Trace`）。只有**读了它**的组件才会在它变化时重渲染。这是一种「白名单式」生效：没读的组件保持原样。

**L4 系统组件默认色** —— `ThemeControl.setDefaultTheme(CustomTheme)`。它写的是 ArkUI 内部的 **token 表**，管的是「你没有显式指定颜色」的那些系统组件（对话框按钮、开关选中、填充按钮底色…）。它粒度粗、覆盖广，但对**显式 set 过颜色的属性无效**，对 HDS 私有 token 也无效。

一句话概括四层的权限边界：

> **L1 管编译期、L2 管样式封装、L3 管自绘组件的即时响应、L4 管系统组件的兜底默认。**

四者不互相替代，因为它们管的是**不同的对象**，而不是同一对象的不同优先级。

### 1.3 为什么不能「合并成一个大 token 表」

一个常见的直觉是：把所有颜色都定义成 `app.color.brand`，改主题时改这个资源值——不就全变了吗？

这条路在 HarmonyOS 上走不通，原因有三条（均可验证）：

1. **资源值在编译期固化**，运行期没有「改 `$r` 指向的值」的公开 API；
2. 想模拟这个效果，只能让每处引用都变成「变量」（即 L3 的单例读取），那就等于把 L1 全量迁移到 L3，代价是全仓改动 + 每处都要有观察上下文；
3. 即便全量迁移，**系统组件与 HDS 组件仍不归你管**（它们读自己的 token），L4 依然不可省。

所以正确姿势不是「合并」，而是**分层 + 编排**：L4 兜底系统组件，L3 管自绘组件的即时性，L2 保留个别特调能力，L1 负责语义色与深浅色。

### 1.4 四层与「深浅色」是正交的两件事

初学者最容易混的一点：

- **深浅色**（`ColorModeManager` → 系统 `ColorMode`）决定「底色是白还是黑」；
- **主题/换肤**（本教程的四层）决定「品牌色是什么」。

`A1-appearance.png` 与 `B1-presets-5.png` 是同一页的两种状态：前者主题包是品牌紫、取色块 `#6c4de8`；后者是青碧、取色块 `#12A594`。而两图右上角「显示模式：跟随系统」都没变——**换主题不动显示模式，换显示模式不动主题**。

这条正交性带来一个必然要求：L4 的 `CustomTheme` 必须**同时**提供 `colors` 与 `darkColors`。只给 `colors`，暗色模式下就会「亮底亮字」（第 10 章详解）。

### 1.5 本仓怎么把四层放进工程结构

四层不是四个文件，而是**四个不同层次的模块**，这是被依赖规则逼出来的：

```
quizzyjoy/Foundation   ← 纯数据：5 套主题包（零 @kit）
quizzyjoy/Platform     ← @kit 触点收口：AppThemeController（ThemeControl 在这里）
quizzyjoy/VitalUI      ← 零 @kit 的原语库：UiThemeManager 单例 + CommonButton 等
commons/AppComponent   ← 同时依赖 VitalUI + Platform：AppThemeApplier 编排
commons/AppCommon      ← 只读偏好：AppBootstrap.restoreTheme（刻意不依赖 VitalUI）
product/entry*         ← 入口 Ability：调一次 AppThemeApplier.apply
```

关键约束：**VitalUI 不能依赖 Platform**（原语库要保持零 `@kit`），**AppCommon 不能依赖 VitalUI**（手表端要能用）。正是这两条约束，导致「编排」只能落在 `AppComponent`，「读偏好」与「注入表现层」必须拆开——这条设计因果链在第 7 章会完整复盘，它解释了为什么恢复主题要写成 `restoreTheme()` 读 + `apply()` 注入两段。

### 1.6 用这张图判断「谁该修」

遇到「某处颜色没跟着变」时，按顺序自问：

1. 这个颜色是**语义色**（危险/成功/警告）吗？→ 是则**不该变**，收工。
2. 它是**系统组件**（Dialog / Toggle 轨道 / 填充 Button / SnackBar 动作）吗？→ 查 L4（第 6 章）。
3. 它是 **HDS 组件**（`HdsListItemCard` / `HdsTabs` 等）吗？→ L4 未必够，查 HDS 显式传色（第 11 章）。
4. 它是**自绘组件**读的色吗？→ 查它有没有读 `UiThemeManager`（L3，第 5 章）。
5. 它由 **AttributeModifier** 决定吗？→ 查静态中转值（L2，第 4 章）。
6. 以上都不是？→ 它大概率是 L1 硬编码，需要分级（第 3 章）。

---

## 对应源码（不贴代码）

| 文件 | 关注点 |
|---|---|
| `hm_easystart/quizzyjoy/Foundation/src/main/ets/theme/AppThemePreset.ets` | 主题包数据结构（id / label / baseHex）与 5 套内置包 |
| `hm_easystart/quizzyjoy/Platform/src/main/ets/theme/AppThemeController.ets` | 文件头注释即四层关系的权威说明（L1 / L3 / L4 分工） |
| `hm_easystart/quizzyjoy/VitalUI/src/main/ets/theme/UiThemeManager.ets` | 文件头注释列了三层并说明「谁该读谁」 |
| `hm_easystart/commons/AppComponent/src/main/ets/theme/AppThemeApplier.ets` | 编排层的分层理由（为什么放 AppComponent） |

## 配图

| 截图 | 说明 |
|---|---|
| `assets/B2-home-brandblue.png` | 基线：品牌蓝（`#0A59F7`）下的首页 |
| `assets/A5-teal-applied.png` | 切青碧后的外观页（对比用） |
| `assets/A8-components-teal2.png` | 自绘原语（L3）跟随效果 |
| `assets/A9-dialog-teal.png` | 系统对话框（L4）跟随效果 |
| `assets/C2-hds-teal.png` | HDS 组件（不吃 L4）反例 |

## 需复核 / 已知限制

- 本章「四种结果」表格中的每一行都对应后续章节的具体取证截图；若截图更新，需同步回归。
- `#0A59F7` / `#12A594` 等色值来自 `AppThemePreset.ets`，为编译期常量，不应在正文中作为「品牌规范」引用。

## 版本注记

- 结论对应 v3.43（四层建立）～ v3.46（HDS 传色与布局修复）。
- v3.44 曾把「L1 静态色并入 L3」，即页面装饰色改读 `theme.brandColor()`；但**令牌对照页与语义色仍保留 `$r`**，故 L1 层未消失（第 3 章）。
