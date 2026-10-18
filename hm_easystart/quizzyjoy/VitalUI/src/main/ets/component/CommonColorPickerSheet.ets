import { AppFontSize, AppRadius, AppSpacing, AppStroke, AppSize } from '@quizzyjoy/foundation';
import { ButtonVariant } from './CommonButton';
import { CommonButton } from './CommonButton';
import { CommonColorPicker } from './CommonColorPicker';

/**
 * CommonColorPickerSheet —— CommonColorPicker 的半模态封装。
 *
 * 视觉：胶囊色块（当前色 + hex 文案）→ 点按唤起 bindSheet（detents 半模态）。
 * 交互：面板本身无确认按钮（对齐 HdsColorPicker）；取消/确定由本封装承担——
 * 拖动只写 draft，确定才回调 onColorChange，取消丢弃。
 */
@ComponentV2
export struct CommonColorPickerSheet {
  /** 当前色（回显；'' = 跟随主题令牌）。 */
  @Param color: string = '';
  /** 初始收藏色列表（hex 数组）。 */
  @Param initialFavoriteColors: string[] = [];
  /** 面板标题。 */
  @Param title: string = '选取颜色';
  /** 确定回调（仅点击「确定」时触发，拖动草稿不回调）。 */
  @Event onColorChange: (color: string) => void = () => {
  };
  /** 收藏列表变更回调。 */
  @Event onFavoritesChange: (favorites: string[]) => void = () => {
  };

  @Local show: boolean = false;
  @Local draft: string = '';

  private swatchColor(): ResourceColor {
    if (this.color.length === 7) {
      return this.color;
    }
    return $r('app.color.qj_brand');
  }

  private open(): void {
    this.draft = this.color;
    this.show = true;
  }

  @Builder
  sheetBuilder() {
    Column() {
      Text(this.title)
        .fontSize(AppFontSize.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')
        .margin({ top: AppSpacing.LG, bottom: AppSpacing.SM })

      Scroll() {
        Column() {
          CommonColorPicker({
            initialColor: this.draft,
            initialFavoriteColors: this.initialFavoriteColors,
            onColorSelected: (color: string): void => {
              this.draft = color;
            },
            onFavoriteColorsUpdate: (favorites: string[]): void => {
              this.onFavoritesChange(favorites);
            }
          })
        }
        .width('100%')
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
      }
      .layoutWeight(1)
      .align(Alignment.Start)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      Row({ space: AppSpacing.MD }) {
        CommonButton({
          text: '取消',
          variant: ButtonVariant.TEXT,
          onAction: (): void => {
            this.show = false;
          }
        })
        CommonButton({
          text: '确定',
          variant: ButtonVariant.PRIMARY,
          accentColor: this.draft,
          onAction: (): void => {
            this.onColorChange(this.draft);
            this.show = false;
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({
        left: AppSpacing.LG,
        right: AppSpacing.LG,
        top: AppSpacing.MD,
        bottom: AppSpacing.LG
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
  }

  build() {
    Row({ space: AppSpacing.MD }) {
      Column()
        .width(AppSize.ICON_XL)
        .height(AppSize.ICON_XL)
        .borderRadius(AppRadius.FULL)
        .backgroundColor(this.swatchColor())
        .border({ width: AppStroke.THIN, color: $r('app.color.app_divider') })

      Column({ space: AppSpacing.XXS }) {
        Text(this.color.length === 7 ? this.color : $r('app.string.vitalui_color_follow_theme'))
          .fontSize(AppFontSize.BODY)
          .fontColor($r('app.color.app_text_primary'))
        Text($r('app.string.vitalui_color_tap_to_change'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text($r('app.string.vitalui_color_change'))
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.qj_brand'))
    }
    .width('100%')
    .padding({
      left: AppSpacing.MD,
      right: AppSpacing.MD,
      top: AppSpacing.SM,
      bottom: AppSpacing.SM
    })
    .borderRadius(AppRadius.XXL)
    .backgroundColor($r('app.color.app_fill_subtle'))
    .onClick(() => {
      this.open();
    })
    .bindSheet($$this.show, this.sheetBuilder(), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      showClose: false,
      dragBar: true
    })
  }
}
