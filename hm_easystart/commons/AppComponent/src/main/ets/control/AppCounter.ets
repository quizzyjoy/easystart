import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing } from '@quizzyjoy/foundation';

/**
 * AppCounter —— 主题化计数器（减号 + 值 + 加号）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 计数器是系统可组合结构（Button/SymbolGlyph/Text），但其「激活态图标色跟随运行时
 * 强调色、边界置灰、触摸目标 40vp」是应用的控件规范——裸搭不会随 UiThemeManager
 * 换色、且边界/尺寸不统一 → 应用级（判据见指南 §17）。零 @kit。
 *
 * 【V2 单向绑定】value 由父持有，onChange 上抛父回写；组件内只做 clamp 防越界
 * （不回写父，父在 onChange 里自行 setState 收敛）。
 *
 * 【用法】AppCounter({ value: this.qty, min: 1, max: 10,
 *   onChange: (v: number): void => { this.qty = v } })
 */
@ComponentV2
export struct AppCounter {
  /** 当前值（父持有，经 onChange 回写）。 */
  @Param value: number = 0;
  /** 最小值（默认 0）。 */
  @Param min: number = 0;
  /** 最大值（默认 99）。 */
  @Param max: number = 99;
  /** 步长（默认 1）。 */
  @Param step: number = 1;
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 值变化回调（组件已 clamp 到 [min, max]）。 */
  @Event onChange: (value: number) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  private brandColor(): ResourceColor {
    return this.theme.brandColor();
  }

  private clamp(v: number): number {
    return Math.min(this.max, Math.max(this.min, v));
  }

  /** 减号可用（值仍高于下界）。 */
  private canDecrease(): boolean {
    return this.isEnabled && this.value > this.min;
  }

  /** 加号可用（值仍低于上界）。 */
  private canIncrease(): boolean {
    return this.isEnabled && this.value < this.max;
  }

  build() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.minus'))
          .fontSize(AppSize.ICON_SM)
          .fontColor([this.canDecrease() ? this.brandColor() : $r('app.color.app_text_quaternary')])
      }
      .width(AppSize.TOUCH_MIN)
      .height(AppSize.TOUCH_MIN)
      .backgroundColor($r('app.color.app_fill_subtle'))
      .enabled(this.canDecrease())
      .onClick((): void => {
        this.onChange(this.clamp(this.value - this.step));
      })

      Text(`${this.value}`)
        .fontSize(AppFontSize.BODY)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .textAlign(TextAlign.Center)
        .constraintSize({ minWidth: AppSize.TOUCH_STANDARD })
        .margin({ left: AppSpacing.MD, right: AppSpacing.MD })

      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(AppSize.ICON_SM)
          .fontColor([this.canIncrease() ? this.brandColor() : $r('app.color.app_text_quaternary')])
      }
      .width(AppSize.TOUCH_MIN)
      .height(AppSize.TOUCH_MIN)
      .backgroundColor($r('app.color.app_fill_subtle'))
      .enabled(this.canIncrease())
      .onClick((): void => {
        this.onChange(this.clamp(this.value + this.step));
      })
    }
    .alignItems(VerticalAlign.Center)
  }
}
