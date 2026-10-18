import display from '@ohos.display';

/**
 * 手表屏幕适配工具（v3.27，落在**入口层** utils/）。
 *
 * 【例外登记（指南 §5.3 登记制）】本文件直连 `@ohos.display`
 * （`getDefaultDisplaySync()` 的 `screenShape` 与宽高）——属**形态专属屏幕适配**：
 * 按 F14「形态专属装配落入口模块」口径收口在本入口 utils/，不散落到页面；
 * 若将来出现多 app 复用需求，再提上游轮次进 `quizzyjoy/Platform`。
 *
 * 两层判定驱动手表布局：
 * 1. **圆/方屏**：圆形屏需更大安全边距、更窄内容区（内接正方形），并可走弧屏容器；
 * 2. **尺寸分级** small(<340vp) / standard(340~460vp) / large(>460vp)：Token 随之取档。
 *
 * 参考实证：EasyRandom 手表入口（圆屏 ArcSwiper + 圆形裁切、466vp 基准缩放）——
 * 本工具是其 `WearScreenUtil` 的模板化收敛（静态方法、异常一律降级）。
 */
export class WearScreenUtil {
  private static widthVp: number = 0;
  private static heightVp: number = 0;
  private static round: boolean = false;
  private static detected: boolean = false;

  /** 466vp 基准：Watch GT 4 一类圆形 standard 屏。 */
  private static readonly BASE_WIDTH_VP: number = 466;
  /** 兜底尺寸（探测失败时使用）。 */
  private static readonly FALLBACK_VP: number = 466;

  private static detect(): void {
    if (WearScreenUtil.detected) {
      return;
    }
    WearScreenUtil.detected = true;
    try {
      const info = display.getDefaultDisplaySync();
      // ScreenShape.ROUND = 1 / RECTANGLE = 0
      WearScreenUtil.round = info.screenShape === 1;
      WearScreenUtil.widthVp = px2vp(info.width);
      WearScreenUtil.heightVp = px2vp(info.height);
    } catch (err) {
      WearScreenUtil.round = false;
      WearScreenUtil.widthVp = WearScreenUtil.FALLBACK_VP;
      WearScreenUtil.heightVp = WearScreenUtil.FALLBACK_VP;
    }
    if (!(WearScreenUtil.widthVp > 0)) {
      WearScreenUtil.widthVp = WearScreenUtil.FALLBACK_VP;
    }
    if (!(WearScreenUtil.heightVp > 0)) {
      WearScreenUtil.heightVp = WearScreenUtil.FALLBACK_VP;
    }
  }

  /** 是否圆形屏（探测失败按方屏降级）。 */
  static isRound(): boolean {
    WearScreenUtil.detect();
    return WearScreenUtil.round;
  }

  static screenWidthVp(): number {
    WearScreenUtil.detect();
    return WearScreenUtil.widthVp;
  }

  static screenHeightVp(): number {
    WearScreenUtil.detect();
    return WearScreenUtil.heightVp;
  }

  /** 尺寸分级：small / standard / large。 */
  static sizeBucket(): string {
    WearScreenUtil.detect();
    if (WearScreenUtil.widthVp < 340) {
      return 'small';
    }
    if (WearScreenUtil.widthVp > 460) {
      return 'large';
    }
    return 'standard';
  }

  /** 安全边距（vp）：圆形屏需避开弧形裁切区，故更大。 */
  static safePadding(): number {
    const bucket: string = WearScreenUtil.sizeBucket();
    if (WearScreenUtil.isRound()) {
      if (bucket === 'small') {
        return 18;
      }
      if (bucket === 'large') {
        return 28;
      }
      return 24;
    }
    if (bucket === 'small') {
      return 8;
    }
    if (bucket === 'large') {
      return 16;
    }
    return 12;
  }

  /** 内容区宽度占比：圆形屏取内接正方形思路，更窄。 */
  static contentWidthRatio(): string {
    const bucket: string = WearScreenUtil.sizeBucket();
    if (WearScreenUtil.isRound()) {
      if (bucket === 'small') {
        return '65%';
      }
      if (bucket === 'large') {
        return '75%';
      }
      return '70%';
    }
    if (bucket === 'small') {
      return '88%';
    }
    if (bucket === 'large') {
      return '92%';
    }
    return '90%';
  }

  /** 主结果字号（fp）。 */
  static resultFontSize(): number {
    const bucket: string = WearScreenUtil.sizeBucket();
    if (bucket === 'small') {
      return 40;
    }
    if (bucket === 'large') {
      return 56;
    }
    return 48;
  }

  /** 辅助字号（fp）。 */
  static subFontSize(): number {
    const bucket: string = WearScreenUtil.sizeBucket();
    if (bucket === 'small') {
      return 12;
    }
    if (bucket === 'large') {
      return 16;
    }
    return 14;
  }

  /** 列表项间距（vp）。 */
  static listItemSpace(): number {
    const bucket: string = WearScreenUtil.sizeBucket();
    if (WearScreenUtil.isRound()) {
      if (bucket === 'small') {
        return 12;
      }
      if (bucket === 'large') {
        return 20;
      }
      return 16;
    }
    if (bucket === 'small') {
      return 8;
    }
    if (bucket === 'large') {
      return 14;
    }
    return 12;
  }

  /** 最小触摸目标（vp）：手表平台统一 48，不随屏分档。 */
  static minTouchSize(): number {
    return 48;
  }

  /**
   * 以 466vp 为基准的等比缩放（下限 70%）——仅用于 Canvas 等需要精确 vp 的场景；
   * 常规布局优先使用百分比 Token（contentWidthRatio 等），不依赖本函数。
   */
  static scaledSize(standardValue: number): number {
    WearScreenUtil.detect();
    const scale: number = WearScreenUtil.widthVp / WearScreenUtil.BASE_WIDTH_VP;
    return Math.max(standardValue * scale, standardValue * 0.7);
  }
}
