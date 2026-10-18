import { AppFontSize, AppRadius, AppSpacing, AppSize, AppStroke } from '@quizzyjoy/foundation';
import { ColorMath, Hsv, Rgb } from '../util/ColorMath';
import { ChartPalette } from '../chart/ChartData';

/*
 * 【令牌豁免登记（v3.7）】取色域固有常量不走 design token：
 * - PRESET_COLORS：复用图表 20 色色卡（ChartPalette.forMode(false)）；DEFAULT_COLOR：品牌色 hex 种子（Canvas/渐变仅收字符串）；
 * - HUE_GRADIENT / 光谱白→透明叠层 / 指示器阴影 hex：色相学/取色面板物理属性，非视觉规范值；
 * - 图表调色板同类豁免先例见 ChartData.ets。
 */

/** 页签类型（对齐 API 26 HdsColorPickerTabType：GRID / SPECTRUM / SLIDERS）。 */
export enum ColorPickerTabType {
  GRID = 0,
  SPECTRUM = 1,
  SLIDERS = 2
}

/** 取色器配置（对齐 HdsColorPickerOptions）。 */
export class ColorPickerOptions {
  /** GRID 页签色圆半径（vp，原生默认 12、<10 钳制为 10——钳制在组件内执行）。 */
  circleRadius: number = 12;
  /** 显示的页签集合（默认全部，与原生默认一致）。 */
  tabs: ColorPickerTabType[] = [
    ColorPickerTabType.GRID,
    ColorPickerTabType.SPECTRUM,
    ColorPickerTabType.SLIDERS
  ];

  constructor(circleRadius: number = 12,
    tabs: ColorPickerTabType[] = [
      ColorPickerTabType.GRID,
      ColorPickerTabType.SPECTRUM,
      ColorPickerTabType.SLIDERS
    ]) {
    this.circleRadius = circleRadius;
    this.tabs = tabs;
  }
}

/** GRID 页签预设色（复用图表 20 色色卡 light 套——ChartPalette 为唯一事实源，零双份维护）。 */
const PRESET_COLORS: string[] = [...ChartPalette.forMode(false)];

/** initialColor 为空 / 非法时的回退色（qj_brand）。 */
const DEFAULT_COLOR: string = '#0a59f7';

/** 收藏上限（原生文档：最多可收藏并显示 72 个颜色值）。 */
const MAX_FAVORITES: number = 72;

/** 指示器尺寸（vp）。 */
const THUMB_SIZE: number = 18;
const THUMB_HALF: number = 9;
const THUMB_STROKE: number = 2.5;

/** 指示器投影（取色域固有，豁免登记见文件头）。 */
const THUMB_SHADOW_STRONG: string = '#44000000';
const THUMB_SHADOW_SOFT: string = '#33000000';

/** 色相环渐变（红 → … → 红，360° 闭环）——光谱横轴与色相滑杆共用。 */
const HUE_GRADIENT: Array<[ResourceColor, number]> = [
  ['#FF0000', 0.000], ['#FF4400', 0.083], ['#FF8800', 0.167],
  ['#CCDD00', 0.250], ['#00FF00', 0.333], ['#00FF88', 0.417],
  ['#00FFFF', 0.500], ['#0088FF', 0.583], ['#0000FF', 0.667],
  ['#7700FF', 0.750], ['#FF00FF', 0.833], ['#FF0088', 0.917],
  ['#FF0000', 1.000]
];

/** 输入归一化：无 # 前缀自动补齐（原生回调存在不带 # 的先例）；校验交给 ColorMath。 */
function normalizeSeed(hex: string): string {
  if (hex.length > 0 && !hex.startsWith('#')) {
    return `#${hex}`;
  }
  return hex;
}

/** 收藏归一化：合法校验 → 小写 7 位规范形 → 去重 → 上限 72（对齐原生）。 */
function normalizeFavorites(input: string[]): string[] {
  const result: string[] = [];
  input.forEach((color: string): void => {
    const rgb: Rgb | undefined = ColorMath.hexToRgb(normalizeSeed(color));
    if (rgb === undefined) {
      return;
    }
    const canonical: string = ColorMath.rgbToHex(rgb.r, rgb.g, rgb.b);
    if (result.indexOf(canonical) < 0 && result.length < MAX_FAVORITES) {
      result.push(canonical);
    }
  });
  return result;
}

