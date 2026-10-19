import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing } from '@quizzyjoy/foundation';

/**
 * 设置域「控件行」自绘组件（v3.36）。
 *
 * 与 SettingsRow 一样，左右边界由调用方 pagePadding 决定，不承受 HdsListItemCard 的
 * 固有内缩。三种控件行分别覆盖开关 / 选择 / 滑杆，替代 Hds 的 SuffixSwitch /
 * SuffixSelect / SuffixCustomBuilder。三者各自独立实现（ArkUI 不允许把 @Builder
 * 当普通函数参数传递后再调用）。
 */

@Builder
function leadingIcon(icon: Resource | undefined, iconTint: ResourceColor) {
  if (icon !== undefined) {
    if (iconTint !== Color.Transparent) {
      Column() {
        SymbolGlyph(icon)
          .fontSize(AppSize.ICON_LG)
          .fontColor([$r('app.color.app_text_on_brand')])
      }
      .width(AppSize.ICON_CHIP)
      .height(AppSize.ICON_CHIP)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(iconTint)
      .justifyContent(FlexAlign.Center)
    } else {
      SymbolGlyph(icon)
        .fontSize(AppSize.ICON_LG)
        .fontColor([$r('app.color.app_text_secondary')])
    }
  }
}

@Builder
function titleBlock(title: ResourceStr, subtitle: ResourceStr) {
  Column({ space: AppSpacing.XXS }) {
    Text(title)
      .fontSize(AppFontSize.BODY)
      .fontWeight(AppFontWeight.MEDIUM)
      .fontColor($r('app.color.app_text_primary'))
      .width('100%')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
    if (subtitle !== '') {
      Text(subtitle)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
  }
  .layoutWeight(1)
  .alignItems(HorizontalAlign.Start)
}

const ROW_PADDING: Padding = {
  left: AppSpacing.MD,
  right: AppSpacing.MD,
  top: AppSpacing.SM,
  bottom: AppSpacing.SM
};

/** 开关行。 */
@ComponentV2
export struct SettingsSwitchRow {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Param icon: Resource | undefined = undefined;
  @Param iconTint: ResourceColor = Color.Transparent;
  @Param isOn: boolean = false;
  @Param onToggle: (on: boolean) => void = (_on: boolean): void => {
  };

  build() {
    Row({ space: AppSpacing.MD }) {
      leadingIcon(this.icon, this.iconTint)
      titleBlock(this.title, this.subtitle)
      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor($r('app.color.qj_brand'))
        .onChange((isOn: boolean): void => {
          this.onToggle(isOn);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(ROW_PADDING)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
  }
}

/** 选择行（原生 Select 下拉）。 */
@ComponentV2
export struct SettingsSelectRow {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Param icon: Resource | undefined = undefined;
  @Param iconTint: ResourceColor = Color.Transparent;
  @Param options: ResourceStr[] = [];
  @Param selected: number = 0;
  @Param onSelect: (index: number) => void = (_index: number): void => {
  };

  build() {
    Row({ space: AppSpacing.MD }) {
      leadingIcon(this.icon, this.iconTint)
      titleBlock(this.title, this.subtitle)
      Select(this.options.map((label: ResourceStr): SelectOption => {
        let text: string = '';
        if (typeof label === 'string') {
          text = label;
        }
        return { value: text } as SelectOption;
      }))
        .selected(this.selected)
        .font({ size: AppFontSize.BODY_SM })
        .fontColor($r('app.color.app_text_secondary'))
        .backgroundColor(Color.Transparent)
        .onSelect((index: number): void => {
          this.onSelect(index);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(ROW_PADDING)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
  }
}

/** 滑杆行。 */
@ComponentV2
export struct SettingsSliderRow {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Param icon: Resource | undefined = undefined;
  @Param iconTint: ResourceColor = Color.Transparent;
  @Param value: number = 0;
  @Param min: number = 0;
  @Param max: number = 100;
  @Param step: number = 1;
  @Param onChangeEnd: (value: number) => void = (_value: number): void => {
  };

  build() {
    Row({ space: AppSpacing.MD }) {
      leadingIcon(this.icon, this.iconTint)
      titleBlock(this.title, this.subtitle)
      Slider({
        value: this.value,
        min: this.min,
        max: this.max,
        step: this.step
      })
        .width('50%')
        .selectedColor($r('app.color.qj_brand'))
        .onChange((value: number, mode: SliderChangeMode): void => {
          if (mode === SliderChangeMode.End) {
            this.onChangeEnd(value);
          }
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(ROW_PADDING)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
  }
}
