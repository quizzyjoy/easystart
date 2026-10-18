import { AppSpacing } from '@quizzyjoy/foundation';
import { AppCheckbox } from '../control/AppCheckbox';

/**
 * AppCheckboxGroup —— 纵向多选组（应用级表单规范，组合 AppCheckbox）。
 *
 * 【落位注释：为什么在 AppComponent？】
 * 多选组「纵向排列 + 项间距 SM + 受控勾选集合」的排布律是应用表单规范 → 应用级。
 * 勾选态由父持 boolean[] 受控（V2 单向），组件不依赖系统 Checkbox group 联动
 * 语义——每项独立 AppCheckbox（name 空、group 空），避免跨组串扰。零 @kit。
 *
 * 【V2 单向绑定】selectedIndexes（boolean[] 对齐 options）由父持有，
 * onChange(index, isChecked) 上抛父回写对应位。
 *
 * 【用法】AppCheckboxGroup({ options: ['A', 'B', 'C'], selectedIndexes: this.checked,
 *   onChange: (i: number, v: boolean): void => { this.checked[i] = v } })
 */
@ComponentV2
export struct AppCheckboxGroup {
  /** 选项文本集合。 */
  @Param options: string[] = [];
  /** 各选项勾选态（boolean[] 对齐 options；缺位视为 false）。 */
  @Param selectedIndexes: boolean[] = [];
  /** 是否可交互。 */
  @Param isEnabled: boolean = true;
  /** 勾选态变化回调（index 为选项下标，isChecked 为新勾选态）。 */
  @Event onChange: (index: number, isChecked: boolean) => void = () => {
  };

  build() {
    Column({ space: AppSpacing.SM }) {
      ForEach(this.options, (option: string, index: number) => {
        AppCheckbox({
          isChecked: index < this.selectedIndexes.length ? this.selectedIndexes[index] : false,
          label: option,
          isEnabled: this.isEnabled,
          onChange: (isChecked: boolean): void => {
            this.onChange(index, isChecked);
          }
        })
      }, (option: string, index: number) => `${index}_${option}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
