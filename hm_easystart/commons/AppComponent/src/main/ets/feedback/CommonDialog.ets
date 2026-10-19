import { AppFontSize, AppFontWeight, AppRadius, AppSpacing } from '@quizzyjoy/foundation';
import { CommonButton, ButtonVariant } from '@quizzyjoy/vitalui';

/** 对话框按钮描述。 */
export class DialogAction {
  text: ResourceStr = '';
  variant: ButtonVariant = ButtonVariant.TEXT;
  onAction: () => void = () => {
  };

  constructor(text: ResourceStr, variant: ButtonVariant, onAction: () => void) {
    this.text = text;
    this.variant = variant;
    this.onAction = onAction;
  }
}

/**
 * CommonDialog —— 统一对话框（标题 + 正文 + 操作区）。
 *
 * 用法：配合 promptAction.openCustomDialog 使用本结构体作为 builder；
 *      调用方负责 open/close，本组件只负责视觉与交互。
 */
@ComponentV2
export struct CommonDialog {
  @Param title: ResourceStr = '';
  @Param message: ResourceStr = '';
  /** 主操作（可空，仅提示时传空数组）。 */
  @Param actions: DialogAction[] = [];
  /** 是否纵向排列按钮（窄屏/多按钮建议 true）。 */
  @Param vertical: boolean = false;

  build() {
    Column({ space: AppSpacing.LG }) {
      Column({ space: AppSpacing.SM }) {
        Text(this.title)
          .fontSize(AppFontSize.TITLE)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
        Text(this.message)
          .width('100%')
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .textAlign(TextAlign.Start)
          // 长路径 / URL 等无空格串需要强制断行，否则会撑出弹窗右边界被裁切
          .wordBreak(WordBreak.BREAK_ALL)
          // 弹窗容器在 Scroll 紧约束下不传导 Column 的横向内边距，正文需自行留白，
          // 否则首尾字符会贴边被裁（v3.35 真机走查：路径末尾字符缺失）
          .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
      }
      .width('100%')

      Flex({
        direction: this.vertical ? FlexDirection.Column : FlexDirection.Row,
        justifyContent: FlexAlign.Center
      }) {
        ForEach(this.actions, (action: DialogAction) => {
          CommonButton({
            text: action.text,
            variant: action.variant,
            fullWidth: this.vertical,
            onAction: action.onAction
          })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSpacing.XL)
    .backgroundColor($r('app.color.app_bg_card'))
    .borderRadius(AppRadius.XXXL)
  }
}
