import { FeedbackText, ViewState } from './CommonTypes';
import { SkeletonBlock } from './SkeletonBlock';
import { MotionEffects } from '../motion/MotionEffects';
import { VitalActionButton, VitalActionVariant } from './VitalActionButton';
import { AppFontSize, AppRadius, AppSpacing } from '@quizzyjoy/foundation';

/** 骨架行高（vp）——正文文本行的视觉代理，命名保形。 */
const SKELETON_LINE_HEIGHT: number = 20;

/**
 * 状态容器（StateContainer）。
 *
 * 统一四态：加载 / 空 / 错误 / 内容。业务页面不再各自写 if 分支，
 * 保证全应用的空态与错误态外观、文案结构、重试行为一致。
 *
 * 用法：
 *   StateContainer({ state: this.state }) {
 *     // 内容区
 *   }
 */
@ComponentV2
export struct StateContainer {
  /** 当前状态（四态：LOADING/EMPTY/ERROR/CONTENT）。 */
  @Param state: ViewState = ViewState.CONTENT;
  /** 空态文案（组织级默认，应用档可通过 AppListState 注入本应用文案）。 */
  @Param emptyText: FeedbackText = new FeedbackText('暂无数据', '换个条件试试', '');
  /** 错误态文案（同上）。 */
  @Param errorText: FeedbackText = new FeedbackText('加载失败', '请检查网络后重试', '重试');
  /** 错误态「重试」按钮回调。 */
  @Event onRetry: () => void = () => {
  };
  /** 内容区构建器（尾随闭包，CONTENT 态渲染）。 */
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
  }

  build() {
    Column() {
      if (this.state === ViewState.LOADING) {
        this.loadingView()
      } else if (this.state === ViewState.EMPTY) {
        this.feedbackView(this.emptyText, false)
      } else if (this.state === ViewState.ERROR) {
        this.feedbackView(this.errorText, true)
      } else {
        this.content()
      }
    }
    .width('100%')
  }

  @Builder
  loadingView() {
    Column({ space: AppSpacing.MD }) {
      SkeletonBlock({ heightValue: SKELETON_LINE_HEIGHT, radius: AppRadius.MD })
      SkeletonBlock({ heightValue: SKELETON_LINE_HEIGHT, radius: AppRadius.MD })
      SkeletonBlock({ widthValue: '60%', heightValue: SKELETON_LINE_HEIGHT, radius: AppRadius.MD })
    }
    .width('100%')
    .padding(AppSpacing.LG)
  }

  @Builder
  feedbackView(text: FeedbackText, showAction: boolean) {
    Column({ space: AppSpacing.SM }) {
      Text(text.title)
        .fontSize(AppFontSize.BODY)
        .fontColor($r('app.color.app_text_primary'))
      Text(text.description)
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
      if (showAction && text.actionText.length > 0) {
        VitalActionButton({
          text: text.actionText,
          variant: VitalActionVariant.SECONDARY,
          onAction: () => {
            this.onRetry();
          }
        })
      }
    }
    .width('100%')
    .padding(AppSpacing.XXXL)
    .transition(MotionEffects.pageTransition())
  }
}
