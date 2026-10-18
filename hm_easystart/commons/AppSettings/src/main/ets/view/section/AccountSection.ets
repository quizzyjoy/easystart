import { IconSize, HdsListItemCard, PrefixIcon, SuffixArrow } from '@kit.UIDesignKit';
import { SettingsRoute } from '../../model/SettingsRoute';

/**
 * 账号卡（设置主页，v3.28 TODO-019；v3.32 宽度统一）：登录占位卡。
 *
 * 结构进模板、内容 fork 填：无账号体系时保持占位形态（头像符号 +
 * 点击登录），接入真实账号体系后仅需替换头像数据源与登录态文案；
 * 点击域内自理跳账号子页（SettingsRoute.ACCOUNT，互禁不破）。
 *
 * 【v3.32 为什么改用 HdsListItemCard】原自绘 Row 的背景宽度为「页面 padding 内全宽」，
 * 而设置行的 `HdsListItemCard` 自带约 17vp 横向内缩（`HdsListItemCardOptions` 无整卡
 * margin/padding 字段，负 margin 与 `cardWidth` 均无效——实测），两者背景宽度相差约 33vp，
 * 视觉上「登录卡宽、其他行窄」。改用同一组件后所有行背景自然同宽同缩进。
 */
@ComponentV2
export struct AccountSection {
  /** 设置域内层导航栈（v3.32 双层栈：账号子页压内层栈）。 */
  @Param settingsStack: NavPathStack = new NavPathStack();

  build() {
    HdsListItemCard({
      prefixItem: new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { symbol: $r('sys.symbol.person_crop_circle_fill') }
      }),
      textItem: {
        primaryText: { text: $r('app.string.settings_account_title') },
        secondaryText: { text: $r('app.string.settings_account_tap_login') }
      },
      suffixItem: new SuffixArrow(),
      cardBackgroundColor: $r('app.color.app_bg_card'),
      onClick: (): void => {
        this.settingsStack.pushPath({ name: SettingsRoute.ACCOUNT });
      }
    })
      .width('100%')
  }
}
