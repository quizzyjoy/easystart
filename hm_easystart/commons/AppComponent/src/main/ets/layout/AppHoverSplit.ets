import { AppFoldStatus, HoverStore } from '@quizzyjoy/platform';

/**
 * AppHoverSplit —— 折叠屏悬停态分屏容器（v3.31，对标 `hmos-multidevice-fold-state`
 * 的 SCENE-02 / FOLD-01「悬停态分屏」）。
 *
 * 【为什么在 AppComponent】上/下分区的对齐律与折痕留白属应用规范 → 应用级
 * （AppSection / AppCard 同档）。
 *
 * 【实现路线：自定义分屏（官方方案三），而非 FolderStack】
 * 官方首选是系统 `FolderStack`（`hmos-multidevice-fold-state/references/hover_state_interaction.md` 方案一），
 * 但它有两条硬约束：①父节点不能是 if/else 条件渲染节点；②**必须撑满页面全屏**。
 * 本工程实测（bp_fold 模拟器，2026-10-18）：
 * - 把演示页放进独立 Ability、页面根直接渲染 FolderStack，`onHoverStatusChange` 仍**从未触发**；
 * - `ui layout --mode full` 显示 `Folder` bounds = `[0,122,2224,2409]`——顶部被状态栏占 122px、
 *   底部被导航条占 87px，**不满足「撑满全屏」**；`setWindowLayoutFullScreen(true)` 只补了底部。
 * 因此改用方案三：读取 HoverStore 已实采的 `foldStatus` 与折痕几何，按折痕边界自行分区。
 * 好处是行为可预测、可自动化验证，且不依赖窗口能否被占满。
 *
 * 【分屏规则（悬停态 / HALF_FOLDED）】
 * - 上区高度 = 折痕上沿 `creaseTopVp`（实测 340vp）；
 * - 折痕留白 = `creaseHeightVp`（实测 55vp），保证内容不跨折痕（FOLD-02 联动）；
 * - 下区 = 剩余高度（`layoutWeight(1)`）。
 * 折痕数据缺失（非折叠设备 / 读取失败）时回退 50% + 24vp 留白，仍保持上下分区。
 *
 * 【非悬停态】退化为 Stack：上区铺满、下区贴底（等价常规单页 + 底部操作条）。
 *
 * 【方向】本组件不改方向策略；悬停态旋转由系统（`autoHalfFold` 场景）或调用方
 * `setPreferredOrientation` 决定，组件只按当前折痕方向做上下分区。
 *
 * 【用法】两个插槽均具名传参（ArkTS：多个 @BuilderParam 不能用尾随闭包）：
 * ```
 * AppHoverSplit({
 *   upperContent: (): void => { this.playerArea() },
 *   lowerContent: (): void => { this.controlBar() }
 * })
 * ```
 */
@ComponentV2
export struct AppHoverSplit {
  /** 上半屏（非悬停态 = 铺满整页）。 */
  @BuilderParam upperContent: () => void = this.emptyContent;
  /** 下半屏（非悬停态 = 贴底叠加于页面上）。 */
  @BuilderParam lowerContent: () => void = this.emptyContent;
  /** 悬停态几何：兜底上区高度（vp，折痕不可读时使用）。 */
  @Param fallbackUpperVp: number = 300;
  /** 悬停态几何：兜底折痕留白（vp）。 */
  @Param fallbackCreaseVp: number = 24;

  /** 折痕 / 折叠态数据源（Platform 已 attach，display 级事件）。 */
  @Local fold: HoverStore = HoverStore.getInstance();

  @Builder
  emptyContent() {
  }

  /** 当前是否悬停态（半折叠）。 */
  private isHoverMode(): boolean {
    return this.fold.foldStatus === AppFoldStatus.HALF_FOLDED;
  }

  /** 上区高度：优先取真实折痕上沿，缺失时回退。 */
  private upperHeightVp(): number {
    return this.fold.creaseTopVp > 0 ? this.fold.creaseTopVp : this.fallbackUpperVp;
  }

  /** 折痕留白高度：优先取真实折痕高度，缺失时回退。 */
  private creaseHeightVp(): number {
    return this.fold.creaseHeightVp > 0 ? this.fold.creaseHeightVp : this.fallbackCreaseVp;
  }

  build() {
    Column() {
      if (this.isHoverMode()) {
        // 悬停态：上区 → 折痕留白 → 下区（内容不跨折痕）
        Column() {
          this.upperContent()
        }
        .width('100%')
        .height(`${this.upperHeightVp()}vp`)

        Blank()
          .width('100%')
          .height(`${this.creaseHeightVp()}vp`)

        Column() {
          this.lowerContent()
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        // 非悬停态：Stack 语义——上区铺满，下区贴底
        Stack({ alignContent: Alignment.Bottom }) {
          Column() {
            this.upperContent()
          }
          .width('100%')
          .height('100%')

          Column() {
            this.lowerContent()
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
