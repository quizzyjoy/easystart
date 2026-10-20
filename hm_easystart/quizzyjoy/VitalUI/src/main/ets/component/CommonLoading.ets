import { UiThemeManager } from '../theme/UiThemeManager';
import { AppFontSize, AppRadius, AppSpacing, AppStroke } from '@quizzyjoy/foundation';
import { SizeLevel } from './CommonTypes';
import { MotionSpec } from '../motion/MotionSpec';

/** Loading 形态：环形旋转 / 呼吸三点 / 扫掠进度条。 */
export enum LoadingVariant {
  SPINNER = 'spinner',
  DOTS = 'dots',
  BAR = 'bar'
}

/* ---- SizeLevel 三档既定视觉规格（vp），命名集中、保形不取近令牌 ---- */
/** SPINNER 环外径三档。 */
const SPINNER_SIZE_SM: number = 20;
const SPINNER_SIZE_MD: number = 32;
const SPINNER_SIZE_LG: number = 44;
/** DOTS 点径三档。 */
const DOT_SIZE_SM: number = 8;
const DOT_SIZE_MD: number = 10;
const DOT_SIZE_LG: number = 14;
/** BAR 轨道宽三档。 */
const BAR_WIDTH_SM: number = 120;
const BAR_WIDTH_MD: number = 160;
const BAR_WIDTH_LG: number = 200;
/** DOTS 相邻点相位差（ms），呼吸波浪错峰节奏。 */
const DOT_PHASE_MS: number = 160;
/** DOTS 呼吸峰值缩放倍数。 */
const DOT_BREATH_SCALE: number = 1.4;
/** BAR 滑块往复位移（% 自身宽度）。 */
const BAR_TRAVEL_PERCENT: number = 100;
/** SPINNER 环宽（vp）——介于 AppStroke.MEDIUM(2)/THICK(4) 之间的视觉适配值。 */
const SPINNER_STROKE: number = 3;
/** qj_brand 令牌 hex 值（BAR 渐变透明端推导用，与 AppScope color.json 同源维护）。 */
const QJ_BRAND_HEX: string = '#0A59F7';

/**
 * CommonLoading —— 统一 Loading 指示器。
 *
 * 三形态一个组件：variant 枚举切换；尺寸三档；可选文案。
 * 动画全部走通用属性（rotate / scale / translate）+ UIContext.animateTo
 * iterations: -1 循环，零 @kit（符合 VitalUI 纯表现层纪律）。
 */
@ComponentV2
export struct CommonLoading {
  /** Loading 形态。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  @Param variant: LoadingVariant = LoadingVariant.SPINNER;
  /** 尺寸三档（SMALL/MEDIUM/LARGE，各形态有独立映射）。 */
  @Param sizeLevel: SizeLevel = SizeLevel.MEDIUM;
  /** 可选说明文案（空串 = 不显示）。 */
  @Param text: string = '';
  /** 强调色（空串 = qj_brand 令牌）。 */
  @Param accentColor: string = '';

  @Local spinAngle: number = 0;
  @Local dot0Scale: number = 1;
  @Local dot1Scale: number = 1;
  @Local dot2Scale: number = 1;
  @Local barShift: number = 0;

  private started: boolean = false;

  private accent(): ResourceColor {
    if (this.accentColor.length > 0) {
      return this.accentColor;
    }
    // 未显式传色时跟随主题包（v3.44：静态令牌也接入主题系统）
    return this.theme.brandColor();
  }

  /**
   * BAR 渐变起点：accent 的全透明同源色（修复 v3.7 前硬编码品牌蓝 rgba 的缺陷——
   * 自定义 accentColor 时渐变起点不再残留旧品牌色）。
   */
  private accentFadeStart(): string {
    const raw: string = this.accentColor.length > 0 ? this.accentColor
      : (this.theme.presetId === 'brand' && this.theme.accentColor.length === 0
        ? QJ_BRAND_HEX : this.theme.effectiveAccent());
    if (raw.length === 7) {
      return `#00${raw.slice(1)}`;
    }
    if (raw.length === 9) {
      return `#00${raw.slice(3)}`;
    }
    return 'rgba(0,0,0,0)';
  }

