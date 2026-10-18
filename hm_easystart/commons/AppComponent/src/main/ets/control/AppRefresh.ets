import { AppFontSize, AppSpacing } from '@quizzyjoy/foundation';
import { AppLoadingProgress } from './AppLoadingProgress';

/**
 * AppRefresh —— 主题化下拉刷新（Refresh 简易封装）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * Refresh 是系统容器原语，本身无颜色属性，但其刷新指示器视觉需与全应用统一——
 * 本封装用 builder 自定义刷新区域（AppLoadingProgress 换色转圈 + 可选提示文本），
 * 把「刷新指示器换肤 + 内容插槽 + 刷新回调」收口为应用级范式。换一个 app 刷新
 * 指示器样式就变 → 应用级。
 *
 * 【用法】AppRefresh({ refreshing: this.loading, promptText: '刷新中…',
 *   onRefreshing: (): void => { ...异步刷新后 this.loading = false } }) { 列表内容 }
 * refreshing 经 $$ 双向同步（用户下拉时回写 true，父异步完成后置 false）。
 *
 * 【@kit 纪律】Refresh / Stack / Row / Text 为全局组件类型；零直接 @kit。
 */
@ComponentV2
export struct AppRefresh {
  /** 刷新状态（$$ 双向：下拉回写 true，父完成后置 false）。 */
  @Param refreshing: boolean = false;
  /** 刷新区域提示文本（空串不显示）。 */
  @Param promptText: string = '';
  /** 内容插槽（尾随闭包注入，如 List）。 */
  @BuilderParam contentBuilder: () => void = this.emptyContent;
  /** 进入刷新状态回调（父执行异步刷新）。 */
  @Event onRefreshing: () => void = () => {
  };

  @Builder
  emptyContent() {
  }

  /** 刷新指示器：AppLoadingProgress 换色转圈 + 可选提示文本。 */
  @Builder
  refreshIndicator() {
    Stack() {
      Row({ space: AppSpacing.SM }) {
        AppLoadingProgress()
          .width(32)
          .height(32)
        if (this.promptText.length > 0) {
          Text(this.promptText)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
        }
      }
      .alignItems(VerticalAlign.Center)
    }
    .align(Alignment.Center)
    .width('100%')
  }

  build() {
    Refresh({ refreshing: $$this.refreshing, builder: this.refreshIndicator() }) {
      this.contentBuilder()
    }
    .onRefreshing((): void => {
      this.onRefreshing();
    })
  }
}
