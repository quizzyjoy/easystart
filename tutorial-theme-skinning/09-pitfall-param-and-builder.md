<a id="ch09"></a>

# 第 9 章 坑 3–4：`@Param` 默认值读单例不响应，顶层 `@Builder` 用不了 `this`

> 本章成稿目标字数：2000–2800 ｜ 预计阅读 10 分钟 ｜ 前置：第 5 章、第 8 章

## 本章要解决的问题

这两个坑的共同点是：**代码看起来完全正确，编译器也不报错，但就是不刷新。**

- **坑 3**：把主题色写在 `@Param` 的**默认值**里 → 首次求值后固定。
- **坑 4**：在**顶层 `@Builder`** 里想读单例 / 用 `this` → 两者都不存在。

## 读者收获

1. 掌握一条判定信号：「改色后重建页面就对了」= 求值时机问题；
2. 知道 `@Param` 默认值不参与依赖收集，必须把读取搬进 `build` 或取色方法；
3. 掌握「内容对象注入」这个让无上下文 `@Builder` 拿到主题色的标准手法。

---

## 坑 3：`@Param` 默认值读单例，改色不响应

### 现象

组件这么写（**错误示范，仅 1 行**）：

```
@Param accentColor: string = UiThemeManager.getInstance().effectiveAccent();
```

第一次渲染颜色是对的（当前主题色）。之后在任何页面改主题色：**这个组件的颜色不动**。但如果切到别的页面再回来（组件重建），颜色就对了。

### 根因：默认值只在实例化时求值一次

`@Param` 的默认值是**表达式**，在**创建组件实例时求值一次**，把结果赋给参数。它带来两个后果：

1. **值被固化**：后续单例变化不会回写到这个参数（参数只由父组件传入才会更新）；
2. **不建立依赖**：依赖收集发生在**读取 `@Trace` 字段的那次 `build` 执行**中。在「实例化求值」阶段读，不属于渲染期的读取，**不会被记入依赖图**。

所以这不是「响应式写法错了」，而是「用了求值时机不对的地方去读一个可观察值」。

### 正解：`@Local` 持有单例，读取发生在渲染期

```
@Local theme = UiThemeManager.getInstance();     // 持有的是对象本身
取色方法() { return this.theme.brandColor(); }    // 读取发生在 build 调用链中
```

区别的关键：`@Local theme` 持有的是**对象引用**，`build` 执行时通过 `this.theme.brandColor()` 访问 `@Trace` 字段——这次访问发生在渲染期，依赖被正确记录，改色即重渲染。

这就是为什么 `CommonButton` 的写法是「`@Local theme` + `@Param accentColor` 双持」而不是「`@Param` 默认值读单例」（第 5 章 §5.8）。

### 一条可复用的判定信号

> **「改色后，重建页面/重进页面就对了」→ 求值时机问题；「重建也不对」→ 根本没连上（坑 2）。**

这条信号能把 90% 的「主题不生效」问题在 5 分钟内分流。

### 顺带一个同类陷阱：`@Builder` 参数按值传递

同源的坑还有 `@Builder` 的参数传递：**带值参数的 `@Builder` 调用会把值按值捕获**，父组件状态更新不会让它重算。表现是「点了按钮，`@Builder` 里的东西不跟着变」。

修法同理：**要么把读取搬进 `build` 内联**，要么**改传对象/回调**（对象是引用，字段变化可被观测）。本仓在动效演示页踩过这个坑（曲线方块点击不动），根因即此。

---

## 坑 4：顶层 `@Builder` 不能用 `this`，也读不到单例

### 现象

一个全局悬浮球（`AppOverlay`）的品牌圆钮，无论怎么换主题，**底色恒为默认品牌蓝**。

### 根因：顶层 `@Builder` 是「无组件上下文的函数」

`@Builder` 定义在文件顶层（不是 `struct` 成员）时：

1. **没有 `this`**——它不是组件方法，没有实例；
2. **不能在渲染期建立对单例的依赖**——它不属于任何组件的渲染作用域；
3. 它通常通过 `ComponentContent` / `wrapBuilder` 从**组件外部**注入，连父级状态都拿不到。

