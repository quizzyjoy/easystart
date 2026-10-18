import { UIContext, window } from '@kit.ArkUI';
import { Logger } from '@quizzyjoy/foundation';
import { BreakpointConstants, BreakpointType } from './BreakpointConstants';

const DOMAIN: string = 'platform';
const TAG: string = 'BreakpointManager';

/**
 * 断点管理器（全局单例）。
 *
 * 两条硬纪律：
 * 1. 断点值一律取自 UIContext.getWindowWidthBreakpoint() / getWindowHeightBreakpoint()，
 *    禁止自行硬编码阈值（个别设备已通过产品化配置调整阈值）。
 * 2. 监听源是窗口（windowSizeChange），不是屏幕尺寸，因此分屏 / 折叠 / 自由窗口都正确。
 *
 * 订阅方式：@ObservedV2 + @Trace，组件侧用 @Local 持有实例即可自动刷新。
 */
@ObservedV2
export class BreakpointManager {
  private static instance: BreakpointManager | undefined = undefined;

  /** 当前横向断点语义名（平台枚举归一化后的结果） */
  @Trace breakpoint: BreakpointType = BreakpointType.SM;
  /** 当前纵向断点（按窗口高宽比），用于差异化设计 */
  @Trace heightBreakpoint: string = '';
  /** 当前窗口宽度（vp） */
  @Trace windowWidthVp: number = 0;
  /** 当前窗口高度（vp） */
  @Trace windowHeightVp: number = 0;

  private uiContext: UIContext | undefined = undefined;
  private mainWindow: window.Window | undefined = undefined;
  private sizeListener: ((size: window.Size) => void) | undefined = undefined;

  private constructor() {
  }

  static getInstance(): BreakpointManager {
    if (BreakpointManager.instance === undefined) {
      BreakpointManager.instance = new BreakpointManager();
    }
    return BreakpointManager.instance;
  }

  /**
   * 绑定窗口并开始监听。
   * 必须在 windowStage.loadContent 的回调中调用（loadContent 完成后断点查询才有效）。
   */
  attach(uiContext: UIContext, mainWindow: window.Window): void {
    this.uiContext = uiContext;
    this.mainWindow = mainWindow;
    try {
      const rect: window.Rect = mainWindow.getWindowProperties().windowRect;
      this.applySize(rect.width, rect.height);
    } catch (err) {
      // 窗口属性读取失败时仍解析断点（后续 windowSizeChange 会补齐尺寸）
      Logger.warn(DOMAIN, TAG, `readWindowRect failed: ${err}`);
      this.breakpoint = BreakpointConstants.resolve(uiContext.getWindowWidthBreakpoint());
    }
    this.sizeListener = (size: window.Size) => {
      this.applySize(size.width, size.height);
    };
    mainWindow.on('windowSizeChange', this.sizeListener);
    Logger.info(DOMAIN, TAG, `attached, breakpoint=${this.breakpoint}, widthVp=${this.windowWidthVp}`);
  }

  /** 解绑，应在 onWindowStageDestroy / onDestroy 中调用 */
  detach(): void {
    if (this.mainWindow !== undefined && this.sizeListener !== undefined) {
      this.mainWindow.off('windowSizeChange', this.sizeListener);
    }
    this.mainWindow = undefined;
    this.sizeListener = undefined;
    this.uiContext = undefined;
  }

  /**
   * 重置为初始状态（测试隔离 / 复用场景）。
   * 解绑监听并清空全部 @Trace 状态字段；生产生命周期（onWindowStageDestroy）仍走 detach()。
   */
  reset(): void {
    this.detach();
    this.breakpoint = BreakpointType.SM;
    this.heightBreakpoint = '';
    this.windowWidthVp = 0;
    this.windowHeightVp = 0;
  }

  /** 当前是否宽屏断点（lg / xl），用于决定单栏还是分栏 */
  isWide(): boolean {
    return BreakpointConstants.isWide(this.breakpoint);
  }

  /** 栅格总列数 */
  gridColumns(): number {
    return BreakpointConstants.gridColumns(this.breakpoint);
  }

  /**
   * 数据源快照（v2.4）：供 Foundation 响应式 DSL（ResponsiveValueResolver）求值。
   * field 契约：breakpoint / heightBreakpoint / widthVp / heightVp / isWide / gridColumns。
   */
  snapshot(): Record<string, string | number | boolean> {
    const snap: Record<string, string | number | boolean> = {
      'breakpoint': `${this.breakpoint}`,
      'heightBreakpoint': this.heightBreakpoint,
      'widthVp': this.windowWidthVp,
      'heightVp': this.windowHeightVp,
      'isWide': this.isWide(),
      'gridColumns': this.gridColumns()
    };
    return snap;
  }

  private applySize(widthPx: number, heightPx: number): void {
    const ui = this.uiContext;
    if (ui === undefined) {
      this.breakpoint = BreakpointConstants.resolve(WidthBreakpoint.WIDTH_SM);
      return;
    }
    // 全局 px2vp 自 API 18 弃用，官方替代为 UIContext.px2vp（SDK @useinstead）
    this.windowWidthVp = ui.px2vp(widthPx);
    this.windowHeightVp = ui.px2vp(heightPx);
    this.breakpoint = BreakpointConstants.resolve(ui.getWindowWidthBreakpoint());
    this.heightBreakpoint = `${ui.getWindowHeightBreakpoint()}`;
  }
}