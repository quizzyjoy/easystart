import { window, display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';
import { CapabilityManager } from '../capability/CapabilityManager';

const DOMAIN: string = 'platform';
const TAG: string = 'OrientationManager';

/** 屏幕方向（语义值，读数用：refresh 产出 / isLandscape 判定）。 */
export enum AppOrientation {
  PORTRAIT = 'portrait',
  LANDSCAPE = 'landscape'
}

/**
 * 方向策略（全量镜像 window.Orientation 家族，v2.5 补齐）。
 *
 * 语义分层（借鉴官方 WindowOrientation 三层决策模型：是否支持旋转 → 支持范围 → 首选方向）：
 * - 固定类：PORTRAIT/LANDSCAPE/INVERTED×2（强制指定方向）、LOCKED（锁当前）、UNSPECIFIED（交还系统）
 * - 自旋不受限类：AUTO_ROTATION/_PORTRAIT/_LANDSCAPE——不受控制中心「旋转锁」影响（全屏/游戏刚需）
 * - 自旋受限类：*_RESTRICTED 与 AUTO_ROTATION_UNSPECIFIED——受旋转锁影响
 * - 首选类：USER_ROTATION_*×4——先转到首选方向再放开全向自旋（受旋转锁影响）
 * - FOLLOW_DESKTOP：跟随桌面旋转行为（PC/平板一多推荐）
 */
export enum AppOrientationStrategy {
  UNSPECIFIED = 'unspecified',
  LOCKED = 'locked',
  PORTRAIT = 'portrait',
  LANDSCAPE = 'landscape',
  PORTRAIT_INVERTED = 'portraitInverted',
  LANDSCAPE_INVERTED = 'landscapeInverted',
  AUTO_ROTATION = 'autoRotation',
  AUTO_ROTATION_PORTRAIT = 'autoRotationPortrait',
  AUTO_ROTATION_LANDSCAPE = 'autoRotationLandscape',
  AUTO_ROTATION_RESTRICTED = 'autoRotationRestricted',
  AUTO_ROTATION_PORTRAIT_RESTRICTED = 'autoRotationPortraitRestricted',
  AUTO_ROTATION_LANDSCAPE_RESTRICTED = 'autoRotationLandscapeRestricted',
  AUTO_ROTATION_UNSPECIFIED = 'autoRotationUnspecified',
  USER_ROTATION_PORTRAIT = 'userRotationPortrait',
  USER_ROTATION_LANDSCAPE = 'userRotationLandscape',
  USER_ROTATION_PORTRAIT_INVERTED = 'userRotationPortraitInverted',
  USER_ROTATION_LANDSCAPE_INVERTED = 'userRotationLandscapeInverted',
  FOLLOW_DESKTOP = 'followDesktop'
}

/** 场景栈项：tag 标识压栈方，orientation 为该场景期望的锁定方向。 */
class OrientationStackEntry {
  readonly tag: string;
  readonly orientation: window.Orientation;

  constructor(tag: string, orientation: window.Orientation) {
    this.tag = tag;
    this.orientation = orientation;
  }
}

/**
 * 屏幕方向管理（V2 单例）。
 *
 * 【纪律 F9 · 必读】布局自适应仍然只看断点，禁止用 orientation 做布局分支；
 * orientation 仅用于「产品级锁定场景」（视频全屏锁横屏、游戏等）。
 *
 * 实现：display.rotation 归一（0/180 → portrait，90/270 → landscape）；
 * 锁定走 window.setPreferredOrientation，Promise 异步生效；applyLock 内部
 * lastApplied 去重（未变化跳过系统调用）。
 * 两级 API：lockPortrait/lockLandscape/lockCurrent/unlock 与 pushOrientation/popOrientation
 * 为场景级（栈语义 + 入口快照恢复，借鉴官方 MultiDeviceLibrary OrientationController）；
 * 全量策略面经 pushOrientation(tag, AppOrientationStrategy.*) 下发。
 * 折叠联动（v2.5）：attach 注册 display 'foldStatusChange'，折叠形态变化时重申栈顶策略
 * （reassertTop 强制越过 lastApplied 去重——折叠可能重置窗口方向，需重断言）。
 * 生命周期：attach 与 detach 成对（loadContent 后 attach，onWindowStageDestroy 中 detach）。
 */
@ObservedV2
export class OrientationManager {
  private static instance: OrientationManager | undefined = undefined;

  /** 当前屏幕方向（@Trace，组件直接观测） */
  @Trace orientation: AppOrientation = AppOrientation.PORTRAIT;
  /** 方向栈版本（@Trace，push/pop 自增——UI 可观测栈变更；官方 SceneController 经 AppStorage 版本桥的 V2 原生等价物） */
  @Trace stackVersion: number = 0;
  /** 当前方向栈深度（@Trace） */
  @Trace stackDepth: number = 0;

  private win: window.Window | undefined = undefined;
  private displayListener: ((id: number) => void) | undefined = undefined;
  private foldListener: ((status: display.FoldStatus) => void) | undefined = undefined;
  /** 场景栈（后进先出；栈内为场景级锁定） */
  private stack: OrientationStackEntry[] = [];
  /** 入口方向快照：首个 push 前捕获，栈清空后恢复 */
  private entrySnapshot: window.Orientation | undefined = undefined;
  /** 去重：上次已应用的偏好方向，未变化跳过 */
  private lastApplied: window.Orientation | undefined = undefined;

  private constructor() {
  }

  static getInstance(): OrientationManager {
    if (OrientationManager.instance === undefined) {
      OrientationManager.instance = new OrientationManager();
    }
    return OrientationManager.instance;
  }

  isLandscape(): boolean {
    return this.orientation === AppOrientation.LANDSCAPE;
  }

  /**
   * 绑定窗口并开始监听屏幕旋转。
   * 必须在 windowStage.loadContent 回调之后调用。
   */
  attach(win: window.Window): void {
    this.win = win;
    this.refresh();
    this.displayListener = (id: number) => {
      this.refresh();
    };
    try {
      display.on('change', this.displayListener);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `listenDisplayChange failed: ${ErrorMapper.from(err, DOMAIN, 'attach').toLog()}`);
    }
    this.foldListener = (status: display.FoldStatus) => {
      this.refresh();
      this.reassertTop();
      Logger.info(DOMAIN, TAG, `foldStatusChange -> ${status}, top reasserted`);
    };
    try {
      display.on('foldStatusChange', this.foldListener);
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `listenFoldStatus failed: ${ErrorMapper.from(err, DOMAIN, 'attach').toLog()}`);
    }
    Logger.info(DOMAIN, TAG, `attached, orientation=${this.orientation}`);
  }

  /** 解绑（与 attach 成对）。场景栈与快照一并清空。 */
  detach(): void {
    if (this.displayListener !== undefined) {
      try {
        display.off('change', this.displayListener);
      } catch (err) {
        Logger.warn(DOMAIN, TAG, `unlistenDisplayChange failed: ${ErrorMapper.from(err, DOMAIN, 'detach').toLog()}`);
      }
    }
    this.displayListener = undefined;
    if (this.foldListener !== undefined) {
      try {
        display.off('foldStatusChange', this.foldListener);
      } catch (err) {
        Logger.warn(DOMAIN, TAG, `unlistenFoldStatus failed: ${ErrorMapper.from(err, DOMAIN, 'detach').toLog()}`);
      }
    }
    this.foldListener = undefined;
    this.win = undefined;
    this.stack = [];
    this.entrySnapshot = undefined;
    this.lastApplied = undefined;
    this.bumpStack();
  }

  /**
   * 重置为初始状态（测试隔离 / 复用场景）。
   * 解绑监听并清空全部 @Trace 状态字段；生产生命周期（onWindowStageDestroy）仍走 detach()。
   * 注意：detach() 末尾 bumpStack() 会自增 stackVersion，故这里显式归零。
   */
  reset(): void {
    this.detach();
    this.orientation = AppOrientation.PORTRAIT;
    this.stackVersion = 0;
    this.stackDepth = 0;
  }

  /** 锁定竖屏（产品级场景用，如阅读页）。失败仅告警，不影响业务。 */
  lockPortrait(): void {
    this.applyLock(window.Orientation.PORTRAIT);
  }

  /** 锁定横屏（产品级场景用，如视频全屏）。失败仅告警，不影响业务。 */
  lockLandscape(): void {
    this.applyLock(window.Orientation.LANDSCAPE);
  }

  /** 锁定当前方向（window.Orientation.LOCKED 语义：固定在此刻方向，不受旋转锁影响）。 */
  lockCurrent(): void {
    this.applyLock(window.Orientation.LOCKED);
  }

  /**
   * 解除应用的方向锁定，交还系统自动旋转——跟随系统「自动旋转」设置，
   * 受控制中心「旋转锁」约束（window.Orientation.AUTO_ROTATION_UNSPECIFIED）。
   *
   * 勿用 UNSPECIFIED：其语义是「系统默认方向」（手机上通常固定竖屏），并不会随
   * 系统自动旋转开关 / 重力转动；曾误用 UNSPECIFIED 致设置页「跟随系统」不旋转
   * （v3.16 / 1000007 修复）。需要真正 UNSPECIFIED 时走全量策略面 pushOrientation。
   */
  unlock(): void {
    this.applyLock(window.Orientation.AUTO_ROTATION_UNSPECIFIED);
  }

  /** 策略是否受控制中心「旋转锁」影响（自旋受限类与首选类为 true；文档级语义 isRestricted）。 */
  isRotationLockRestricted(strategy: AppOrientationStrategy): boolean {
    switch (strategy) {
      case AppOrientationStrategy.AUTO_ROTATION_RESTRICTED:
      case AppOrientationStrategy.AUTO_ROTATION_PORTRAIT_RESTRICTED:
      case AppOrientationStrategy.AUTO_ROTATION_LANDSCAPE_RESTRICTED:
      case AppOrientationStrategy.AUTO_ROTATION_UNSPECIFIED:
      case AppOrientationStrategy.USER_ROTATION_PORTRAIT:
      case AppOrientationStrategy.USER_ROTATION_LANDSCAPE:
      case AppOrientationStrategy.USER_ROTATION_PORTRAIT_INVERTED:
      case AppOrientationStrategy.USER_ROTATION_LANDSCAPE_INVERTED:
        return true;
      default:
        return false;
    }
  }

  /**
   * 场景级策略锁定：压栈并应用（v2.5 全量策略面）。
   * 首个 push 前自动捕获入口快照；栈清空后恢复快照——
   * 适用于「进入某场景临时改方向，离开还原」的叠加语义。
   */
  pushOrientation(tag: string, strategy: AppOrientationStrategy): void {
    if (this.entrySnapshot === undefined) {
      this.entrySnapshot = this.readPreferredOrientation();
    }
    const mapped: window.Orientation = OrientationManager.toNativeStrategy(strategy);
    this.stack.push(new OrientationStackEntry(tag, mapped));
    this.applyLock(mapped);
    this.bumpStack();
    Logger.info(DOMAIN, TAG, `pushOrientation tag=${tag}, strategy=${strategy}, stackSize=${this.stack.length}`);
  }

  /** 场景级解锁：按 tag 弹栈；栈空则恢复入口快照（无快照则交还系统）。 */
  popOrientation(tag: string): void {
    for (let i = this.stack.length - 1; i >= 0; i--) {
      if (this.stack[i].tag === tag) {
        this.stack.splice(i, 1);
        break;
      }
    }
    if (this.stack.length > 0) {
      this.applyLock(this.stack[this.stack.length - 1].orientation);
    } else if (this.entrySnapshot !== undefined) {
      this.applyLock(this.entrySnapshot);
      this.entrySnapshot = undefined;
    } else {
      // 无入口快照：交还系统自动旋转（与 unlock 同义，跟随系统旋转设置），而非「系统默认方向」
      this.applyLock(window.Orientation.AUTO_ROTATION_UNSPECIFIED);
    }
    this.bumpStack();
    Logger.info(DOMAIN, TAG, `popOrientation tag=${tag}, stackSize=${this.stack.length}`);
  }

  /** 栈变更通知：版本自增 + 深度同步（@Trace 可观测）。 */
  private bumpStack(): void {
    this.stackVersion++;
    this.stackDepth = this.stack.length;
  }

  /** 折叠形态变化时重申栈顶策略：清 lastApplied 强制越过去重（折叠可能重置窗口方向）。 */
  private reassertTop(): void {
    if (this.stack.length === 0) {
      return;
    }
    this.lastApplied = undefined;
    this.applyLock(this.stack[this.stack.length - 1].orientation);
  }

  /** 策略枚举 → window.Orientation 原生值（编译期封闭 switch，无 as）。 */
  private static toNativeStrategy(strategy: AppOrientationStrategy): window.Orientation {
    switch (strategy) {
      case AppOrientationStrategy.PORTRAIT:
        return window.Orientation.PORTRAIT;
      case AppOrientationStrategy.LANDSCAPE:
        return window.Orientation.LANDSCAPE;
      case AppOrientationStrategy.PORTRAIT_INVERTED:
        return window.Orientation.PORTRAIT_INVERTED;
      case AppOrientationStrategy.LANDSCAPE_INVERTED:
        return window.Orientation.LANDSCAPE_INVERTED;
      case AppOrientationStrategy.LOCKED:
        return window.Orientation.LOCKED;
      case AppOrientationStrategy.AUTO_ROTATION:
        return window.Orientation.AUTO_ROTATION;
      case AppOrientationStrategy.AUTO_ROTATION_PORTRAIT:
        return window.Orientation.AUTO_ROTATION_PORTRAIT;
      case AppOrientationStrategy.AUTO_ROTATION_LANDSCAPE:
        return window.Orientation.AUTO_ROTATION_LANDSCAPE;
      case AppOrientationStrategy.AUTO_ROTATION_RESTRICTED:
        return window.Orientation.AUTO_ROTATION_RESTRICTED;
      case AppOrientationStrategy.AUTO_ROTATION_PORTRAIT_RESTRICTED:
        return window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED;
      case AppOrientationStrategy.AUTO_ROTATION_LANDSCAPE_RESTRICTED:
        return window.Orientation.AUTO_ROTATION_LANDSCAPE_RESTRICTED;
      case AppOrientationStrategy.AUTO_ROTATION_UNSPECIFIED:
        return window.Orientation.AUTO_ROTATION_UNSPECIFIED;
      case AppOrientationStrategy.USER_ROTATION_PORTRAIT:
        return window.Orientation.USER_ROTATION_PORTRAIT;
      case AppOrientationStrategy.USER_ROTATION_LANDSCAPE:
        return window.Orientation.USER_ROTATION_LANDSCAPE;
      case AppOrientationStrategy.USER_ROTATION_PORTRAIT_INVERTED:
        return window.Orientation.USER_ROTATION_PORTRAIT_INVERTED;
      case AppOrientationStrategy.USER_ROTATION_LANDSCAPE_INVERTED:
        return window.Orientation.USER_ROTATION_LANDSCAPE_INVERTED;
      case AppOrientationStrategy.FOLLOW_DESKTOP:
        return window.Orientation.FOLLOW_DESKTOP;
      default:
        return window.Orientation.UNSPECIFIED;
    }
  }

  private readPreferredOrientation(): window.Orientation | undefined {
    const win = this.win;
    if (win === undefined) {
      return undefined;
    }
    try {
      return win.getPreferredOrientation();
    } catch (err) {
      Logger.warn(DOMAIN, TAG,
        `getPreferredOrientation failed: ${ErrorMapper.from(err, DOMAIN, 'readPreferredOrientation').toLog()}`);
      return undefined;
    }
  }

  private applyLock(orientation: window.Orientation): void {
    const win = this.win;
    if (win === undefined) {
      Logger.warn(DOMAIN, TAG, 'not attached: call attach in loadContent first');
      return;
    }
    if (orientation === this.lastApplied) {
      return;
    }
    // 2in1 自由窗口不支持方向锁定（SDK 标注该 API unavailable to 2in1），直接跳过
    if (CapabilityManager.is2in1()) {
      Logger.debug(DOMAIN, TAG, 'skip applyLock on 2in1 (API unavailable)');
      return;
    }
    win.setPreferredOrientation(orientation).then(() => {
      this.lastApplied = orientation;
      Logger.info(DOMAIN, TAG, `preferredOrientation -> ${orientation}`);
    }).catch((err: BusinessError) => {
      Logger.warn(DOMAIN, TAG, `applyLock failed: ${ErrorMapper.fromBusiness(err, DOMAIN, 'applyLock').toLog()}`);
    });
  }

  private refresh(): void {
    try {
      const rotation: number = display.getDefaultDisplaySync().rotation;
      const next: AppOrientation = (rotation === 90 || rotation === 270)
        ? AppOrientation.LANDSCAPE : AppOrientation.PORTRAIT;
      if (next !== this.orientation) {
        this.orientation = next;
        Logger.info(DOMAIN, TAG, `orientation -> ${next} (rotation=${rotation})`);
      }
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `refresh failed: ${ErrorMapper.from(err, DOMAIN, 'refresh').toLog()}`);
    }
  }
}