于是任何「在 builder 里读主题色」的尝试都会失败——不是写法问题，是**上下文不存在**。

### 正解：内容对象注入（把「读色」搬到有上下文的一侧）

三步走：

**① 定义内容对象**（纯数据，含主题色字段）：

```
class AppFloatingBallContent {
  tint: ResourceColor = $r('app.color.qj_brand');    // 默认值只做兜底
  onTint: ResourceColor = $r('app.color.qj_on_brand');
}
```

**② builder 只消费字段，不读单例**：`appFloatingBallBuilder(content)` 内部用 `content.tint` / `content.onTint`。

**③ 调用侧（有组件上下文）填值**：

```
const theme = UiThemeManager.getInstance();
content.tint = theme.brandColor();
content.onTint = theme.onBrandColor();
// 再交给 ComponentContent 注入
```

这样「读取」发生在有上下文的一侧，「渲染」发生在无上下文的一侧，两侧通过**内容对象**这一份数据结构解耦。

源码注释把这条约束写得很清楚：

> `@Builder` 是顶层函数、不能读单例也不能用 `this`，故由 `show()` 侧读主题注入。

### 补充：内容对象变了，builder 会跟着变吗

**不会自动变。** 这是坑 3 的同一机制的延伸：`ComponentContent` 一旦构建，builder 的参数按值捕获，字段后续变化不会触发重绘。

所以「悬浮球颜色」这类场景的正确预期是：**在下一次 `show()`（重建 `ComponentContent`）时取到新色**。若产品要求「开着悬浮球时切主题也立即变色」，就需要在切色后主动重建 `ComponentContent`——代价与收益需单独评估。

### 同类样本：`splitPlaceholderBuilder`

`Index.ets` 里的分栏空态占位也是**顶层 `@Builder`**，它内部只用 `$r(...)`、不读单例、不用 `this`——这是「知道约束并主动规避」的写法，可作对照样本。

---

## 两个坑的对照表

| | 坑 3 | 坑 4 |
|---|---|---|
| 载体 | `@Param` 默认值 | 顶层 `@Builder` |
| 为什么失效 | 求值时机不在渲染期，依赖未被记录 | 没有组件上下文，无法建立依赖 |
| 重建后是否恢复 | ✅ 会恢复 | ✅ 会在下一次构建时取到 |
| 修法 | `@Local` 持有单例 + 渲染期读取 | 内容对象注入（读取搬到调用侧） |
| 判定信号 | 重建就好 | builder 里的色永远不变 |

---

## 对应源码（不贴代码）

| 文件 | 关注点 |
|---|---|
| `commons/AppComponent/src/main/ets/feedback/AppOverlay.ets` | 坑 4 完整样本：内容对象字段 `tint` / `onTint`、顶层 builder 只消费字段、`show()` 侧填值 |
| `product/entry/src/main/ets/pages/Index.ets` | 对照样本：`splitPlaceholderBuilder` 顶层 builder 只用 `$r` |
| `quizzyjoy/VitalUI/src/main/ets/component/CommonButton.ets` | 坑 3 正解样本：`@Local theme` + 渲染期读取 |
| `commons/AppComponent/src/main/ets/**/App*`（控件工厂） | 同范式批量应用 |

## 配图

| 截图 | 说明 |
|---|---|
| `assets/A8-components-teal2.png` | 修复后组件页整体效果（含原语与工厂两类组件同色） |

## 需复核 / 已知限制

- 悬浮球（`AppOverlay`）的**即时刷新**能力未在真机做「开着球切主题」的对比取证 → **需复核**；当前结论是「下一次 `show()` 生效」。
- 坑 4 的「内容对象字段变更不触发 builder 重绘」由 `ComponentContent` 的构建语义与实机表现共同支撑，**未做逐帧录屏取证** → **需复核**。

## 版本注记

- 坑 3 修复随 v3.44 原语接入一起完成。
- 坑 4 修复于 v3.44/v3.45（悬浮球徽标跟随运行时主题）。
