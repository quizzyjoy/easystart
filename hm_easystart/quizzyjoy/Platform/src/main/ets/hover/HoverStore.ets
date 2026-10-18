import { display } from '@kit.ArkUI';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'HoverStore';

/** 折叠形态（含三折叠双展开/双折叠态；无法识别归 UNKNOWN）。 */
export enum AppFoldStatus {
  UNKNOWN = 'unknown',
  EXPANDED = 'expanded',
  FOLDED = 'folded',
  HALF_FOLDED = 'halfFolded',
  EXPANDED_WITH_SECOND_EXPANDED = 'expandedWithSecondExpanded',
  FOLDED_WITH_SECOND_EXPANDED = 'foldedWithSecondExpanded'
}

/** 悬停/折痕数据载荷（字段集对齐官方 MultiDeviceLibrary HoverDataStore）。 */
export class HoverData {
  isHover: boolean = false;
  /** 折叠屏折痕上沿（vp，未折叠/非折叠屏为 0） */
  creaseTopVp: number = 0;
  /** 折叠屏折痕高度（vp） */
  creaseHeightVp: number = 0;
}

/** 订阅回调签名。 */
export type HoverListener = (data: HoverData) => void;

/**
 * 悬停 / 折叠屏数据源（v2.5 实采，借鉴官方 WindowOrientation 示例）。
 *
 * 折痕数据源：display.getCurrentFoldCreaseRegion（px→vp 经 densityPixels）；
 * 折叠形态：display.getFoldStatus + 'foldStatusChange' 监听（变化时同步刷新折痕）。
 * 全部折叠 API 经 canIUse('SystemCapability.Window.SessionManager') 守卫，
 * 非折叠设备 / 低能力设备 isFoldable=false，其余字段恒 0（降级安全）。
 * isHover 仍为组件驱动（onHover 事件回写），系统无全局 hover 源。
 * 【与官方差异】display.off 精确解绑本 store 回调（官方无参 off 会清除该事件全部监听，不采纳）。
 * 生命周期：attach 与 detach 成对（幂等，重复 attach 只注册一次）。
 */
@ObservedV2
export class HoverStore {
  private static instance: HoverStore | undefined = undefined;

  /** 当前悬停态（@Trace，组件直接观测；组件 onHover 回写） */
  @Trace isHover: boolean = false;
  /** 设备是否可折叠（@Trace，能力降级开关） */
  @Trace isFoldable: boolean = false;
  /** 折叠形态（@Trace） */
  @Trace foldStatus: AppFoldStatus = AppFoldStatus.UNKNOWN;
  /** 折痕上沿（vp，非折叠屏为 0） */
  @Trace creaseTopVp: number = 0;
  /** 折痕高度（vp，非折叠屏为 0） */
  @Trace creaseHeightVp: number = 0;

  private listeners: HoverListener[] = [];
  private attached: boolean = false;
  private foldListener: ((status: display.FoldStatus) => void) | undefined = undefined;

  private constructor() {
  }

  static getInstance(): HoverStore {
    if (HoverStore.instance === undefined) {
      HoverStore.instance = new HoverStore();
    }
    return HoverStore.instance;
  }

