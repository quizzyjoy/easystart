import { CommonLoading, FeedbackText, ListStatus, LoadingVariant, RefreshList, StateContainer, ViewState } from '@quizzyjoy/vitalui';
import { ActionCard, ButtonVariant, CommonButton } from '@easystart/app-component';
import { AppSection, AppTextDisplayModifier, CommonToast } from '@easystart/app-component';
import { AppFontSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';

/**
 * 样例子页 ⑤：列表四态（v3.9）。
 *
 * 【fork 可整体复制的页面范式】列表页状态机：StateContainer 四态切换 +
 * RefreshList 下拉刷新/上拉加载（ListStatus 状态机流转）。fork 后把
 * mockLoad 换成真实 Repository 即可。
 *
 * 【@BuilderParam 规则】RefreshList.itemBuilder 带参数，不能用尾随闭包，
 * 以参数传入并用箭头包裹保持 this 指向（HomeListView 先例）。
 */

/** 模拟网络耗时（ms）——示例数据值，非样式值，不涉 v3.7 豁免登记。 */
const MOCK_LOAD_MS: number = 800;
/** 首页条数与追加条数（示例分页）。 */
const PAGE_SIZE: number = 6;

/** 示例列表行模型（instanceof 收窄取字段，HomeItem 先例）。 */
class DemoListItem {
  title: string = '';
  subtitle: string = '';

  constructor(title: string, subtitle: string) {
    this.title = title;
    this.subtitle = subtitle;
  }
}

@ComponentV2
export struct ListStateView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** StateContainer 四态（态切换行驱动）。 */
  @Local viewState: ViewState = ViewState.LOADING;
  /** RefreshList 状态机（刷新/加载更多流转）。 */
  @Local listStatus: ListStatus = ListStatus.IDLE;
  /** 列表数据（RefreshList 契约：Object[]，行内 instanceof 收窄）。 */
  @Local items: Object[] = [];
  private mockTimer: number = -1;

  aboutToAppear(): void {
    this.mockLoad();
  }

  aboutToDisappear(): void {
    if (this.mockTimer !== -1) {
      clearTimeout(this.mockTimer);
      this.mockTimer = -1;
    }
  }

  /** 模拟首屏/刷新加载（LOADING → CONTENT）。 */
  private mockLoad(): void {
    this.viewState = ViewState.LOADING;
    this.mockTimer = setTimeout(() => {
      this.mockTimer = -1;
      const first: Object[] = [];
      for (let i = 0; i < PAGE_SIZE; i++) {
        first.push(new DemoListItem(`条目 ${i + 1}`, '下拉可刷新，滚动到底部加载更多'));
      }
      this.items = first;
      this.viewState = ViewState.CONTENT;
      this.listStatus = ListStatus.SUCCESS;
    }, MOCK_LOAD_MS);
  }

  /** 模拟追加一页（最多 18 条后 hasMore=false）。 */
  private mockLoadMore(): void {
    this.listStatus = ListStatus.LOADING;
    this.mockTimer = setTimeout(() => {
      this.mockTimer = -1;
      const base: number = this.items.length;
      const remain: number = Math.min(PAGE_SIZE, 18 - base);
      for (let i = 0; i < remain; i++) {
        this.items.push(new DemoListItem(`条目 ${base + i + 1}`, '追加页数据'));
      }
      this.listStatus = ListStatus.SUCCESS;
    }, MOCK_LOAD_MS);
  }

  /** 模拟错误恢复（ERROR 重试 → LOADING → CONTENT）。 */
  private mockRetry(): void {
    this.mockLoad();
  }

  private titleOf(item: Object): string {
    if (item instanceof DemoListItem) {
      return item.title;
    }
    return '';
  }

  private subtitleOf(item: Object): string {
    if (item instanceof DemoListItem) {
      return item.subtitle;
    }
    return '';
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  pageHeader() {
    Column({ space: AppSpacing.XS }) {
      Text('StateContainer 加载/空/错误/内容 + RefreshList 刷新与分页状态机。')
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  listRow(item: Object, index: number) {
    ActionCard({
      title: this.titleOf(item),
      subtitle: this.subtitleOf(item),
      onAction: () => {
        CommonToast.info(`点击：${this.titleOf(item)}`);
      }
    })
    .margin({ bottom: DesignToken.listItemSpacing() })
  }

  build() {
    Column() {
      Column() {
        this.pageHeader()

        AppSection({ sectionTitle: '态切换', description: 'LOADING / EMPTY / ERROR / CONTENT 四态一键切换（示例 StateContainer 契约）' }) {
          Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
            CommonButton({
              text: '加载中',
              variant: this.viewState === ViewState.LOADING ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
              onAction: () => {
                this.viewState = ViewState.LOADING;
              }
            })
            CommonButton({
              text: '空态',
              variant: this.viewState === ViewState.EMPTY ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
              onAction: () => {
                this.viewState = ViewState.EMPTY;
              }
            })
            CommonButton({
              text: '错误',
              variant: this.viewState === ViewState.ERROR ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
              onAction: () => {
                this.viewState = ViewState.ERROR;
              }
            })
            CommonButton({
              text: '内容',
              variant: this.viewState === ViewState.CONTENT ? ButtonVariant.PRIMARY : ButtonVariant.SECONDARY,
              onAction: () => {
                this.viewState = ViewState.CONTENT;
              }
            })
          }
          .width('100%')
          Text(`当前态：${this.viewState}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
            .margin({ top: AppSpacing.SM })
        }

        if (this.viewState === ViewState.LOADING) {
          CommonLoading({ variant: LoadingVariant.DOTS, text: '加载中…' })
            .margin({ top: AppSpacing.LG })
        }

        Column() {
          StateContainer({
            state: this.viewState,
            emptyText: new FeedbackText('暂无数据', '切换到「内容」态查看列表示例', ''),
            errorText: new FeedbackText('加载失败', '请检查网络后重试', '重试'),
            onRetry: () => {
              this.mockRetry();
            }
          }) {
            RefreshList({
              items: this.items,
              status: this.listStatus,
              hasMore: this.items.length < 18,
              onRefresh: () => {
                this.mockLoad();
              },
              onLoadMore: () => {
                this.mockLoadMore();
              },
              onRetry: () => {
                this.mockRetry();
              },
              itemBuilder: (item: Object, index: number) => {
                this.listRow(item, index)
              }
            })
          }
        }
        .layoutWeight(1)
        .width('100%')
        .margin({ top: AppSpacing.MD })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
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
}
