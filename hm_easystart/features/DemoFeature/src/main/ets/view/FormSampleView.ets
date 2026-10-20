import { CommonColorPickerSheet } from '@quizzyjoy/vitalui';
import { ButtonVariant, CommonButton, CommonTag, TagTone } from '@easystart/app-component';
import { AppDialog, AppFormField, AppSection, AppSnackBar, AppTextDisplayModifier, CommonSearchBar, CommonToast, DialogSemantic } from '@easystart/app-component';
import {
  AppCheckboxGroup,
  AppCounter,
  AppRadioGroup,
  AppSelectField,
  AppSwitchRow,
  AppTextArea
} from '@easystart/app-component';
import { AppFontSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';

/**
 * 样例子页 ④：表单范式（v3.9）。
 *
 * 【fork 可整体复制的页面范式】应用级表单交互链路：AppFormField 受控域 +
 * 逐域校验红线 + 品牌色取色实时联动 + 搜索防抖 + 提交确认闭环。
 *
 * 【分层说明】状态 @Local 于视图内——DemoFeature 为示例聚合；真实业务的
 * MVVM 分层范式见 HomeFeature（ViewModel + Repository + instanceof 收窄）。
 */

/** 模拟提交耗时（ms）——示例数据值，非样式值，不涉 v3.7 豁免登记。 */
const MOCK_SUBMIT_MS: number = 800;

@ComponentV2
export struct FormSampleView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 表单域受控值（父持有回写）。 */
  @Local nameValue: string = '';
  @Local emailValue: string = '';
  @Local noteValue: string = '';
  /** 逐域校验错误（非空即红线态）。 */
  @Local nameError: string = '';
  @Local emailError: string = '';
  /** 品牌色（数据值：与 AppScope qj_brand 同值，CommonLoading.QJ_BRAND_HEX 同源先例）。 */
  @Local brandColor: string = '#0A59F7';
  /** 扩展表单域示例态（v3.21 组件）。 */
  @Local detailValue: string = '';
  @Local genderLabel: string = '';
  @Local autoSync: boolean = true;
  @Local planIndex: number = 0;
  @Local interestChecked: boolean[] = [true, false, false];
  @Local qtyValue: number = 1;
  /** 搜索防抖回显。 */
  @Local lastSearch: string = '';
  /** 提交中。 */
  @Local submitting: boolean = false;
  private submitTimer: number = -1;

  aboutToDisappear(): void {
    if (this.submitTimer !== -1) {
      clearTimeout(this.submitTimer);
      this.submitTimer = -1;
    }
  }

  /** 校验：逐域写回错误文案；返回是否整体通过。 */
  private validate(): boolean {
    this.nameError = this.nameValue.trim().length === 0 ? '请输入名称' : '';
    this.emailError = this.emailValue.includes('@') ? '' : '邮箱格式不正确';
    return this.nameError.length === 0 && this.emailError.length === 0;
  }

  private submit(): void {
    if (!this.validate()) {
      AppSnackBar.error(this.getUIContext(), '请检查表单填写', '错误');
      return;
    }
    this.submitting = true;
    this.submitTimer = setTimeout(() => {
      this.submitTimer = -1;
      this.submitting = false;
      AppDialog.open(this.getUIContext(), DialogSemantic.CONFIRM, '提交确认',
        `名称：${this.nameValue}\n邮箱：${this.emailValue}`, () => {
          AppSnackBar.success(this.getUIContext(), '提交成功');
        });
    }, MOCK_SUBMIT_MS);
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  pageHeader() {
    Column({ space: AppSpacing.XS }) {
      Text('表单范式')
        .attributeModifier(new AppTextDisplayModifier())
        .width('100%')
      Text('AppFormField 受控域 + 逐域校验红线 + 取色实时联动 + 提交确认闭环。')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          this.pageHeader()

          AppSection({ sectionTitle: '输入域（AppFormField）', description: '标签/占位/辅助说明/错误红线；聚焦描边转品牌色，V2 单向父回写' }) {
            Column({ space: AppSpacing.LG }) {
              AppFormField({
                label: '名称',
                value: this.nameValue,
                placeholder: '请输入活动名称',
                errorText: this.nameError,
                supportingText: '必填，2-20 字',
                onValueChange: (val: string): void => {
                  this.nameValue = val;
                  this.nameError = '';
                }
              })
              AppFormField({
                label: '邮箱',
                value: this.emailValue,
                placeholder: 'name@example.com',
                errorText: this.emailError,
                supportingText: '用于接收确认邮件',
                onValueChange: (val: string): void => {
                  this.emailValue = val;
                  this.emailError = '';
                }
              })
              AppFormField({
                label: '备注',
                value: this.noteValue,
                placeholder: '选填',
                supportingText: '最多 64 字',
                maxLength: 64,
                onValueChange: (val: string): void => {
                  this.noteValue = val;
                }
              })
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '扩展表单域（AppTextArea / AppSelectField / AppSwitchRow / AppCounter）', description: '多行 / 下拉 / 开关行 / 计数器——聚焦描边与激活态随强调色换肤' }) {
            Column({ space: AppSpacing.LG }) {
              AppTextArea({
                label: '详细描述',
                value: this.detailValue,
                placeholder: '多行输入',
                supportingText: '多行文本域，聚焦描边随强调色',
                onValueChange: (v: string): void => {
                  this.detailValue = v;
                }
              })
              AppSelectField({
                label: '性别',
                value: this.genderLabel,
                placeholder: '点击选择',
                onSelect: (): void => {
                  this.genderLabel = this.genderLabel === '男' ? '女' : '男';
                }
              })
              AppSwitchRow({
                label: '自动同步',
                description: '开关选中色随强调色（AppToggle 收口）',
                isOn: this.autoSync,
                onChange: (v: boolean): void => {
                  this.autoSync = v;
                }
              })
              AppCounter({
                value: this.qtyValue,
                min: 1,
                max: 10,
                onChange: (v: number): void => {
                  this.qtyValue = v;
                }
              })
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '选项组（AppRadioGroup / AppCheckboxGroup）', description: '单选 / 多选组，索引受控不依赖系统 group，选中态随强调色' }) {
            Column({ space: AppSpacing.LG }) {
              AppRadioGroup({
                options: ['方案 A', '方案 B', '方案 C'],
                selectedIndex: this.planIndex,
                onChange: (i: number): void => {
                  this.planIndex = i;
                }
              })
              AppCheckboxGroup({
                options: ['选项一', '选项二', '选项三'],
                selectedIndexes: this.interestChecked,
                onChange: (i: number, v: boolean): void => {
                  const next: boolean[] = [...this.interestChecked];
                  next[i] = v;
                  this.interestChecked = next;
                }
              })
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '品牌色实时联动', description: 'CommonColorPickerSheet 草稿-确认语义（拖动不回调，确定才生效）→ CommonTag BRAND 注入' }) {
            CommonColorPickerSheet({
              color: this.brandColor,
              title: '选取品牌色',
              onColorChange: (color: string): void => {
                this.brandColor = color;
              }
            })
            CommonTag({ text: '品牌色实时联动', tone: TagTone.BRAND, accentColor: this.brandColor })
              .margin({ top: AppSpacing.SM })
          }

          AppSection({ sectionTitle: '搜索防抖（CommonSearchBar）', description: '组件内 300ms 防抖；onSearch 上抛后由本视图消费' }) {
            CommonSearchBar({
              value: this.lastSearch,
              showCancel: true,
              onSearch: (keyword: string): void => {
                this.lastSearch = keyword;
                if (keyword.length > 0) {
                  CommonToast.info(`搜索：${keyword}`);
                }
              },
              onCancel: (): void => {
                this.lastSearch = '';
              }
            })
            Text(this.lastSearch.length > 0 ? `最近搜索：${this.lastSearch}` : '输入后停顿 300ms 触发回调')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width('100%')
              .margin({ top: AppSpacing.SM })
          }

          AppSection({ sectionTitle: '提交校验流', description: '空提交 → 逐域红线 + 错误 snackbar；通过 → 确认对话框摘要 → 成功 snackbar' }) {
            CommonButton({
              text: '提交表单',
              variant: ButtonVariant.PRIMARY,
              accentColor: this.brandColor,
              fullWidth: true,
              loading: this.submitting,
              onAction: () => {
                this.submit();
              }
            })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
        .padding({
          left: DesignToken.pagePadding(this.bp()),
          right: DesignToken.pagePadding(this.bp()),
          top: AppSpacing.LG,
          bottom: AppSpacing.XXXL
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
