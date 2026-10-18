import {
  ButtonVariant,
  CommonButton,
  CommonTag,
  TagTone
} from '@quizzyjoy/vitalui';
import { AppSnackBar, AppDialog, AppSection, AppSheetContainer, AppSheetOptions, AppTextDisplayModifier, CommonToast, DialogSemantic } from '@easystart/app-component';
import { AppFontSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics } from '@quizzyjoy/platform';

/**
 * 样例子页 ②：反馈流（v3.9）。
 *
 * 【fork 可整体复制的页面范式】真实业务编排的反馈链路（非单点按钮示例）：
 * 提交失败→重试→成功、危险确认、筛选 Sheet 多选、轻提示降级对照。
 * fork 后替换为真实数据源即可。
 *
 * 【V2 单向绑定】AppSheet 显隐由本视图 @Local 持有，onDisappear/onClose 回写，
 * 不用 $$（画廊先例 ComponentGalleryView）。
 */

/** 模拟提交耗时（ms）——示例数据值，非样式值，不涉 v3.7 豁免登记。 */
const MOCK_SUBMIT_MS: number = 800;

/** 筛选选项。 */
const FILTER_OPTIONS: string[] = ['进行中', '已完成', '已收藏', '高优先级', '本周创建'];

@ComponentV2
export struct FeedbackFlowView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 提交中（按钮 loading 态）。 */
  @Local submitting: boolean = false;
  /** 首次提交已失败（显示重试按钮）。 */
  @Local failed: boolean = false;
  /** 筛选 Sheet 显隐。 */
  @Local sheetShow: boolean = false;
  /** 已选筛选项。 */
  @Local selectedFilters: string[] = [];
  private submitTimer: number = -1;

  aboutToDisappear(): void {
    if (this.submitTimer !== -1) {
      clearTimeout(this.submitTimer);
      this.submitTimer = -1;
    }
  }

  /** 模拟提交：fail 控制首达失败/重试成功的编排。 */
  private mockSubmit(fail: boolean): void {
    this.submitting = true;
    this.submitTimer = setTimeout(() => {
      this.submitTimer = -1;
      this.submitting = false;
      if (fail) {
        this.failed = true;
        AppSnackBar.error(this.getUIContext(), '提交失败：服务暂不可用', '错误');
      } else {
        this.failed = false;
        AppSnackBar.success(this.getUIContext(), '重试成功：数据已提交');
      }
    }, MOCK_SUBMIT_MS);
  }

  private toggleFilter(option: string): void {
    const index: number = this.selectedFilters.indexOf(option);
    if (index >= 0) {
      this.selectedFilters.splice(index, 1);
    } else {
      this.selectedFilters.push(option);
    }
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  filterSheetContent() {
    Column({ space: AppSpacing.MD }) {
      Text('多选后关闭 Sheet，onDisappear 回写并给出摘要反馈（V2 单向 + 回写）。')
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
      Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
        ForEach(FILTER_OPTIONS, (option: string) => {
          CommonTag({
            text: option,
            tone: this.selectedFilters.indexOf(option) >= 0 ? TagTone.BRAND : TagTone.NEUTRAL
          })
            .onClick(() => {
              this.toggleFilter(option);
            })
        }, (option: string) => option)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  filterSheetBuilder() {
    AppSheetContainer({
      sheetTitle: '筛选',
      contentBuilder: (): void => {
        this.filterSheetContent()
      },
      onClose: () => {
        this.sheetShow = false;
      }
    })
  }

  @Builder
  pageHeader() {
    Column({ space: AppSpacing.XS }) {
      Text('反馈流')
        .attributeModifier(new AppTextDisplayModifier())
        .width('100%')
      Text('真实业务编排的反馈链路：SnackBar 语义时长 / Dialog 危险确认 / Sheet 筛选回写。')
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

          AppSection({ sectionTitle: '提交失败 → 重试 → 成功', description: '按钮 loading 态 + 错误长驻 4.5s（AppSnackBar 语义时长）+ 重试成功短驻 1.5s' }) {
            Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
              CommonButton({
                text: '提交数据',
                variant: ButtonVariant.PRIMARY,
                loading: this.submitting,
                onAction: () => {
                  this.mockSubmit(true);
                }
              })
              if (this.failed) {
                CommonButton({
                  text: '重试提交',
                  variant: ButtonVariant.SECONDARY,
                  onAction: () => {
                    this.mockSubmit(false);
                  }
                })
              }
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '危险确认', description: 'AppDialog.open(DANGER)：危险语义自动切换红色主按钮，确认后才执行' }) {
            CommonButton({
              text: '删除这条数据',
              variant: ButtonVariant.DANGER,
              onAction: () => {
                AppDialog.open(this.getUIContext(), DialogSemantic.DANGER, '删除该数据？', '此操作不可撤销。', () => {
                  AppSnackBar.success(this.getUIContext(), '已删除');
                });
              }
            })
          }

          AppSection({ sectionTitle: '筛选 Sheet（多选）', description: 'AppSheetOptions.bind + AppSheetContainer + CommonTag 多选；关闭回写并摘要反馈' }) {
            CommonButton({
              text: '打开筛选',
              variant: ButtonVariant.SECONDARY,
              onAction: () => {
                this.sheetShow = true;
              }
            })
            if (this.selectedFilters.length > 0) {
              Text(`当前已选：${this.selectedFilters.join('、')}`)
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_secondary'))
                .width('100%')
                .margin({ top: AppSpacing.SM })
            }
          }

          AppSection({ sectionTitle: '轻提示降级对照', description: 'CommonToast（文本，全设备）与 AppSnackBar（HdsSnackBar，手表降级 Toast）' }) {
            Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
              CommonButton({
                text: 'CommonToast',
                variant: ButtonVariant.SECONDARY,
                onAction: () => {
                  CommonToast.info('轻提示：统一时长与语义入口');
                }
              })
              CommonButton({
                text: 'AppSnackBar 信息档',
                variant: ButtonVariant.SECONDARY,
                onAction: () => {
                  AppSnackBar.info(this.getUIContext(), '应用级信息反馈');
                }
              })
            }
            .width('100%')
            Text('降级链：AppSnackBar 内部 canIUse 守卫，HdsSnackBar 不可用（如 wearable）时自动降级 CommonToast，手表链路不崩。')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width('100%')
              .margin({ top: AppSpacing.SM })
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
        .bindSheet(this.sheetShow, this.filterSheetBuilder(), AppSheetOptions.bind({
          onDisappear: () => {
            this.sheetShow = false;
            if (this.selectedFilters.length > 0) {
              AppSnackBar.info(this.getUIContext(), `已选 ${this.selectedFilters.length} 项筛选`);
            }
          }
        }))
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
