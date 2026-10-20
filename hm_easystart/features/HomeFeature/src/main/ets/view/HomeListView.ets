import { ActionCard } from '@easystart/app-component';
import { ListStatus, RefreshList, ViewState } from '@quizzyjoy/vitalui';
import { AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { HomeItem } from '../data/HomeRepository';
import { HomeViewModel } from '../viewmodel/HomeViewModel';

/**
 * 栅格行模型：把 columns(breakpoint) 列卡片打包成一个 RefreshList 行。
 * RefreshList 不支持泛型（items 为 Object[]），行内 instanceof 收窄。
 */
class HomeCardRow {
  cards: HomeItem[] = [];

  constructor(cards: HomeItem[]) {
    this.cards = cards;
  }
}

/**
 * 首页视图：响应式卡片栅格 + 下拉刷新 + 四态。
 *
 * 由入口装配（TabContent / 分栏均可），本组件不感知导航——
 * 打开详情经 @Event onOpenDetail 上抛，由入口注入 RouterManager 跳转。
 * RefreshList 的 items 为 Object[]，行内用 instanceof 收窄取字段。
 * 带参数的 @BuilderParam 不能用尾随闭包初始化（ArkTS 限制），
 * 必须以参数形式传入，并用箭头包裹保持 this 指向本组件。
 * 布局走 DesignToken 响应式令牌：pagePadding/contentMaxWidth 随断点伸缩，
 * 宽屏内容限宽居中（ListStateView 同范式）；列数走 HomeViewModel.columns
 * （xs/sm 单列、md 两列、lg/xl 三列），行内卡片 cardGap、行间 listItemSpacing。
 */
@ComponentV2
export struct HomeListView {
  @Local viewModel: HomeViewModel = new HomeViewModel();
  /** 断点注册表（pagePadding/contentMaxWidth/columns 令牌入参）。 */
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 窗口适配器（tabPageBottomPadding 的底部避让高度入参）。 */
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 点击卡片打开详情（入口注入跳转实现；feature 不感知导航）。 */
  @Event onOpenDetail: (item: HomeItem) => void = () => {
  };

  aboutToAppear(): void {
    this.viewModel.load();
  }

  private listStatus(): ListStatus {
    if (this.viewModel.viewState === ViewState.LOADING) {
      return ListStatus.LOADING;
    }
    if (this.viewModel.viewState === ViewState.EMPTY) {
      return ListStatus.EMPTY;
    }
    if (this.viewModel.viewState === ViewState.ERROR) {
      return ListStatus.ERROR;
    }
    return ListStatus.SUCCESS;
  }

  private openDetail(card: HomeItem): void {
    this.viewModel.select(card.id);
    this.onOpenDetail(card);
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 按断点列数把 items 打包成栅格行（build 期求值，items/断点变化即重算）。 */
  private gridRows(): Object[] {
    const columns: number = this.viewModel.columns(this.bp());
    const source: HomeItem[] = this.viewModel.items;
    const rows: Object[] = [];
    for (let i = 0; i < source.length; i += columns) {
      const chunk: HomeItem[] = [];
      const end: number = Math.min(i + columns, source.length);
      for (let j = i; j < end; j++) {
        chunk.push(source[j]);
      }
      rows.push(new HomeCardRow(chunk));
    }
    return rows;
  }

  /** 栅格行内容键：行内卡片 id 组合（断点重分块后键必变，强制 ForEach 重建行节点）。 */
  private rowKey(item: Object, index: number): string {
    if (item instanceof HomeCardRow) {
      return item.cards.map((card: HomeItem) => card.id).join('+');
    }
    return `${index}`;
  }

  build() {
    Column() {
      Column() {
        RefreshList({
          items: this.gridRows(),
          keyOf: (item: Object, index: number): string => {
            return this.rowKey(item, index);
          },
          status: this.listStatus(),
          hasMore: false,
          onRefresh: () => {
            this.viewModel.load();
          },
          onRetry: () => {
            this.viewModel.load();
          },
          itemBuilder: (item: Object, index: number) => {
            this.itemRow(item, index)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.app_bg_page'))
  }

  @Builder
  itemRow(item: Object, index: number) {
    if (item instanceof HomeCardRow) {
      Row({ space: DesignToken.cardGap() }) {
        ForEach(item.cards, (card: HomeItem) => {
          ActionCard({
            title: card.title,
            subtitle: card.description,
            onAction: () => {
              this.openDetail(card);
            }
          })
          .layoutWeight(1)
          // 鼠标 / 触控板悬浮高亮（v3.31）：系统 Highlight 属渲染层效果，不侵入
          // ActionCard 内部令牌；触屏设备无 hover 事件，零副作用。
          .hoverEffect(HoverEffect.Highlight)
        }, (card: HomeItem) => card.id)
      }
      .width('100%')
      .margin({ bottom: DesignToken.listItemSpacing() })
    }
  }
}