/**
 * CommonColorPicker —— HdsColorPicker（API 26，UIDesignKit）的 API 23 仿照复刻（HDS 例外 E7）。
 *
 * 【仿照声明】本组件**不导入** @kit.UIDesignKit（VitalUI 零 @kit 宪章），
 * 依据本机 SDK @hms.hds.HdsColorPicker.d.ets 与官方文档（26.0.0 API 参考 +
 * 《颜色选择与收藏管理》开发指南，devecocli docs）做高保真语义仿照，API 23~26 全量可用。
 *
 * API 对齐（与原生逐项一致）：
 * - initialColor / onColorSelected（拖动实时回调，无确认按钮）
 * - initialFavoriteColors / onFavoriteColorsUpdate（收藏由宿主持久化；上限 72，对齐原生）
 * - options { circleRadius, tabs }（默认 12vp / 三页签全开；<10 钳制为 10，对齐原生）
 *
 * 页签语义对齐（官方文档措辞）：
 * - GRID：预设颜色网格；
 * - SPECTRUM：「色相和饱和度光谱」——x 轴色相 0-360°、y 轴饱和度 0-100%、明度恒 V=100
 *   （明度调节归 SLIDERS 页签，与原生三模式分工一致）；
 * - SLIDERS：「色相、饱和度、明度滑块」（HSB 三滑杆）。
 *
 * 有意差异（原生未公开细节 / 本工程约束，见复核报告 #70）：
 * - 输出恒为 '#rrggbb' 小写 7 位：原生回调格式不统一（ARGB/无 # 均有先例），
 *   本组件输入宽容（#RGB / #RRGGBB / #AARRGGBB / 无 # 前缀均可，alpha 忽略）、输出稳定，
 *   宿主无需再做 normalizeColor；Sheet/UiThemeManager 均按 7 位消费；
 * - GRID 预设色为本模板品牌/语义种子色（原生预设色板未公开）；
 * - 收藏"添加"入口为预览行星标（原生收藏交互官方未公开图示），收藏/移除/更新语义与原生一致；
 * - 设备约束（原生仅 Phone/Tablet）不适用于纯自绘复刻，四形态均可渲染。
 */
@ComponentV2
export struct CommonColorPicker {
  /** 初始色（#RRGGBB / #AARRGGBB 均可；空/非法回退 DEFAULT_COLOR）。 */
  @Param initialColor: string = '';
  /** 拖动实时回调（无确认按钮，对齐 HdsColorPicker 语义；输出 #rrggbb）。 */
  @Event onColorSelected: (color: string) => void = () => {
  };
  /** 初始收藏色列表（hex 数组，收藏持久化由宿主承担；上限 72，对齐原生）。 */
  @Param initialFavoriteColors: string[] = [];
  /** 收藏列表变更回调。 */
  @Event onFavoriteColorsUpdate: (favorites: string[]) => void = () => {
  };
  /** 取色器配置（色圆半径 + 页签集合）。 */
  @Param options: ColorPickerOptions = new ColorPickerOptions();

  /** 默认状态 = DEFAULT_COLOR（qj_brand #0a59f7）的 HSV。 */
  @Local activeTab: ColorPickerTabType = ColorPickerTabType.GRID;
  @Local hue: number = 220;
  @Local sat: number = 96;
  @Local val: number = 97;
  @Local favorites: string[] = [];
  @Local blockW: number = 0;
  @Local blockH: number = 0;
  @Local barW: number = 0;

  aboutToAppear(): void {
    const parsed: Hsv | undefined = ColorMath.hexToHsv(normalizeSeed(this.initialColor));
    const seed: Hsv = parsed !== undefined ? parsed : ColorMath.hexToHsv(DEFAULT_COLOR) as Hsv;
    this.hue = seed.h;
    this.sat = seed.s;
    this.val = seed.v;
    this.favorites = normalizeFavorites(this.initialFavoriteColors);
    this.activeTab = this.options.tabs.length > 0 ? this.options.tabs[0] : ColorPickerTabType.GRID;
  }

  private currentHex(): string {
    return ColorMath.hsvToHex(this.hue, this.sat, this.val);
  }

  /** 色圆半径（原生规则：值 <10 一律取 10；整数化）。 */
  private pickerRadius(): number {
    const rounded: number = Math.round(this.options.circleRadius);
    return rounded < 10 ? 10 : rounded;
  }

  private applyHex(hex: string): void {
    const hsv: Hsv | undefined = ColorMath.hexToHsv(normalizeSeed(hex));
    if (hsv !== undefined) {
      this.hue = hsv.h;
      this.sat = hsv.s;
      this.val = hsv.v;
      this.onColorSelected(this.currentHex());
    }
  }

  private isFavorite(hex: string): boolean {
    return this.favorites.indexOf(hex) >= 0;
  }

