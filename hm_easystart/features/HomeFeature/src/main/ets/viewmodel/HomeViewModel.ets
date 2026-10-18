import { AppError, Logger, Result } from '@quizzyjoy/foundation';
import { ViewState } from '@quizzyjoy/vitalui';
import { HomeItem, HomeRepository } from '../data/HomeRepository';

const DOMAIN: string = 'demo';
const TAG: string = 'HomeViewModel';

/**
 * 示例 ViewModel（V2）。
 *
 * 约定：只暴露 @Trace 可观测状态与行为方法；不感知 UI，不抛异常给页面。
 * 失败一律转成 ViewState，由页面用 StateContainer 统一呈现。
 */
@ObservedV2
export class HomeViewModel {
  @Trace items: HomeItem[] = [];
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace selectedId: string = '';

  private repository: HomeRepository = new HomeRepository();

  async load(): Promise<void> {
    this.viewState = ViewState.LOADING;
    const result: Result<HomeItem[]> = await this.repository.fetchItems();
    if (result.success) {
      this.items = result.getOrDefault([]);
      this.viewState = this.items.length === 0 ? ViewState.EMPTY : ViewState.CONTENT;
      return;
    }
    this.items = [];
    this.viewState = ViewState.ERROR;
    result.onFailure((error: AppError) => {
      Logger.error(DOMAIN, TAG, `load failed: ${error.toLog()}`);
    });
  }

  select(id: string): void {
    this.selectedId = id;
    Logger.debug(DOMAIN, TAG, `select id=${id}`);
  }

  /** 断点驱动的列数：紧凑/中等以下单列、中等两列、宽松及以上三列 */
  columns(breakpoint: string): number {
    if (breakpoint === 'md') {
      return 2;
    }
    if (breakpoint === 'lg' || breakpoint === 'xl') {
      return 3;
    }
    return 1;
  }

  breakpointLabel(breakpoint: string): string {
    return breakpoint.toUpperCase();
  }
}