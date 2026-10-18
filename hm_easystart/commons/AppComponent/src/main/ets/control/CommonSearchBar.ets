import { AppFontSize, AppFontWeight, AppRadius, AppSpacing, AppSize } from '@quizzyjoy/foundation';

/** 输入防抖时长（ms）——搜索类交互的应用级规范值。 */
const DEBOUNCE_MS: number = 300;

/**
 * CommonSearchBar —— 统一搜索框。
 * 状态管理 V2：@Param 传入值，@Event 抛出变更（已做 300ms 防抖）。
 * 健壮性：组件销毁时清理防抖定时器，避免对已销毁实例回调。
 */
@ComponentV2
export struct CommonSearchBar {
  /** 占位提示文案。 */
  @Param placeholder: ResourceStr = '搜索';
  /** 受控值（单向输入）。 */
  @Param value: string = '';
  /** 输入变化（已防抖 DEBOUNCE_MS）。 */
  @Event onSearch: (keyword: string) => void = () => {
  };
  /** 是否显示右侧「取消」按钮（聚焦态由调用方管理）。 */
  @Param showCancel: boolean = false;
  /** 取消回调。 */
  @Event onCancel: () => void = () => {
  };

  private debounceTimer: number = -1;

  aboutToDisappear(): void {
    this.clearTimer();
  }

  private clearTimer(): void {
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = -1;
    }
  }

  private emitSearch(keyword: string): void {
    this.clearTimer();
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = -1;
      this.onSearch(keyword);
    }, DEBOUNCE_MS);
  }

  build() {
    Row({ space: AppSpacing.SM }) {
      Row({ space: AppSpacing.SM }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(AppFontSize.BODY)
          .fontColor([$r('app.color.app_text_tertiary')])
        TextInput({ text: this.value, placeholder: this.placeholder })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .placeholderColor($r('app.color.app_text_tertiary'))
          .padding(0)
          .onChange((val: string) => {
            this.emitSearch(val);
          })
        if (this.value.length > 0) {
          SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
            .fontSize(AppFontSize.BODY)
            .fontColor([$r('app.color.app_text_tertiary')])
            .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.MD })
            .onClick(() => {
              this.onSearch('');
            })
        }
      }
      .layoutWeight(1)
      .height(AppSize.TOUCH_MIN)
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
      .backgroundColor($r('app.color.app_fill_subtle'))
      .borderRadius(AppRadius.XXL)
      if (this.showCancel) {
        Text('取消')
          .fontSize(AppFontSize.BODY_SM)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.qj_brand'))
          .height(AppSize.TOUCH_MIN)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .onClick(() => {
            this.onCancel();
          })
      }
    }
    .width('100%')
  }
}