  private spinnerSize(): number {
    if (this.sizeLevel === SizeLevel.SMALL) {
      return SPINNER_SIZE_SM;
    }
    if (this.sizeLevel === SizeLevel.LARGE) {
      return SPINNER_SIZE_LG;
    }
    return SPINNER_SIZE_MD;
  }

  private dotSize(): number {
    if (this.sizeLevel === SizeLevel.SMALL) {
      return DOT_SIZE_SM;
    }
    if (this.sizeLevel === SizeLevel.LARGE) {
      return DOT_SIZE_LG;
    }
    return DOT_SIZE_MD;
  }

  private barWidth(): number {
    if (this.sizeLevel === SizeLevel.SMALL) {
      return BAR_WIDTH_SM;
    }
    if (this.sizeLevel === SizeLevel.LARGE) {
      return BAR_WIDTH_LG;
    }
    return BAR_WIDTH_MD;
  }

  private startAnimations(): void {
    if (this.started) {
      return;
    }
    this.started = true;
    const ui = this.getUIContext();
    if (this.variant === LoadingVariant.SPINNER) {
      ui.animateTo({
        duration: MotionSpec.DURATION_LOOP,
        curve: Curve.Linear,
        iterations: -1
      }, (): void => {
        this.spinAngle = 360;
      });
    } else if (this.variant === LoadingVariant.DOTS) {
      ui.animateTo({
        duration: MotionSpec.DURATION_LOOP,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      }, (): void => {
        this.dot0Scale = DOT_BREATH_SCALE;
      });
      ui.animateTo({
        duration: MotionSpec.DURATION_LOOP,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate,
        delay: DOT_PHASE_MS
      }, (): void => {
        this.dot1Scale = DOT_BREATH_SCALE;
      });
      ui.animateTo({
        duration: MotionSpec.DURATION_LOOP,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate,
        delay: DOT_PHASE_MS * 2
      }, (): void => {
        this.dot2Scale = DOT_BREATH_SCALE;
      });
    } else {
      ui.animateTo({
        duration: MotionSpec.DURATION_LOOP * 1.5,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      }, (): void => {
        this.barShift = BAR_TRAVEL_PERCENT;
      });
    }
  }

  build() {
    Column({ space: AppSpacing.SM }) {
      if (this.variant === LoadingVariant.SPINNER) {
        Column()
          .width(this.spinnerSize())
          .height(this.spinnerSize())
          .borderRadius(AppRadius.FULL)
          .border({
            width: SPINNER_STROKE,
            color: {
              left: this.accent(),
              top: this.accent(),
              right: Color.Transparent,
              bottom: Color.Transparent
            }
          })
          .rotate({ angle: this.spinAngle })
      } else if (this.variant === LoadingVariant.DOTS) {
        Row({ space: this.dotSize() * 0.8 }) {
          Column()
            .width(this.dotSize())
            .height(this.dotSize())
            .borderRadius(AppRadius.FULL)
            .backgroundColor(this.accent())
            .scale({ x: this.dot0Scale, y: this.dot0Scale })
          Column()
            .width(this.dotSize())
            .height(this.dotSize())
            .borderRadius(AppRadius.FULL)
            .backgroundColor(this.accent())
            .scale({ x: this.dot1Scale, y: this.dot1Scale })
          Column()
            .width(this.dotSize())
            .height(this.dotSize())
            .borderRadius(AppRadius.FULL)
            .backgroundColor(this.accent())
            .scale({ x: this.dot2Scale, y: this.dot2Scale })
        }
        .alignItems(VerticalAlign.Center)
      } else {
        Stack({ alignContent: Alignment.Start }) {
          Column()
            .width('100%')
            .height(AppStroke.THICK)
            .borderRadius(AppRadius.FULL)
            .backgroundColor($r('app.color.app_fill_subtle'))
          Column()
            .width('40%')
            .height(AppStroke.THICK)
            .borderRadius(AppRadius.FULL)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [[this.accentFadeStart(), 0], [this.accent(), 1]]
            })
            .translate({ x: `${this.barShift}%` })
        }
        .width(this.barWidth())
      }

      if (this.text.length > 0) {
        Text(this.text)
          .fontSize(AppFontSize.CAPTION)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_secondary'))
      }
    }
    .alignItems(HorizontalAlign.Center)
    .onAppear(() => {
      this.startAnimations();
    })
  }
}
