import { PreferenceKeys } from '@easystart/app-preferences';
import { ButtonVariant, CommonButton, CommonColorPickerSheet, CommonTag, TagTone, UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppSpacing, Logger } from '@quizzyjoy/foundation';
import { PreferencesStore, UiMetrics } from '@quizzyjoy/platform';

const DOMAIN: string = 'settings';
const TAG: string = 'AccentColorSetting';

/**
 * 强调色设置（外观组复合卡片内容，v3.13 由 ThemeSettingsView 转型）。
 *
 * 视觉：说明文案 + CommonColorPickerSheet（胶囊色块，点按唤起取色半模态）
 *      + 恢复默认 + 品牌组件效果预览。
 * 外层卡片容器（圆角 / 背景 / padding）由 DisplaySection 统一提供，
 * 本组件不自带卡片壳与 Scroll，可直接嵌入。
 *
 * 主题双机制：颜色模式（base/dark）走系统与 AppScope 资源覆盖契约；
 * 强调色由 UiThemeManager 运行时注入 VitalUI 组件 accentColor，经 PreferencesStore 持久化。
 * 冷启动恢复链（v3.15 起）：AppBootstrap.restoreAccentColor 读出色值 → phone/pc/tv
 * 入口 Ability 注入 UiThemeManager（修复冷启动停在首页/画廊时回退默认蓝的缺口）；
 * 本组件 aboutToAppear 的 restoreAccent 负责进入本页时幂等再同步并恢复收藏色。
 */
@ComponentV2
export struct AccentColorSetting {
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local restoring: boolean = true;
  @Local favorites: string[] = [];

  aboutToAppear(): void {
    this.restoreAccent();
  }

  private isHexColor(value: string): boolean {
    const lower: string = value.toLowerCase();
    return lower.length === 7 && lower.startsWith('#');
  }

  private async restoreAccent(): Promise<void> {
    let saved: string = await PreferencesStore.getString(PreferenceKeys.ACCENT_COLOR, '');
    if (saved.length === 0) {
      // v2.1 预设枚举迁移：'default' → 回退令牌；预设枚举值本身是 hex，直通
      const legacy: string = await PreferencesStore.getString(PreferenceKeys.ACCENT_COLOR_LEGACY, '');
      if (this.isHexColor(legacy)) {
        saved = legacy.toLowerCase();
      } else {
        saved = '';
      }
    }
    if (saved.length > 0) {
      this.theme.setAccentColor(saved);
    }
    this.restoring = false;
    Logger.info(DOMAIN, TAG, `accent restored: ${saved}`);
    this.restoreFavorites();
  }

  private async restoreFavorites(): Promise<void> {
    const joined: string = await PreferencesStore.getString(PreferenceKeys.FAVORITE_COLORS, '');
    const list: string[] = [];
    joined.split(',').forEach((part: string): void => {
      const color: string = part.trim().toLowerCase();
      if (this.isHexColor(color) && list.indexOf(color) < 0) {
        list.push(color);
      }
    });
    this.favorites = list.slice(0, PreferenceKeys.FAVORITE_MAX);
  }

  private applyColor(color: string): void {
    if (color.length === 0) {
      this.theme.reset();
    } else {
      this.theme.setAccentColor(color);
    }
    PreferencesStore.put(PreferenceKeys.ACCENT_COLOR, color);
  }

  private saveFavorites(favorites: string[]): void {
    const capped: string[] = favorites.slice(0, PreferenceKeys.FAVORITE_MAX);
    this.favorites = capped;
    PreferencesStore.put(PreferenceKeys.FAVORITE_COLORS, capped.join(','));
  }

  build() {
    Column({ space: AppSpacing.MD }) {
      Text($r('app.string.settings_accent_desc'))
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')

      CommonColorPickerSheet({
        color: this.theme.accentColor,
        initialFavoriteColors: this.favorites,
        onColorChange: (color: string): void => {
          this.applyColor(color);
        },
        onFavoritesChange: (favorites: string[]): void => {
          this.saveFavorites(favorites);
        }
      })

      CommonButton({
        text: $r('app.string.settings_accent_reset'),
        variant: ButtonVariant.TEXT,
        onAction: (): void => {
          this.applyColor('');
        }
      })

      Text($r('app.string.settings_accent_preview'))
        .fontSize(AppFontSize.TITLE_SM)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')
        .margin({ top: AppSpacing.SM })

      Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
        CommonButton({
          text: $r('app.string.settings_accent_preview_primary'),
          variant: ButtonVariant.PRIMARY,
          accentColor: this.theme.accentColor
        })
        CommonButton({
          text: $r('app.string.settings_accent_preview_secondary'),
          variant: ButtonVariant.SECONDARY,
          accentColor: this.theme.accentColor
        })
        CommonTag({
          text: $r('app.string.settings_accent_preview_tag'),
          tone: TagTone.BRAND,
          accentColor: this.theme.accentColor
        })
      }
      .width('100%')

      if (this.restoring) {
        Text($r('app.string.settings_accent_restoring'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
