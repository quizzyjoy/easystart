import { AppSpacing } from '@quizzyjoy/foundation';
import { AppRadio } from '../control/AppRadio';

/**
 * AppRadioGroup —— 纵向单选组（应用级表单规范，组合 AppRadio）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 单选组「纵向排列 + 项间距 SM + 受控选中」的排布律是应用表单规范 → 应用级。
 * 选中态由父持 selectedIndex 受控（V2 单向），组件不依赖系统 Radio group 互斥
 * 语义——内部 group 名固定仅满足 AppRadio 必填，互斥由 selectedIndex 计算实现，
 * 避免多实例同名 group 串扰。零 @kit。
 *
 * 【V2 单向绑定】selectedIndex 由父持有，onChange 上抛父回写。
 *
 * 【用法】AppRadioGroup({ options: ['方案 A', '方案 B'], selectedIndex: this.idx,
 *   onChange: (i: number): void => { this.idx = i } })
 */
@ComponentV2
export struct AppRadioGroup {
  /** 选项文本集合。 */
  @Param options: string[] = [];
  /** 当前选中下标（父持有；-1 表示未选）。 */
  @Param selectedIndex: number = -1;
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 选中下标变化回调。 */
  @Event onChange: (index: number) => void = () => {
  };

  build() {
    Column({ space: AppSpacing.SM }) {
      ForEach(this.options, (option: string, index: number) => {
        AppRadio({
          value: option,
          group: 'app_radio_group',
          checked: index === this.selectedIndex,
          label: option,
          isEnabled: this.isEnabled,
          onChange: (): void => {
            this.onChange(index);
          }
        })
      }, (option: string, index: number) => `${index}_${option}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
