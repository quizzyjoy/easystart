import { AppFontSize, AppSpacing, AppRadius, AppSize } from '@quizzyjoy/foundation';
import { SkeletonBlock } from './SkeletonBlock';
import { VitalActionButton, VitalActionVariant } from './VitalActionButton';

/** 底部加载指示器边长（vp）——与 CommonButton 内嵌菊花同视觉档，命名保形。 */
const FOOTER_INDICATOR_SIZE: number = 18;

/** 列表数据状态机。 */
export enum ListStatus {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  EMPTY = 'empty',
  ERROR = 'error'
}

/**
 * RefreshList —— 下拉刷新 + 上拉加载 + 四态（加载/成功/空/错误）统一容器。
 *
 * 刷新控制：内部 @Local isRefreshing 驱动 Refresh；
 * 状态机回到终态（SUCCESS / EMPTY / ERROR）时由 @Monitor 自动收起刷新指示器，
 * 不使用 $$ 双向绑定，规避 V2 语法风险。
 *
 * 注意：ArkTS 自定义组件不支持泛型，故 items 使用 Object[]，
 * 行渲染由 itemBuilder 负责向下转型。
 */
@ComponentV2
export struct RefreshList {
  /** 列表数据（ArkTS 自定义组件不支持泛型，行为 Object[]，行渲染向下转型）。 */
  @Param items: Object[] = [];
  /** 列表状态机（LOADING 且 items 为空时显示骨架屏；终态自动收起刷新指示器）。 */
  @Param status: ListStatus = ListStatus.IDLE;
  /** 是否还有更多数据（false 且非空时 footer 显示「没有更多了」）。 */
  @Param hasMore: boolean = true;
  /**
   * 行键生成器（可选）：默认按索引；当数组替换后同索引行内容会变
   * （如断点切换导致栅格行重新分块）时必须传内容键——ArkUI ForEach
   * 同键复用旧节点且不重执行 itemBuilder，索引键会保留旧行内容。
   */
  @Param keyOf: ((item: Object, index: number) => string) | undefined = undefined;
  /** 下拉刷新回调（触发时指示器由组件内部接管）。 */
  @Event onRefresh: () => void = () => {
  };
  /** 触底加载更多回调（LOADING 中不重复触发）。 */
  @Event onLoadMore: () => void = () => {
  };
  /** 错误态「重试」按钮回调。 */
  @Event onRetry: () => void = () => {
  };
  /** 行构建器。 */
  @BuilderParam itemBuilder: (item: Object, index: number) => void;

  @Local isRefreshing: boolean = false;

  @Monitor('status')
  onStatusChange(): void {
    if (this.status !== ListStatus.LOADING) {
      this.isRefreshing = false;
    }
  }

  @Builder
  private initialLoading() {
    Column({ space: AppSpacing.MD }) {
      SkeletonBlock({ heightValue: AppSize.TOUCH_STANDARD, radius: AppRadius.LG })
      SkeletonBlock({ heightValue: AppSize.TOUCH_STANDARD, radius: AppRadius.LG })
      SkeletonBlock({ heightValue: AppSize.TOUCH_STANDARD, radius: AppRadius.LG })
      SkeletonBlock({ widthValue: '60%', heightValue: AppSize.TOUCH_STANDARD, radius: AppRadius.LG })
    }
    .width('100%')
    .padding(AppSpacing.LG)
  }

  @Builder
  private placeholderLine(title: string, description: string, retryable: boolean) {
    Column({ space: AppSpacing.SM }) {
      Text(title)
        .fontSize(AppFontSize.BODY)
        .fontColor($r('app.color.app_text_primary'))
      Text(description)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
      if (retryable) {
        VitalActionButton({
          text: '重试',
          variant: VitalActionVariant.SECONDARY,
          onAction: () => {
            this.onRetry();
          }
        })
      }
    }
    .width('100%')
    .padding(AppSpacing.XXXL)
  }

  @Builder
  private footer() {
    if (this.status === ListStatus.LOADING && this.items.length > 0) {
      Row({ space: AppSpacing.SM }) {
        LoadingProgress()
          .width(FOOTER_INDICATOR_SIZE)
          .height(FOOTER_INDICATOR_SIZE)
          .color($r('app.color.app_text_tertiary'))
        Text('加载中…')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(AppSpacing.LG)
    } else if (!this.hasMore && this.items.length > 0) {
      Row() {
        Text('没有更多了')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(AppSpacing.LG)
    }
  }

  build() {
    if (this.status === ListStatus.LOADING && this.items.length === 0) {
      this.initialLoading()
    } else if (this.status === ListStatus.ERROR && this.items.length === 0) {
      this.placeholderLine('加载失败', '请检查网络后重试', true)
    } else if (this.status === ListStatus.EMPTY
      || (this.status === ListStatus.SUCCESS && this.items.length === 0)) {
      this.placeholderLine('暂无数据', '下拉刷新试试', false)
    } else {
      Refresh({ refreshing: this.isRefreshing }) {
        List() {
          ForEach(this.items, (item: Object, index: number) => {
            ListItem() {
              this.itemBuilder(item, index)
            }
          }, (item: Object, index: number) => {
            if (this.keyOf !== undefined) {
              return this.keyOf(item, index);
            }
            return `${index}`;
          })
          ListItem() {
            this.footer()
          }
        }
        .width('100%')
        .height('100%')
        .onReachEnd(() => {
          if (this.hasMore && this.status !== ListStatus.LOADING) {
            this.onLoadMore();
          }
        })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .onRefreshing(() => {
        this.isRefreshing = true;
        this.onRefresh();
      })
      .width('100%')
      .height('100%')
    }
  }
}