  private toggleFavorite(): void {
    const hex: string = this.currentHex();
    const next: string[] = [];
    this.favorites.forEach((color: string): void => {
      if (color !== hex) {
        next.push(color);
      }
    });
    if (!this.isFavorite(hex) && next.length < MAX_FAVORITES) {
      next.push(hex);
    }
    this.favorites = next;
    this.onFavoriteColorsUpdate(next);
  }

  private tabLabel(tab: ColorPickerTabType): string {
    if (tab === ColorPickerTabType.GRID) {
      return '色板';
    }
    if (tab === ColorPickerTabType.SPECTRUM) {
      return '光谱';
    }
    return '滑杆';
  }

  /**
   * HSB 滑杆维度（对齐原生 SLIDERS）：
   * 0=色相（0-360，全色相环渐变）1=饱和度（0-100）2=明度（0-100）。
   */
  private channelValue(index: number): number {
    if (index === 0) {
      return this.hue;
    }
    if (index === 1) {
      return this.sat;
    }
    return this.val;
  }

  private channelMax(index: number): number {
    return index === 0 ? 360 : 100;
  }

  private channelLabel(index: number): string {
    if (index === 0) {
      return '色相';
    }
    if (index === 1) {
      return '饱和';
    }
    return '明度';
  }

  private channelGradient(index: number): Array<[ResourceColor, number]> {
    if (index === 0) {
      return HUE_GRADIENT;
    }
    if (index === 1) {
      return [
        [ColorMath.hsvToHex(this.hue, 0, this.val), 0],
        [ColorMath.hsvToHex(this.hue, 100, this.val), 1]
      ];
    }
    return [
      [ColorMath.hsvToHex(this.hue, this.sat, 0), 0],
      [ColorMath.hsvToHex(this.hue, this.sat, 100), 1]
    ];
  }

  private applyChannel(index: number, ratio: number): void {
    const value: number = Math.round(ColorMath.clamp(ratio, 0, 1) * this.channelMax(index));
    if (index === 0) {
      this.hue = value;
    } else if (index === 1) {
      this.sat = value;
    } else {
      this.val = value;
    }
    this.onColorSelected(this.currentHex());
  }

  build() {
    Column({ space: AppSpacing.MD }) {
      if (this.options.tabs.length > 1) {
        this.tabBar()
      }
      if (this.activeTab === ColorPickerTabType.GRID) {
        this.gridTab()
      }
      if (this.activeTab === ColorPickerTabType.SPECTRUM) {
        this.spectrumTab()
      }
      if (this.activeTab === ColorPickerTabType.SLIDERS) {
        this.slidersTab()
      }
      this.previewRow()
    }
    .width('100%')
    .padding({
      left: AppSpacing.LG,
      right: AppSpacing.LG,
      top: AppSpacing.MD,
      bottom: AppSpacing.MD
    })
    .backgroundColor($r('app.color.app_bg_card'))
    .borderRadius(AppRadius.LG)
  }

