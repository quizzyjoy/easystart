import { UiThemeManager } from '../theme/UiThemeManager';
import { AppFontSize, AppRadius, AppSpacing } from '@quizzyjoy/foundation';

/** 标签语义色。 */
export enum TagTone {
  NEUTRAL = 'neutral',
  BRAND = 'brand',
  SUCCESS = 'success',
  WARNING = 'warning',
  DANGER = 'danger'
}

/**
 * CommonTag —— 状态/分类标签。
 * 颜色跟随主题（$r('app.color.*')），支持可关闭。
 * accentColor 非空时 BRAND 档使用注入色。
 * v2.6：反馈三档（SUCCESS/WARNING/DANGER）底色改用语义容器色（M3 container 模式）。
 */
@ComponentV2
export struct CommonTag {
  /** 标签文案。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  @Param text: ResourceStr = '';
  /** 语义色调（NEUTRAL/BRAND/SUCCESS/WARNING/DANGER）。 */
  @Param tone: TagTone = TagTone.NEUTRAL;
  /** 是否显示关闭按钮。 */
  @Param closable: boolean = false;
  /** BRAND 档注入色（空串回退 qj_brand 令牌）。 */
  @Param accentColor: string = '';
  /** 关闭按钮点击回调。 */
  @Event onClose: () => void = () => {
  };

  private bg(): ResourceColor {
    if (this.tone === TagTone.BRAND) {
      return $r('app.color.qj_brand_light');
    }
    if (this.tone === TagTone.SUCCESS) {
      return $r('app.color.app_success_container');
    }
    if (this.tone === TagTone.WARNING) {
      return $r('app.color.app_warning_container');
    }
    if (this.tone === TagTone.DANGER) {
      return $r('app.color.app_danger_container');
    }
    return $r('app.color.app_fill_subtle');
  }

  private fg(): ResourceColor {
    if (this.tone === TagTone.BRAND) {
      return this.accentColor.length > 0 ? this.accentColor : this.theme.brandColor();
    }
    if (this.tone === TagTone.SUCCESS) {
      return $r('app.color.app_success');
    }
    if (this.tone === TagTone.WARNING) {
      return $r('app.color.app_warning');
    }
    if (this.tone === TagTone.DANGER) {
      return $r('app.color.app_danger');
    }
    return $r('app.color.app_text_secondary');
  }

  build() {
    Row({ space: AppSpacing.XS }) {
      Text(this.text)
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.fg())
      if (this.closable) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor([this.fg()])
          .padding(AppSpacing.SM)
          .onClick(() => {
            this.onClose();
          })
      }
    }
    .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
    .backgroundColor(this.bg())
    .borderRadius(AppRadius.FULL)
}
}
