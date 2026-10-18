import { window, display } from '@kit.ArkUI';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';
import { CapabilityManager } from '../capability/CapabilityManager';

const DOMAIN: string = 'platform';
const TAG: string = 'WindowAdapter';

/**
 * 窗口适配：安全区、沉浸式（V2 单例）。
 *
 * 与 Runtime/BreakpointManager 的分工：
 * - BreakpointManager 负责「窗口宽度 → 断点」；
 * - WindowAdapter 负责「安全区 → 可观测的避让尺寸」。
 * 组件侧用 @Local 持有本单例即可自动刷新，不经过 AppStorage（V1 机制）。
 */
@ObservedV2
export class WindowAdapter {
  private static instance: WindowAdapter | undefined = undefined;

  /** 状态栏高度（vp） */
  @Trace statusBarHeightVp: number = 0;
  /** 手势条高度（vp） */
  @Trace navIndicatorHeightVp: number = 0;
  /** 顶部避让（vp，含挖孔屏 cutout） */
  @Trace topAvoidVp: number = 0;
  /** 底部避让（vp，含挖孔屏 cutout） */
  @Trace bottomAvoidVp: number = 0;
  /** 沉浸式全屏是否开启（@Trace；v2.6 默认经 AppBootstrap 开启） */
  @Trace isImmersive: boolean = false;

  private density: number = 2;
  private lastKnownDark: boolean = false;
  private win: window.Window | undefined = undefined;
  private avoidListener: ((data: window.AvoidAreaOptions) => void) | undefined = undefined;

  private constructor() {
  }

  static getInstance(): WindowAdapter {
    if (WindowAdapter.instance === undefined) {
      WindowAdapter.instance = new WindowAdapter();
    }
    return WindowAdapter.instance;
  }

  /**
   * 绑定窗口并开始监听安全区变化。
   * 必须在 windowStage.loadContent 回调之后调用。
   */
  attach(win: window.Window): void {
    this.win = win;
    try {
      this.density = display.getDefaultDisplaySync().densityPixels;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `bindDisplay failed: ${ErrorMapper.from(err, DOMAIN, 'attach').toLog()}`);
      this.density = 2;
    }
    this.applyAvoidArea();
    this.avoidListener = (data: window.AvoidAreaOptions) => {
      this.applyAvoidArea();
    };
    win.on('avoidAreaChange', this.avoidListener);
    Logger.info(DOMAIN, TAG,
      `attached, statusBar=${this.statusBarHeightVp}vp, navIndicator=${this.navIndicatorHeightVp}vp`);
  }

  /** 解绑（与 attach 成对，onWindowStageDestroy 中调用）。 */
  detach(): void {
    if (this.win !== undefined && this.avoidListener !== undefined) {
      this.win.off('avoidAreaChange', this.avoidListener);
    }
    this.win = undefined;
    this.avoidListener = undefined;
  }

  /**
   * 重置为初始状态（测试隔离 / 复用场景）。
   * 解绑监听并清空全部 @Trace 状态字段；生产生命周期（onWindowStageDestroy）仍走 detach()。
   */
  reset(): void {
    this.detach();
    this.statusBarHeightVp = 0;
    this.navIndicatorHeightVp = 0;
    this.topAvoidVp = 0;
    this.bottomAvoidVp = 0;
    this.isImmersive = false;
  }

  /**
   * 设置沉浸式全屏（v2.6 起 AppBootstrap 默认开启）。
   * 开启后内容延伸至系统栏下，页面用 topAvoidVp/bottomAvoidVp padding 避让；
   * 不支持的形态（TV/手表等）内部 try-catch 降级为 no-op。
   */
  setImmersive(immersive: boolean): void {
    const win = this.win;
    if (win === undefined) {
      return;
    }
    // 2in1 自由窗口形态无全屏布局语义（SDK 标注该 API unavailable to 2in1），直接跳过
    if (CapabilityManager.is2in1()) {
      Logger.debug(DOMAIN, TAG, 'skip setImmersive on 2in1 (API unavailable)');
      return;
    }
    try {
      win.setWindowLayoutFullScreen(immersive);
      this.isImmersive = immersive;
      this.applySystemBarAppearance(this.lastKnownDark);
      Logger.info(DOMAIN, TAG, `immersive -> ${immersive}`);
    } catch (err) {
      Logger.warn(DOMAIN, TAG,
        `setImmersive failed (degraded to non-immersive): ${ErrorMapper.from(err, DOMAIN, 'setImmersive').toLog()}`);
    }
  }

  /**
   * 系统栏内容色随深浅色联动（沉浸式配套：避免深底黑字）。
   * 由 ColorModeManager 在模式初始化与每次变更时推送；win 未绑定或未沉浸时安全跳过。
   */
  applySystemBarAppearance(isDark: boolean): void {
    const win = this.win;
    this.lastKnownDark = isDark;
    if (win === undefined || !this.isImmersive) {
      return;
    }
    const contentColor: string = isDark ? '#FFFFFFFF' : '#FF000000';
    try {
      win.setWindowSystemBarProperties({
        statusBarContentColor: contentColor,
        navigationBarContentColor: contentColor
      });
    } catch (err) {
      Logger.warn(DOMAIN, TAG,
        `applySystemBarAppearance failed: ${ErrorMapper.from(err, DOMAIN, 'applySystemBarAppearance').toLog()}`);
    }
  }

  private applyAvoidArea(): void {
    const win = this.win;
    if (win === undefined) {
      return;
    }
    try {
      const status = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const nav = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const cutout = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      this.statusBarHeightVp = status.topRect.height / this.density;
      this.navIndicatorHeightVp = nav.bottomRect.height / this.density;
      this.topAvoidVp = Math.max(status.topRect.height, cutout.topRect.height) / this.density;
      this.bottomAvoidVp = Math.max(nav.bottomRect.height, cutout.bottomRect.height) / this.density;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `applyAvoidArea failed: ${ErrorMapper.from(err, DOMAIN, 'applyAvoidArea').toLog()}`);
    }
  }
}
