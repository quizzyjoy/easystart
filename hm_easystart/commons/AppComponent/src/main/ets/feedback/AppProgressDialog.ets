import { AppFontSize, AppFontWeight, AppRadius, AppSpacing } from '@quizzyjoy/foundation';
import { UIContext, ComponentContent } from '@quizzyjoy/platform';
import { AppProgress } from '../control/AppProgress';

/**
 * 进度弹窗内容参数（经 ComponentContent 注入全局 @Builder）。
 *
 * 【为什么是类而不是接口】同 AppDialogContent——ComponentContent 的 params 需要
 * 稳定实例引用，update() 时按实例重新构建；类字段显式初始化满足 ArkTS 严格类型。
 */
class AppProgressContent {
  title: string = '';
  progress: number = 0;
}

/** 进度弹窗卡片宽度（vp）——窄于确认弹窗的 400vp，进度条场景无需整宽。 */
const PROGRESS_DIALOG_WIDTH_VP = 280;

/**
 * 全局 @Builder：进度弹窗内容（标题 + 主题化进度条 + 进度值）。
 * 逃逸层三明治形制同 AppDialog（Stack + Scroll 定宽动态高度 + HitTestMode.None 点击穿透）。
 */
@Builder
function appProgressBuilder(content: AppProgressContent) {
  Stack() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text(content.title)
          .fontSize(AppFontSize.TITLE)
          .fontWeight(AppFontWeight.BOLD)
          .fontColor($r('app.color.app_text_primary'))
          .textAlign(TextAlign.Center)
        AppProgress({ value: content.progress, total: 100 })
          .width('100%')
        Text(`${content.progress}%`)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(AppSpacing.XL)
      .backgroundColor($r('app.color.app_bg_card'))
      .borderRadius(AppRadius.XXXL)
    }
    .width(PROGRESS_DIALOG_WIDTH_VP)
    .constraintSize({ maxHeight: '90%' })
    .align(Alignment.Center)
    .edgeEffect(EdgeEffect.None)
    .scrollBar(BarState.Off)
    .hitTestBehavior(HitTestMode.None)
  }
  .width('100%')
  .height('100%')
  .hitTestBehavior(HitTestMode.None)
}

/**
 * AppProgressDialog —— 应用级进度弹窗（openCustomDialog + ComponentContent.update 数据交互）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「标题 + 主题化进度条 + 进度值」的进度反馈规范、update() 数据交互方式、点外不关闭
 * （autoCancel 保任务持续）是应用规范——换一个 app 进度弹窗样式与交互就变 → 应用级。
 * 组合 AppProgress（换肤进度条）+ ComponentContent 解耦（官方「进度展示弹窗」方案）。
 *
 * 【用法】AppProgressDialog.open(this.getUIContext(), '上传中…', 0);
 *         循环中 AppProgressDialog.update(p)；完成后 AppProgressDialog.close(ctx)。
 *
 * 【@kit 纪律】ComponentContent/wrapBuilder/DialogAlignment 为全局类型；零直接 @kit。
 *
 * 【生命周期】onDidDisappear 统一 dispose 释放 ComponentContent；打开失败在 catch 释放。
 */
export class AppProgressDialog {
  private static contentNode: ComponentContent<AppProgressContent> | undefined = undefined;
  private static content: AppProgressContent | undefined = undefined;

  /** 打开进度弹窗（cancelable=false 时点外不关闭，保任务持续）。 */
  static open(uiContext: UIContext, title: string, progress: number = 0, cancelable: boolean = true): void {
    const content: AppProgressContent = new AppProgressContent();
    content.title = title;
    content.progress = progress;
    AppProgressDialog.content = content;
    AppProgressDialog.contentNode = new ComponentContent(uiContext, wrapBuilder(appProgressBuilder), content);
    uiContext.getPromptAction().openCustomDialog(AppProgressDialog.contentNode, {
      alignment: DialogAlignment.Center,
      autoCancel: cancelable,
      isModal: true,
      onDidDisappear: (): void => {
        AppProgressDialog.contentNode?.dispose();
        AppProgressDialog.contentNode = undefined;
        AppProgressDialog.content = undefined;
      }
    }).catch(() => {
      // 面板服务异常时静默释放内容节点
      AppProgressDialog.contentNode?.dispose();
      AppProgressDialog.contentNode = undefined;
      AppProgressDialog.content = undefined;
    });
  }

  /** 更新进度（0-100，ComponentContent.update 重新构建内容）。 */
  static update(progress: number): void {
    if (AppProgressDialog.content !== undefined && AppProgressDialog.contentNode !== undefined) {
      AppProgressDialog.content.progress = progress;
      AppProgressDialog.contentNode.update(AppProgressDialog.content);
    }
  }

  /** 关闭进度弹窗。 */
  static close(uiContext: UIContext): void {
    if (AppProgressDialog.contentNode !== undefined) {
      uiContext.getPromptAction().closeCustomDialog(AppProgressDialog.contentNode).catch(() => {
        // 已关闭时忽略（重复关闭仅走此静默分支）
      });
    }
  }
}
