import { ChartEntry, ChartSeries, PieChart, QuarterRoseChart, RadarChart, RoseChart } from '@quizzyjoy/vitalui';
import { ButtonVariant, CommonButton } from '@easystart/app-component';
import { AppSection, AppTextDisplayModifier } from '@easystart/app-component';
import { AppFontSize, AppRadius, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, ColorModeManager } from '@quizzyjoy/platform';

/**
 * 样例子页 ③：数据看板（v3.9）。
 *
 * 【fork 可整体复制的页面范式】Canvas 自绘图表的看板页：深浅色联动
 * （ColorModeManager @ObservedV2 → isDark 注入，切换即重绘）、
 * 断点响应 GridRow 布局、onSelect 页底详情联动。
 */

/* ---- 样例数据（演示数据值，非样式值，不涉 v3.7 豁免登记） ---- */
const ROSE_DATA: ChartSeries = new ChartSeries('时段活跃', [
  new ChartEntry('清晨', 1), new ChartEntry('上午', 3), new ChartEntry('午后', 2),
  new ChartEntry('傍晚', 3), new ChartEntry('夜间', 2)
]);
const PIE_DATA: ChartSeries = new ChartSeries('渠道构成', [
  new ChartEntry('自然流量', 3), new ChartEntry('活动引流', 2),
  new ChartEntry('分享回流', 2), new ChartEntry('其他', 1)
]);
const QUARTER_DATA: ChartSeries = new ChartSeries('季度节奏', [
  new ChartEntry('一季度', 2), new ChartEntry('二季度', 3),
  new ChartEntry('三季度', 2), new ChartEntry('四季度', 1)
]);
const RADAR_DATA: ChartSeries = new ChartSeries('能力雷达', [
  new ChartEntry('敏捷', 2), new ChartEntry('力量', 3), new ChartEntry('智慧', 3),
  new ChartEntry('耐力', 2), new ChartEntry('速度', 1)
]);
/** 20 色色卡全量演示：等权重 1 → 玫瑰图每瓣依次取色板一位（C01 → C20）。 */
const PALETTE_DATA: ChartSeries = new ChartSeries('色卡全量取色', [
  new ChartEntry('C01', 1), new ChartEntry('C02', 1), new ChartEntry('C03', 1),
  new ChartEntry('C04', 1), new ChartEntry('C05', 1), new ChartEntry('C06', 1),
  new ChartEntry('C07', 1), new ChartEntry('C08', 1), new ChartEntry('C09', 1),
  new ChartEntry('C10', 1), new ChartEntry('C11', 1), new ChartEntry('C12', 1),
  new ChartEntry('C13', 1), new ChartEntry('C14', 1), new ChartEntry('C15', 1),
  new ChartEntry('C16', 1), new ChartEntry('C17', 1), new ChartEntry('C18', 1),
  new ChartEntry('C19', 1), new ChartEntry('C20', 1)
]);

@ComponentV2
export struct ChartsDashboardView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 深浅色单例（@ObservedV2 + @Trace：toggle 后 isDarkNow() 读取点自动重绘）。 */
  @Local colorMode: ColorModeManager = ColorModeManager.getInstance();
  /** 选中详情联动行（图表 onSelect 回写）。 */
  @Local selectedLabel: string = '';

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  pageHeader() {
    Column({ space: AppSpacing.XS }) {
      Text('数据看板')
        .attributeModifier(new AppTextDisplayModifier())
        .width('100%')
      Text('Canvas 自绘图表 + 深浅色联动重绘 + 选中详情联动（点击扇区/顶点）。')
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

          AppSection({ sectionTitle: '深浅色联动', description: '图表为 Canvas 自绘无法消费 $r 自动切换，经 ColorModeManager.isDarkNow() 注入重绘' }) {
            CommonButton({
              text: '切换深浅色',
              variant: ButtonVariant.SECONDARY,
              onAction: () => {
                this.colorMode.toggle();
              }
            })
          }

          AppSection({ sectionTitle: '四图表看板', description: 'GridRow 断点列数：宽屏 2 列 / 窄屏单列；gutter 走 DesignToken.gridGap' }) {
            GridRow({ columns: this.breakpoint.isWide() ? 2 : 1, gutter: DesignToken.gridGap(this.bp()) }) {
              GridCol({ span: 1 }) {
                Column() {
                  RoseChart({
                    data: ROSE_DATA,
                    isDark: this.colorMode.isDarkNow(),
                    onSelect: (entry: ChartEntry): void => {
                      this.selectedLabel = `时段活跃 · ${entry.text}`;
                    }
                  })
                }
                .width('100%')
                .padding(DesignToken.cardPadding())
                .borderRadius(AppRadius.XL)
                .backgroundColor($r('app.color.app_bg_card'))
              }
              GridCol({ span: 1 }) {
                Column() {
                  PieChart({
                    data: PIE_DATA,
                    showDot: true,
                    isDark: this.colorMode.isDarkNow(),
                    onSelect: (entry: ChartEntry): void => {
                      this.selectedLabel = `渠道构成 · ${entry.text}`;
                    }
                  })
                }
                .width('100%')
                .padding(DesignToken.cardPadding())
                .borderRadius(AppRadius.XL)
                .backgroundColor($r('app.color.app_bg_card'))
              }
              GridCol({ span: 1 }) {
                Column() {
                  QuarterRoseChart({
                    data: QUARTER_DATA,
                    isDark: this.colorMode.isDarkNow(),
                    onSelect: (entry: ChartEntry): void => {
                      this.selectedLabel = `季度节奏 · ${entry.text}`;
                    }
                  })
                }
                .width('100%')
                .padding(DesignToken.cardPadding())
                .borderRadius(AppRadius.XL)
                .backgroundColor($r('app.color.app_bg_card'))
              }
              GridCol({ span: 1 }) {
                Column() {
                  RadarChart({
                    data: RADAR_DATA,
                    isDark: this.colorMode.isDarkNow(),
                    onSelect: (entry: ChartEntry): void => {
                      this.selectedLabel = `能力雷达 · ${entry.text}`;
                    }
                  })
                }
                .width('100%')
                .padding(DesignToken.cardPadding())
                .borderRadius(AppRadius.XL)
                .backgroundColor($r('app.color.app_bg_card'))
              }
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '色卡全量取色（20 色 · 常量轨）', description: 'C01~C20 一次取满：色卡即图表默认分类色板（ChartEntry 不指定 color 时按序取色），深浅切换经 ColorModeManager 注入重绘' }) {
            GridRow({ columns: this.breakpoint.isWide() ? 2 : 1, gutter: DesignToken.gridGap(this.bp()) }) {
              GridCol({ span: 1 }) {
                Column() {
                  RoseChart({
                    data: PALETTE_DATA,
                    isDark: this.colorMode.isDarkNow(),
                    onSelect: (entry: ChartEntry): void => {
                      this.selectedLabel = `色卡全量取色 · ${entry.text}`;
                    }
                  })
                }
                .width('100%')
                .padding(DesignToken.cardPadding())
                .borderRadius(AppRadius.XL)
                .backgroundColor($r('app.color.app_bg_card'))
              }
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '选中详情联动', description: 'onSelect 上抛 → 页底详情行回写（V2 单向）' }) {
            Text(this.selectedLabel.length > 0 ? this.selectedLabel : '点击任意图表扇区/顶点查看详情')
              .fontSize(AppFontSize.BODY_SM)
              .fontColor(this.selectedLabel.length > 0
                ? $r('app.color.app_text_primary') : $r('app.color.app_text_tertiary'))
              .width('100%')
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