  @Builder
  tabBar() {
    Row({ space: AppSpacing.XS }) {
      ForEach(this.options.tabs, (tab: ColorPickerTabType) => {
        Text(this.tabLabel(tab))
          .fontSize(AppFontSize.CAPTION)
          .fontColor(this.activeTab === tab
            ? $r('app.color.qj_brand') : $r('app.color.app_text_secondary'))
          .padding({
            left: AppSpacing.MD,
            right: AppSpacing.MD,
            top: AppSpacing.XS,
            bottom: AppSpacing.XS
          })
          .backgroundColor(this.activeTab === tab
            ? $r('app.color.qj_brand_light') : Color.Transparent)
          .borderRadius(AppRadius.FULL)
          .onClick(() => {
            this.activeTab = tab;
          })
      }, (tab: ColorPickerTabType) => `${tab}`)
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  gridTab() {
    Column({ space: AppSpacing.SM }) {
      Text('预设')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(PRESET_COLORS, (color: string) => {
          Column()
            .width(this.pickerRadius() * 2)
            .height(this.pickerRadius() * 2)
            .borderRadius(this.pickerRadius())
            .backgroundColor(color)
            .border({
              width: AppStroke.MEDIUM,
              color: this.currentHex() === color
                ? $r('app.color.app_text_primary') : Color.Transparent
            })
            .margin({ right: AppSpacing.MD, bottom: AppSpacing.SM })
            .onClick(() => {
              this.applyHex(color);
            })
        }, (color: string) => color)
      }
      .width('100%')

      if (this.favorites.length > 0) {
        Text('收藏')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.favorites, (color: string) => {
            Column()
              .width(this.pickerRadius() * 2)
              .height(this.pickerRadius() * 2)
              .borderRadius(this.pickerRadius())
              .backgroundColor(color)
              .border({
                width: AppStroke.MEDIUM,
                color: this.currentHex() === color
                  ? $r('app.color.app_text_primary') : Color.Transparent
              })
              .margin({ right: AppSpacing.MD, bottom: AppSpacing.SM })
              .onClick(() => {
                this.applyHex(color);
              })
          }, (color: string) => color)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 光谱页签：色相 × 饱和度光谱（官方语义），明度恒 V=100（明度调节归滑杆页签）。 */
  @Builder
  spectrumTab() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: HUE_GRADIENT
        })

      Row()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#FFFFFF', 0], ['#00FFFFFF', 1]]
        })

      Column()
        .width(THUMB_SIZE)
        .height(THUMB_SIZE)
        .borderRadius(AppRadius.FULL)
        .backgroundColor(Color.Transparent)
        .border({ width: AppStroke.MEDIUM, color: Color.White })
        .shadow({ radius: AppSpacing.MD, color: THUMB_SHADOW_STRONG })
        .offset({
          x: this.blockW > 0 ? (this.hue / 360) * this.blockW - THUMB_HALF : 0,
          y: this.blockH > 0 ? (this.sat / 100) * this.blockH - THUMB_HALF : 0
        })
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .aspectRatio(1.6)
    .borderRadius(AppRadius.MD)
    .clip(true)
    .onAreaChange((_: Area, newArea: Area) => {
      this.blockW = Number(newArea.width);
      this.blockH = Number(newArea.height);
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down || event.type === TouchType.Move) {
        if (this.blockW > 0 && this.blockH > 0) {
          const rx: number = ColorMath.clamp(event.touches[0].x / this.blockW, 0, 1);
          const ry: number = ColorMath.clamp(event.touches[0].y / this.blockH, 0, 1);
          this.hue = Math.round(rx * 360);
          this.sat = Math.round(ry * 100);
          this.onColorSelected(this.currentHex());
        }
      }
    })
  }

  /** 滑杆页签：HSB 三滑杆（色相 / 饱和 / 明度），维度语义对齐原生 SLIDERS。 */
  @Builder
  slidersTab() {
    Column({ space: AppSpacing.MD }) {
      this.channelBar(0)
      this.channelBar(1)
      this.channelBar(2)
    }
    .width('100%')
  }

  @Builder
  channelBar(index: number) {
    Column({ space: AppSpacing.XS }) {
      Row({ space: AppSpacing.XS }) {
        Text(this.channelLabel(index))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
        Text(`${this.channelValue(index)}`)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_primary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(AppSpacing.LG)
          .borderRadius(AppRadius.FULL)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: this.channelGradient(index)
          })

        Column()
          .width(THUMB_SIZE)
          .height(THUMB_SIZE)
          .borderRadius(AppRadius.FULL)
          .backgroundColor(Color.White)
          .border({ width: THUMB_STROKE, color: this.currentHex() })
          .shadow({ radius: AppSpacing.SM, color: THUMB_SHADOW_SOFT })
          .offset({
            x: this.barW > 0
              ? (this.channelValue(index) / this.channelMax(index)) * this.barW - THUMB_HALF : 0,
            y: -1
          })
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .onAreaChange((_: Area, newArea: Area) => {
        this.barW = Number(newArea.width);
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down || event.type === TouchType.Move) {
          if (this.barW > 0) {
            const ratio: number = ColorMath.clamp(event.touches[0].x / this.barW, 0, 1);
            this.applyChannel(index, ratio);
          }
        }
      })
    }
    .width('100%')
  }

  @Builder
  previewRow() {
    Row({ space: AppSpacing.MD }) {
      Column()
        .width(AppSize.TOUCH_MIN)
        .height(AppSize.TOUCH_MIN)
        .borderRadius(AppRadius.FULL)
        .backgroundColor(this.currentHex())
        .border({ width: AppStroke.THIN, color: $r('app.color.app_divider') })

      Text(this.currentHex())
        .fontSize(AppFontSize.BODY)
        .fontColor($r('app.color.app_text_primary'))

      Blank()

      Text(this.isFavorite(this.currentHex()) ? '★ 已收藏' : '☆ 收藏')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.qj_brand'))
        .padding({
          left: AppSpacing.MD,
          right: AppSpacing.MD,
          top: AppSpacing.SM,
          bottom: AppSpacing.SM
        })
        .onClick(() => {
          this.toggleFavorite();
        })
    }
    .width('100%')
  }
}