  /** 开始采集（幂等）。非折叠屏 / 无 SessionManager 能力时安全降级为 isFoldable=false。 */
  attach(): void {
    if (this.attached) {
      return;
    }
    this.attached = true;
    if (!canIUse('SystemCapability.Window.SessionManager')) {
      Logger.info(DOMAIN, TAG, 'attach: SessionManager unsupported, degraded');
      return;
    }
    try {
      this.isFoldable = display.isFoldable();
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `isFoldable failed: ${ErrorMapper.from(err, DOMAIN, 'attach').toLog()}`);
    }
    if (!this.isFoldable) {
      Logger.info(DOMAIN, TAG, 'attach: not foldable, degraded');
      return;
    }
    this.refreshFold();
    this.foldListener = (status: display.FoldStatus) => {
      this.refreshFold();
      Logger.info(DOMAIN, TAG, `foldStatusChange -> ${status}`);
    };
    try {
      display.on('foldStatusChange', this.foldListener);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `listenFoldStatus failed: ${ErrorMapper.from(err, DOMAIN, 'attach').toLog()}`);
    }
    Logger.info(DOMAIN, TAG, 'attached');
  }

  /** 停止采集（与 attach 成对；精确解绑，不影响其他 display 监听者）。 */
  detach(): void {
    if (this.foldListener !== undefined) {
      try {
        display.off('foldStatusChange', this.foldListener);
      } catch (err) {
        Logger.warn(DOMAIN, TAG, `unlistenFoldStatus failed: ${ErrorMapper.from(err, DOMAIN, 'detach').toLog()}`);
      }
    }
    this.foldListener = undefined;
    this.attached = false;
    this.isFoldable = false;
    this.foldStatus = AppFoldStatus.UNKNOWN;
    this.creaseTopVp = 0;
    this.creaseHeightVp = 0;
    Logger.info(DOMAIN, TAG, 'detached');
  }

  /** 订阅数据变化（配合 @Trace 之外的命令式消费）。 */
  subscribe(listener: HoverListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
    Logger.info(DOMAIN, TAG, `subscribed, listeners=${this.listeners.length}`);
  }

  /** 注销监听（与 subscribe 成对）。 */
  unsubscribe(listener: HoverListener): void {
    const idx: number = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  /** 清空全部监听（onWindowStageDestroy 中调用；与订阅生命周期成对）。 */
  destroy(): void {
    this.listeners = [];
    Logger.info(DOMAIN, TAG, 'destroyed');
  }

  /** 组件回写悬停态（onHover 事件入口）。 */
  reportHover(isHover: boolean): void {
    this.isHover = isHover;
    const data: HoverData = new HoverData();
    data.isHover = isHover;
    data.creaseTopVp = this.creaseTopVp;
    data.creaseHeightVp = this.creaseHeightVp;
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i](data);
    }
  }

  private refreshFold(): void {
    try {
      this.foldStatus = HoverStore.mapFoldStatus(display.getFoldStatus());
      this.readCrease();
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `refreshFold failed: ${ErrorMapper.from(err, DOMAIN, 'refreshFold').toLog()}`);
    }
  }

  private readCrease(): void {
    try {
      const region: display.FoldCreaseRegion = display.getCurrentFoldCreaseRegion();
      const rects: display.Rect[] = region.creaseRects;
      if (rects.length === 0) {
        this.creaseTopVp = 0;
        this.creaseHeightVp = 0;
        return;
      }
      const density: number = display.getDefaultDisplaySync().densityPixels;
      const rect: display.Rect = rects[0];
      this.creaseTopVp = density > 0 ? Math.round(rect.top / density) : 0;
      this.creaseHeightVp = density > 0 ? Math.round(rect.height / density) : 0;
    } catch (err) {
      // 非折叠设备 / 折痕区读取失败时归零（refreshFold 上层已有日志）
      this.creaseTopVp = 0;
      this.creaseHeightVp = 0;
    }
  }

  private static mapFoldStatus(status: display.FoldStatus): AppFoldStatus {
    switch (status) {
      case display.FoldStatus.FOLD_STATUS_EXPANDED:
        return AppFoldStatus.EXPANDED;
      case display.FoldStatus.FOLD_STATUS_FOLDED:
        return AppFoldStatus.FOLDED;
      case display.FoldStatus.FOLD_STATUS_HALF_FOLDED:
        return AppFoldStatus.HALF_FOLDED;
      case display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_EXPANDED:
        return AppFoldStatus.EXPANDED_WITH_SECOND_EXPANDED;
      case display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_EXPANDED:
        return AppFoldStatus.FOLDED_WITH_SECOND_EXPANDED;
      default:
        return AppFoldStatus.UNKNOWN;
    }
  }
}
