import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'ScreenManager';

/**
 * 屏幕控制（V2 单例）：常亮与窗口亮度。
 *
 * 说明：@ohos.brightness 仅供系统应用使用（d.ts 标注），
 * 三方应用走窗口级 API（setWindowKeepScreenOn / setWindowBrightness）。
 * 亮度取值 [0.0, 1.0]，-1.0 表示恢复跟随系统；
 * 能力不可用（如部分模拟器 / TV）时降级为 WARN 日志，不抛异常、不阻塞业务。
 * 生命周期：attach 与 detach 成对。
 */
@ObservedV2
export class ScreenManager {
  private static instance: ScreenManager | undefined = undefined;

  /** 常亮开关状态（@Trace，组件直接观测） */
  @Trace keepScreenOn: boolean = false;

  private win: window.Window | undefined = undefined;

  private constructor() {
  }

  static getInstance(): ScreenManager {
    if (ScreenManager.instance === undefined) {
      ScreenManager.instance = new ScreenManager();
    }
    return ScreenManager.instance;
  }

  /**
   * 绑定窗口。
   * 必须在 windowStage.loadContent 回调之后调用。
   */
  attach(win: window.Window): void {
    this.win = win;
    try {
      this.keepScreenOn = win.getWindowProperties().isKeepScreenOn;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `readState failed: ${ErrorMapper.from(err, DOMAIN, 'attach').toLog()}`);
    }
    Logger.info(DOMAIN, TAG, `attached, keepScreenOn=${this.keepScreenOn}`);
  }

  /** 解绑（与 attach 成对）。 */
  detach(): void {
    this.win = undefined;
  }

  /** 设置屏幕常亮（如视频播放、导航场景）。失败仅告警。 */
  setKeepScreenOn(enable: boolean): void {
    const win = this.win;
    if (win === undefined) {
      Logger.warn(DOMAIN, TAG, 'not attached: call attach in loadContent first');
      return;
    }
    win.setWindowKeepScreenOn(enable).then(() => {
      this.keepScreenOn = enable;
      Logger.info(DOMAIN, TAG, `keepScreenOn -> ${enable}`);
    }).catch((err: BusinessError) => {
      Logger.warn(DOMAIN, TAG,
        `setKeepScreenOn failed: ${ErrorMapper.fromBusiness(err, DOMAIN, 'setKeepScreenOn').toLog()}`);
    });
  }

  /** 读取当前窗口亮度（[0.0, 1.0]；-1.0 表示跟随系统；读取失败返回 -1.0 并告警）。 */
  getBrightness(): number {
    const win = this.win;
    if (win === undefined) {
      return -1;
    }
    try {
      return win.getWindowProperties().brightness;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getBrightness failed: ${ErrorMapper.from(err, DOMAIN, 'getBrightness').toLog()}`);
      return -1;
    }
  }

  /** 设置窗口亮度（[0.0, 1.0]；-1.0 恢复跟随系统）。失败仅告警。 */
  setBrightness(value: number): void {
    const win = this.win;
    if (win === undefined) {
      Logger.warn(DOMAIN, TAG, 'not attached: call attach in loadContent first');
      return;
    }
    win.setWindowBrightness(value).then(() => {
      Logger.info(DOMAIN, TAG, `brightness -> ${value}`);
    }).catch((err: BusinessError) => {
      Logger.warn(DOMAIN, TAG, `setBrightness failed: ${ErrorMapper.fromBusiness(err, DOMAIN, 'setBrightness').toLog()}`);
    });
  }
}
