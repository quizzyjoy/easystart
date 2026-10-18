/**
 * 组件统一 API 约定。
 *
 * 所有通用组件必须遵循：
 * 1. 外观参数走 @Param，且都带默认值；
 * 2. 交互回调走 @Event，命名 onXxx；
 * 3. 组件内部不持有全局单例，依赖由外部注入；
 * 4. 必填语义参数（如 title）显式声明，不做隐式缺省。
 */

/** 通用尺寸档位，替代裸 number，保证跨端一致 */
export enum SizeLevel {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large'
}

/** 通用状态语义，组件外观据此切换 */
export enum ViewState {
  IDLE = 'idle',
  LOADING = 'loading',
  EMPTY = 'empty',
  ERROR = 'error',
  CONTENT = 'content'
}

/** 统一的空态 / 错误态文案模型 */
export class FeedbackText {
  title: string = '';
  description: string = '';
  actionText: string = '';

  constructor(title: string, description: string, actionText: string) {
    this.title = title;
    this.description = description;
    this.actionText = actionText;
  }
}
