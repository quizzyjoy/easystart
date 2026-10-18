import { AppButtonPrimaryModifier, AppHoverSplit, AppSection } from '@easystart/app-component';
import { AppFontSize, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { AppFoldStatus, HoverStore } from '@quizzyjoy/platform';

/**
 * 样例子页 ⑦：悬停态分屏（v3.31，对标 `hmos-multidevice-fold-state` 的 SCENE-02 / FOLD-01）。
 *
 * 【fork 可整体复制的页面范式】折叠屏半折叠（帐篷状）时，把「展示区 + 操作区」拆到
 * 折痕上下两侧：上屏内容、下屏操作。分屏本体是 AppHoverSplit（**自定义分屏实现**，
 * 按 HoverStore 实采的折痕几何分区，不依赖系统 FolderStack 的窗口条件）。
 *
 * 【为什么不用官方 FolderStack】实测（bp_fold）其两条硬约束难以满足：
 * ①父节点不能是 if/else 条件渲染节点（本页位于 pageMap 的 if 分支内）；
 * ②必须撑满页面全屏（实测 Folder bounds 仅 `[0,122,2224,2409]`，被状态栏/导航条挤掉）。
 * 详见 AppHoverSplit 头注释。
 *
 * 【页面结构】常规单页（上区铺满 + 下区贴底）；悬停态自动按折痕上沿分区。
 */
@ComponentV2
export struct HoverSplitView {
  @Local fold: HoverStore = HoverStore.getInstance();
  /** 下屏操作按钮点击计数（验证下屏可交互，不依赖 Toast 装配）。 */
  @Local tapCount: number = 0;

  private foldLabel(): string {
    switch (this.fold.foldStatus) {
      case AppFoldStatus.HALF_FOLDED:
        return '悬停态（半折叠）';
      case AppFoldStatus.EXPANDED:
        return '展开态';
      case AppFoldStatus.FOLDED:
        return '折叠态';
      case AppFoldStatus.EXPANDED_WITH_SECOND_EXPANDED:
        return '三折叠 · 双展开';
      case AppFoldStatus.FOLDED_WITH_SECOND_EXPANDED:
        return '三折叠 · 折叠 + 次展开';
      default:
        return '未知（非折叠设备降级）';
    }
  }

  @Builder
  upperArea() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        AppSection({
          sectionTitle: '悬停态分屏（FOLD-01）',
          description: '把设备折成帐篷状（半折叠）：上半屏是本内容区，下半屏是操作区，中间按折痕真实高度留白。'
        })

        Column({ space: AppSpacing.XS }) {
          Text(`当前折叠形态：${this.foldLabel()}`)
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
            .width('100%')
          Text(`折痕：上沿 ${this.fold.creaseTopVp}vp · 高度 ${this.fold.creaseHeightVp}vp`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
          Text(this.fold.isFoldable ? '设备可折叠：是' : '设备可折叠：否（非折叠设备上退化为上下堆叠）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
          Text(`分屏判定：${this.fold.foldStatus === AppFoldStatus.HALF_FOLDED
            ? '悬停态（已按折痕上沿分区）'
            : '非悬停态（单页布局）'}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(AppSpacing.MD)
        .borderRadius(AppRadius.XL)
        .backgroundColor($r('app.color.app_bg_card'))

        AppSection({
          sectionTitle: '验证方式',
          description: '模拟器：使用模拟器自带折叠模拟切「悬停态」；真机：把手机折成 L 形（帐篷）。分区高度取折痕真实几何，不写死比例。'
        })

        AppSection({
          sectionTitle: '实现要点',
          description: 'AppHoverSplit 读取 HoverStore 的 foldStatus 与折痕上沿/高度：悬停态按折痕分区、折痕处留白；非悬停态退化为上铺满 + 下贴底。'
        })

        Column()
          .width('100%')
          .height(DesignToken.cardPadding() * 8)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: DesignToken.pagePadding('sm'),
        right: DesignToken.pagePadding('sm'),
        top: AppSpacing.LG,
        bottom: AppSpacing.XXXL
      })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
  }

  @Builder
  lowerArea() {
    Column({ space: AppSpacing.SM }) {
      Button(`操作区按钮（下屏）· 已点 ${this.tapCount} 次`)
        .attributeModifier(new AppButtonPrimaryModifier())
        .onClick(() => {
          this.tapCount++;
        })
      Text('悬停态下本区落在折痕下方；展开态时它贴底叠加于页面之上')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({
      left: DesignToken.pagePadding('sm'),
      right: DesignToken.pagePadding('sm'),
      bottom: AppSpacing.XXXL
    })
  }

  build() {
    Column() {
      AppHoverSplit({
        upperContent: (): void => {
          this.upperArea();
        },
        lowerContent: (): void => {
          this.lowerArea();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
  }
}
