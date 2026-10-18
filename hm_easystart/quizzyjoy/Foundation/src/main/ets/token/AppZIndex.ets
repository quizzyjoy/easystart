/**
 * 层级序（自绘浮层冲突裁定）。
 *
 * v3.0 新增。ArkUI 的 bindSheet / autoDialog 由组件栈自管层级，
 * 本表用于自绘浮层（自定义 toast、悬浮预览、引导遮罩）之间的排序与
 * 与系统浮层并置时的参考。
 */
export class AppZIndex {
  static readonly CONTENT: number = 0;
  /** 吸顶元素（表头、悬浮操作条）。 */
  static readonly STICKY: number = 10;
  /** 半模态 / 底部面板。 */
  static readonly SHEET: number = 100;
  /** 对话框。 */
  static readonly DIALOG: number = 200;
  /** 轻提示（最高层）。 */
  static readonly TOAST: number = 300;
}
