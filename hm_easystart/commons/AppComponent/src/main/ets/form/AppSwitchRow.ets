import { AppFontSize, AppFontWeight, AppSpacing } from '@quizzyjoy/foundation';
import { AppToggle } from '../control/AppToggle';

/**
 * AppSwitchRow —— 带标签与说明的开关行（表单/设置类行范式）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 「左标签 + 说明（可省略）+ 右侧主题化开关」的行排布是本应用表单交互规范，
 * 开关选中色随运行时强调色（AppToggle 收口）→ 应用级（判据见指南 §17）。
 * 与设置页 HdsListItemCard 的 SuffixSwitch 分工：设置页走 HDS 原生范式，
 * 自由表单需要随强调色换肤的开关行用本组件。零 @kit。
 *
 * 【V2 单向绑定】isOn 由父持有，onChange 上抛父回写。
 *
 * 【用法】AppSwitchRow({ label: '自动同步', description: '后台自动同步数据',
 *   isOn: this.autoSync, onChange: (v: boolean): void => { this.autoSync = v } })
 */
@ComponentV2
export struct AppSwitchRow {
  /** 行标签（BODY + 主文本）。 */
  @Param label: string = '';
  /** 说明文案（CAPTION + 次要色；空串不渲染）。 */
  @Param description: string = '';
  /** 开关状态（父持有，经 onChange 回写）。 */
  @Param isOn: boolean = false;
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 状态变化回调。 */
  @Event onChange: (isOn: boolean) => void = () => {
  };

  build() {
    Row() {
      Column({ space: AppSpacing.XXS }) {
        Text(this.label)
          .fontSize(AppFontSize.BODY)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        if (this.description.length > 0) {
          Text(this.description)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
            .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      AppToggle({
        isOn: this.isOn,
        isEnabled: this.isEnabled,
        onChange: (isOn: boolean): void => {
          this.onChange(isOn);
        }
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.MD, bottom: AppSpacing.MD })
  }
}
