# ArkTS 状态管理：V1 → V2

本工程全量使用状态管理 V2。V1 的 `@State` / `@Prop` / `@Link` 加 `@Observed` / `@ObjectLink` 组合已被 V2 取代：V2 观测粒度更细（属性级）、跨组件代理更强、派生值有专门装饰器。两者不能混用——同一个组件里出现 V1 与 V2 装饰器会直接编译报错，所以迁移必须按组件逐个完成。

## 装饰器对照

- `@State` → `@Local`：组件内部可变状态，只能在组件内初始化
- `@Prop` → `@Param`：父传子的只读入参，子组件不得赋值
- `@Link` 双向绑定 → `@Param` + `@Event`：子组件上抛事件，由父组件改状态
- `@Observed` + `@ObjectLink` → `@ObservedV2` + `@Trace`：属性级观测，自动逐层代理
- `@Watch` → `@Monitor`：监听指定表达式的变化
- 新增 `@Computed`：派生值，随依赖变化自动重算

## V1 写法（本工程已无此形态，仅作对照）

```ts
@Observed
class Profile {
  name: string = '游客';
}

@Component
struct HeaderView {
  @Prop title: string = '';
  @Link count: number = 0;      // 双向绑定
  @State expanded: boolean = false;
}
```

## V2 写法（本工程 commons/AppSettings/view/DeveloperView.ets 的真实片段）

```ts
@ComponentV2
export struct DeveloperView {
  @Local profile: DeveloperProfile = new DeveloperProfile(...);
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local qrVisible: boolean = false;
}
```

## 父子通信：单向数据流

父子通信改成了单向数据流：`@Param` 只读入参 + `@Event` 回调上抛。本工程所有子页都按这个接法——子组件不碰路由、不碰父状态，只把「用户点了什么」告诉父组件。

```ts
// 子组件：只读入参 + 事件上抛
@Param onOpenDetail: (item: HomeItem) => void = (item: HomeItem): void => {};

// 用户点击 → 只上报，不改自己也不改父
this.onOpenDetail(item);
```

## 嵌套对象：属性级观测

嵌套对象靠 `@ObservedV2` + `@Trace` 做到属性级观测。本工程 `SettingsViewModel` 是典型：一个全局单例被多个设置子页共享，任一属性变化，所有绑定的页面一起刷新。

```ts
@ObservedV2
export class SettingsViewModel {
  @Trace colorMode: number = 0;   // 属性级观测，跨子页共享
}
```

## 五个高频坑

- V1/V2 混用：`@ComponentV2` 里写 `@State` 直接编译失败，迁移按组件整块换，不要逐个装饰器试
- `@Param` 只读：子组件赋值会报 read-only property，改状态一律回父组件
- `@Local` 只代理第一层：嵌套对象内部变化不触发刷新，用 `@ObservedV2` / `@Trace` 或整体换引用
- `ForEach` 必须给稳定业务 key（用 id 不用索引），否则增删时复用错位、动画乱跳
- 普通方法不在依赖追踪链上：派生值放 `@Computed`，否则状态变了文本不刷新

## 迁移顺序

1. 先把装饰器整体换到 V2
2. 再把双向绑定拆成 `@Param` + `@Event`
3. 最后处理嵌套对象的观测

编译器报错带精确的 `文件:行:列`，按报错逐个改比通读代码快得多。
