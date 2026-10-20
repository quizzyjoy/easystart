import { ButtonVariant } from '../control/CommonButton';
import { CommonDialog, DialogAction } from './CommonDialog';
import { UIContext, ComponentContent } from '@quizzyjoy/platform';

/** 对话语义档：决定主按钮变体与标准文案。 */
export enum DialogSemantic {
  /** 常规确认（品牌主按钮） */
  CONFIRM = 'confirm',
  /** 危险操作（红色主按钮，如删除） */
  DANGER = 'danger'
}

/**
 * 弹窗内容参数（经 ComponentContent 注入全局 @Builder）。
 *
 * 【为什么是类而不是接口】ComponentContent 的 params 需要稳定的实例引用，
 * builder 关闭后按钮回调仍读取该实例；类字段显式初始化满足 ArkTS 严格类型。
 */
class AppDialogContent {
  title: string = '';
  message: string = '';
  actions: DialogAction[] = [];
}

/**
 * 标准确认卡片最大宽度（vp）。规范值豁免登记：ArkUI 弹窗默认宽度上限 400vp
 * （@ohos.promptAction.d.ts CustomDialogOptions.width 文档「Default maximum width:
 * 400 vp」）。ComponentContent 路径的 BaseDialogOptions 无 width 字段，弹窗容器实测
 * 给 builder 根整窗紧约束（v3.11 设备走查：白卡撑满 2224×2496px、Center 对齐失效、
 * 标题压入状态栏），故由逃逸层内定宽容器显式恢复该规范上限。
 */
const DIALOG_MAX_WIDTH_VP = 400;

/**
 * 全局 @Builder：弹窗内容（CommonDialog 结构原语 + 本应用语义注入）。
 *
 * 【为什么必须经 wrapBuilder】静态方法上下文里 struct 直调（CommonDialog({...})）
 * 不参与 ArkUI 编译转换，运行时抛「class constructor cannot called without 'new'」
 * （v3.9 设备走查实测）；而全局 @Builder 直接传 openCustomDialog 的 builder
 * 会闪退（官方 FAQ faqs-arkui-1159）。ComponentContent + wrapBuilder 由
 * BuilderNode 提供组件上下文，是官方推荐的 UI 解耦方式（faqs-arkui-1655）。
 */
@Builder
function appDialogBuilder(content: AppDialogContent) {
  // 逃逸层三明治（v3.11 走查实证修正，形制取自官方 faqs-arkui-961 自定义弹窗动态高度）：
  // - 外层 Stack：显式接受弹窗容器的整窗紧约束（builder 根百分比相对容器），按默认
  //   居中摆放内层；实测 Stack 向子传递的仍是紧约束；
  // - 中层 Scroll（官方钦定的弹窗动态高度容器）：显式 width 400vp——CommonDialog 根的
  //   width('100%') 按祖先约束解析（constraintSize 挂 struct 只 clamp 包装盒、不传导给
  //   struct 根，实测根仍整窗宽），显式定宽原生容器才是 struct 百分比的可靠基准；滚动
  //   容器主轴给子 loose 约束（constraintSize 实测无法松开弹窗容器的紧 min），卡片得以
  //   按内容自适应高度；constraintSize maxHeight '90%' 限高（90% 为规范值豁免登记：
  //   ArkUI 弹窗默认高度上限 0.9×(窗高-安全区)，见 CustomDialogOptions.height 官方
  //   文档），超高内容转滚动；align Center 使短内容在视口内垂直居中；
  // - HitTestMode.None（Stack 与 Scroll 两层）：空区不参与命中测试，点击穿透到遮罩，
  //   autoCancel 关闭路径不受影响（卡片作为子节点照常命中）。
  Stack() {
    Scroll() {
      CommonDialog({
        title: content.title,
        message: content.message,
        vertical: true,
        actions: content.actions
      })
    }
    .width('90%')
    .constraintSize({ maxWidth: DIALOG_MAX_WIDTH_VP, maxHeight: '90%' })
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
 * AppDialog —— 应用级确认对话框（v3.4；v3.9 修复静态上下文无法渲染 struct 的运行时缺陷）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * CommonDialog 是**结构原语**（标题 + 正文 + 操作区布局）；而「确认/取消的标准文案、
 * 危险操作用红色主按钮」是**本应用的交互规范**——换一个 app 这些决策就变 → 应用级
 * AppComponent。本类组合原语 + 注入语义，不复刻布局（判据见指南 §17「换一个 app 还能用吗」）。
 *
 * 【@kit 纪律】ComponentContent/wrapBuilder/DialogAlignment 均为 ArkUI 全局
 * 类型/函数；弹窗经 UIContext.getPromptAction() 打开，零直接 @kit import。
 *
 * 【生命周期】onDidDisappear 统一 dispose 释放 ComponentContent（含点蒙层
 * autoCancel 关闭的路径）；打开失败在 catch 中释放，保证有且仅有一次释放。
 */
export class AppDialog {
  /**
   * 打开标准确认对话框。
   * 语义：CONFIRM = 「确认 / 取消」品牌主按钮；DANGER = 「删除 / 取消」危险主按钮。
   * onConfirm 仅在确认时回调；取消与点外自动关闭均只关窗。
   *
   * @param confirmText 覆盖主按钮文案（v3.39：危险语义不等于「删除」——撤回授权、退出登录、
   *                    重置设置这类不可逆动作用 DANGER 变体 + 自己的动词，避免「删除」误导）
   */
  static open(uiContext: UIContext, semantic: DialogSemantic, title: string, message: string,
    onConfirm: () => void, confirmText?: string): void {
    const defaultText: string = semantic === DialogSemantic.DANGER ? '删除' : '确认';
    const confirmLabel: string = (confirmText !== undefined && confirmText.length > 0) ? confirmText : defaultText;
    const confirmVariant: ButtonVariant = semantic === DialogSemantic.DANGER
      ? ButtonVariant.DANGER : ButtonVariant.PRIMARY;
    const content: AppDialogContent = new AppDialogContent();
    content.title = title;
    content.message = message;
    // contentNode 延迟绑定：actions 必须在 ComponentContent 构造前就绪
    // （构造即触发首次构建，晚赋值会被 ForEach 捕获为空数组——v3.9 设备走查实测）
    let contentNode: ComponentContent<AppDialogContent> | undefined = undefined;
    const close = (): void => {
      if (contentNode !== undefined) {
        uiContext.getPromptAction().closeCustomDialog(contentNode).catch(() => {
          // 已关闭时忽略（重复关闭仅走此静默分支）
        });
      }
    };
    content.actions = [
      new DialogAction(confirmLabel, confirmVariant, () => {
        close();
        onConfirm();
      }),
      new DialogAction('取消', ButtonVariant.TEXT, () => {
        close();
      })
    ];
    contentNode = new ComponentContent(uiContext, wrapBuilder(appDialogBuilder), content);
    uiContext.getPromptAction().openCustomDialog(contentNode, {
      alignment: DialogAlignment.Center,
      autoCancel: true,
      isModal: true,
      onDidDisappear: () => {
        contentNode?.dispose();
      }
    }).catch(() => {
      // 面板服务异常时静默降级（不重复触发 onConfirm），并释放内容节点
      contentNode?.dispose();
    });
  }
}
