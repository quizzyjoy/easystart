import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing } from '@quizzyjoy/foundation';

/**
 * 设置域统一自绘行（v3.36，替代 HdsListItemCard）。
 *
 * 替换原因：HdsListItemCard 自带约 17vp 横向内缩且无参数可调（HdsListItemCardOptions
 * 仅暴露 cardWidth / cardPrefixMargin / cardSuffixMargin），导致设置根页与自绘子页卡片
 * 左右边界不一致。自绘后左右边界完全由调用方的 pagePadding 决定。
 *
 * 结构：彩色图标 chip（可选）+ 标题/副标题 + 值文本 + 箭头；按下时前景变暗给出反馈。
 */
@ComponentV2
export struct SettingsRow {
  @Param title: ResourceStr = '';
  @Param subtitle: ResourceStr = '';
  @Param valueText: ResourceStr = '';
  /** 图标 symbol（不传则不显示图标区）。 */
  @Param icon: Resource | undefined = undefined;
  /** 图标底色（chip 背景），不传则不铺色块。 */
  @Param iconTint: ResourceColor = Color.Transparent;
  @Param showArrow: boolean = true;
  @Param onRowClick: () => void = (): void => {
  };
  @Local pressed: boolean = false;

  build() {
    Row({ space: AppSpacing.MD }) {
      if (this.icon !== undefined) {
        if (this.iconTint !== Color.Transparent) {
          Column() {
            SymbolGlyph(this.icon)
              .fontSize(AppSize.ICON_LG)
              .fontColor([$r('app.color.app_text_on_brand')])
          }
          .width(AppSize.ICON_CHIP)
          .height(AppSize.ICON_CHIP)
          .borderRadius(AppRadius.FULL)
          .backgroundColor(this.iconTint)
          .justifyContent(FlexAlign.Center)
        } else {
          SymbolGlyph(this.icon)
            .fontSize(AppSize.ICON_LG)
            .fontColor([$r('app.color.app_text_secondary')])
        }
      }

      Column({ space: AppSpacing.XXS }) {
        Text(this.title)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle !== '') {
          Text(this.subtitle)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.valueText !== '') {
        Text(this.valueText)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '40%' })
      }
      if (this.showArrow) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(AppFontSize.TITLE_SM)
          .fontColor([$r('app.color.app_text_tertiary')])
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({
      left: AppSpacing.MD,
      right: AppSpacing.MD,
      top: AppSpacing.SM,
      bottom: AppSpacing.SM
    })
    .borderRadius(AppRadius.LG)
    .backgroundColor(this.pressed ? $r('app.color.app_fill_subtle') : $r('app.color.app_bg_card'))
    .onClick((): void => {
      this.onRowClick();
    })
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}
