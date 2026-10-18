import { SegmentButtonV2Items, TabSegmentButtonV2, CapsuleSegmentButtonV2 } from '@ohos.arkui.advanced.SegmentButtonV2';
import { LengthMetrics, ColorMetrics } from '@ohos.arkui.node';
import { UiThemeManager } from '@quizzyjoy/vitalui';

/**
 * AppSegment —— 主题化分段选择器（SegmentButtonV2 两形态）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * SegmentButtonV2 是系统高级组件（结构原语），但其选中字色 / 选中底色吃 ColorMetrics，
 * 裸用静态资源色不会随运行时强调色变化。本封装把选中态统一收口到运行时 accent
 * （空串回退 qj_brand 令牌），并固化应用的尺寸 / 圆角 / 配色规范 → 应用级。
 * 范式参考 EasyMath entry/common/SegmentButtonPresets.ets，区别是选中色由静态
 * app.color.primary 升级为运行时 accent，以支持「彻底换肤」。
 *
 * 【V2 受控】selectedIndex 由父持有，onIndexChange 上抛父回写（桥接系统 $selectedIndex）。
 *
 * 【用法】
 * Tab（分段卡）：AppTabSegment({ items: this.items, selectedIndex: this.idx,
 *                   onIndexChange: (i): void => { this.idx = i } })
 * Capsule（胶囊）：AppCapsuleSegment({ items: ..., selectedIndex: ..., onIndexChange: ... })
 *
 * 【@kit 纪律】SegmentButtonV2 / LengthMetrics / ColorMetrics 属 ArkUI 框架（@ohos.arkui.*），
 * 非 @kit 能力包；UiThemeManager 经 @quizzyjoy/vitalui，零直接 @kit。
 */

/** 运行时强调色 → ColorMetrics（SegmentButtonV2 颜色参数类型）；空串回退品牌令牌。
 *  resourceColor 形参为 ResourceColor（含 '#rrggbb' 字符串与 $r 资源），两种来源统一走它。 */
function accentToMetrics(accent: string): ColorMetrics {
  return ColorMetrics.resourceColor(accent.length > 0 ? accent : $r('app.color.qj_brand'));
}

/** Tab 形态分段（分段卡：选中项为卡片浮起、选中字为品牌色）。 */
@ComponentV2
export struct AppTabSegment {
  /** 分段项集合（父用 new SegmentButtonV2Items([...]) 构建）。 */
  @Param @Require items: SegmentButtonV2Items;
  /** 当前选中下标（父持有，经 onIndexChange 回写）。 */
  @Param selectedIndex: number = 0;
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 选中下标变化回调。 */
  @Event onIndexChange: (index: number) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  build() {
    TabSegmentButtonV2({
      items: this.items,
      selectedIndex: this.selectedIndex,
      $selectedIndex: (index: number): void => {
        this.onIndexChange(index);
      },
      itemFontColor: ColorMetrics.resourceColor($r('app.color.app_text_secondary')),
      itemSelectedFontColor: accentToMetrics(this.theme.accentColor),
      itemSelectedBackgroundColor: ColorMetrics.resourceColor($r('app.color.app_bg_card')),
      buttonBackgroundColor: ColorMetrics.resourceColor($r('app.color.app_fill_medium')),
      buttonBorderRadius: LengthMetrics.vp(10),
      itemBorderRadius: LengthMetrics.vp(8),
      itemMinHeight: LengthMetrics.vp(36),
      buttonMinHeight: LengthMetrics.vp(36),
      buttonPadding: LengthMetrics.vp(3),
      itemPadding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16),
        top: LengthMetrics.vp(6),
        bottom: LengthMetrics.vp(6)
      }
    })
      .enabled(this.isEnabled)
  }
}

/** Capsule 形态分段（胶囊：选中项填充品牌色、反白文字）。 */
@ComponentV2
export struct AppCapsuleSegment {
  /** 分段项集合（父用 new SegmentButtonV2Items([...]) 构建）。 */
  @Param @Require items: SegmentButtonV2Items;
  /** 当前选中下标（父持有，经 onIndexChange 回写）。 */
  @Param selectedIndex: number = 0;
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 选中下标变化回调。 */
  @Event onIndexChange: (index: number) => void = () => {
  };

  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  build() {
    CapsuleSegmentButtonV2({
      items: this.items,
      selectedIndex: this.selectedIndex,
      $selectedIndex: (index: number): void => {
        this.onIndexChange(index);
      },
      itemFontSize: LengthMetrics.vp(11),
      itemSelectedFontSize: LengthMetrics.vp(11),
      itemFontColor: ColorMetrics.resourceColor($r('app.color.app_text_secondary')),
      itemSelectedFontColor: ColorMetrics.resourceColor($r('app.color.qj_on_brand')),
      itemSelectedBackgroundColor: accentToMetrics(this.theme.accentColor),
      buttonBackgroundColor: ColorMetrics.resourceColor($r('app.color.app_fill_medium')),
      buttonBorderRadius: LengthMetrics.vp(16),
      itemBorderRadius: LengthMetrics.vp(14),
      itemMinHeight: LengthMetrics.vp(28),
      buttonMinHeight: LengthMetrics.vp(28),
      buttonPadding: LengthMetrics.vp(3),
      itemPadding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16),
        top: LengthMetrics.vp(6),
        bottom: LengthMetrics.vp(6)
      }
    })
      .enabled(this.isEnabled)
  }
}
