import {
  AppFontWeight,
  AppFontSize,
  AppLineHeight,
  AppRadius,
  AppShadow,
  AppSize,
  AppSpacing,
  AppStroke,
  AppZIndex,
  DesignToken
} from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';
import { AppSection, AppTextDisplayModifier } from '@easystart/app-component';

/**
 * 样例子页 ①：令牌总览（v3.9）。
 *
 * 【fork 可整体复制的页面范式】Foundation 令牌真相源的可视化对照——页面即代码
 * 真相：字阶/圆角/间距/描边/阴影/尺寸/层级/行高/色板全量展示 + DesignToken
 * 语义方法断点实测。fork 后可作为设计走查页直接保留或删除。
 *
 * 展示数据模型为令牌常量的镜像（名称 + 值 + 标注），属「数据值」非样式值，
 * 不涉 v3.7 豁免登记；渲染样式全部消费令牌。
 */

/** 字阶展示行：常量名 + 样文 + 字号 + v3.6 官方字重指派。 */
class TypeScaleRow {
  name: string = '';
  sample: string = '';
  size: number = 0;
  weight: FontWeight | number = FontWeight.Normal;

  constructor(name: string, sample: string, size: number, weight: FontWeight | number) {
    this.name = name;
    this.sample = sample;
    this.size = size;
    this.weight = weight;
  }
}

/** 数值刻度展示行（圆角/间距/尺寸/描边/层级通用）。 */
class ScaleRow {
  name: string = '';
  value: number = 0;

  constructor(name: string, value: number) {
    this.name = name;
    this.value = value;
  }
}

/** 阴影展示行（ShadowStyle 预设）。 */
class ShadowRow {
  name: string = '';
  style: ShadowStyle = ShadowStyle.OUTER_DEFAULT_XS;

  constructor(name: string, style: ShadowStyle) {
    this.name = name;
    this.style = style;
  }
}

/** 行高展示行（同字号三比例对排）。 */
class LineHeightRow {
  name: string = '';
  ratio: number = 1.5;

  constructor(name: string, ratio: number) {
    this.name = name;
    this.ratio = ratio;
  }
}

/** 字阶十档（v3.6 官方字阶对齐；字重指派见 AppFontWeight 头注）。 */
const TYPE_SCALE_ROWS: TypeScaleRow[] = [
  new TypeScaleRow('CAPTION_XS', '极辅助信息 10', AppFontSize.CAPTION_XS, AppFontWeight.MEDIUM),
  new TypeScaleRow('CAPTION', '辅助说明 12', AppFontSize.CAPTION, AppFontWeight.MEDIUM),
  new TypeScaleRow('BODY_SM', '次要正文 14', AppFontSize.BODY_SM, AppFontWeight.REGULAR),
  new TypeScaleRow('BODY', '正文内容 16', AppFontSize.BODY, AppFontWeight.REGULAR),
  new TypeScaleRow('TITLE_SM', '小标题 18', AppFontSize.TITLE_SM, AppFontWeight.BOLD),
  new TypeScaleRow('TITLE', '标题 20', AppFontSize.TITLE, AppFontWeight.BOLD),
  new TypeScaleRow('TITLE_LG', '大标题 24', AppFontSize.TITLE_LG, AppFontWeight.BOLD),
  new TypeScaleRow('HEADLINE', '页面主标题 30', AppFontSize.HEADLINE, AppFontWeight.BOLD),
  new TypeScaleRow('DISPLAY_SM', '展示数字 38', AppFontSize.DISPLAY_SM, AppFontWeight.LIGHT),
  new TypeScaleRow('DISPLAY', '首屏大字 48', AppFontSize.DISPLAY, AppFontWeight.LIGHT)
];

/** 圆角十档（v3.6 官方场景映射见 AppRadius 头注）。 */
const RADIUS_ROWS: ScaleRow[] = [
  new ScaleRow('NONE', AppRadius.NONE),
  new ScaleRow('XS', AppRadius.XS),
  new ScaleRow('SM', AppRadius.SM),
  new ScaleRow('MD', AppRadius.MD),
  new ScaleRow('LG', AppRadius.LG),
  new ScaleRow('XL·卡片', AppRadius.XL),
  new ScaleRow('XXL·按钮', AppRadius.XXL),
  new ScaleRow('XXXL·对话框', AppRadius.XXXL),
  new ScaleRow('HUGE·半模态', AppRadius.HUGE),
  new ScaleRow('FULL', AppRadius.FULL)
];

/** 间距八档（8pt 栅格）。 */
const SPACING_ROWS: ScaleRow[] = [
  new ScaleRow('XXS', AppSpacing.XXS),
  new ScaleRow('XS', AppSpacing.XS),
  new ScaleRow('SM', AppSpacing.SM),
  new ScaleRow('MD', AppSpacing.MD),
  new ScaleRow('LG', AppSpacing.LG),
  new ScaleRow('XL', AppSpacing.XL),
  new ScaleRow('XXL', AppSpacing.XXL),
  new ScaleRow('XXXL', AppSpacing.XXXL)
];

/** 描边四档（含焦点环 FOCUS_MARGIN 单独示例）。 */
const STROKE_ROWS: ScaleRow[] = [
  new ScaleRow('HAIR', AppStroke.HAIR),
  new ScaleRow('THIN', AppStroke.THIN),
  new ScaleRow('MEDIUM', AppStroke.MEDIUM),
  new ScaleRow('THICK', AppStroke.THICK)
];

/** 阴影六预设（ShadowStyle 官方预设，克制律：同屏 ≤2 档为使用建议）。 */
const SHADOW_ROWS: ShadowRow[] = [
  new ShadowRow('XS·卡片默认', AppShadow.XS),
  new ShadowRow('SM·悬浮', AppShadow.SM),
  new ShadowRow('MD·对话框', AppShadow.MD),
  new ShadowRow('LG·全屏模态', AppShadow.LG),
  new ShadowRow('FLOAT_SM·气泡', AppShadow.FLOAT_SM),
  new ShadowRow('FLOAT_MD·Toast', AppShadow.FLOAT_MD)
];

/** 触摸目标三档（点击热区红线 40vp 起）。 */
const TOUCH_ROWS: ScaleRow[] = [
  new ScaleRow('TOUCH_MIN·底线', AppSize.TOUCH_MIN),
  new ScaleRow('TOUCH_STANDARD·标准', AppSize.TOUCH_STANDARD),
  new ScaleRow('TOUCH_COMFORT·舒适', AppSize.TOUCH_COMFORT)
];

/** 图标六档。 */
const ICON_ROWS: ScaleRow[] = [
  new ScaleRow('ICON_XS', AppSize.ICON_XS),
  new ScaleRow('ICON_SM', AppSize.ICON_SM),
  new ScaleRow('ICON_MD', AppSize.ICON_MD),
  new ScaleRow('ICON_LG', AppSize.ICON_LG),
  new ScaleRow('ICON_XL', AppSize.ICON_XL),
  new ScaleRow('ICON_XXL', AppSize.ICON_XXL)
];

/** 层级五级（自绘浮层排序参考）。 */
const ZINDEX_ROWS: ScaleRow[] = [
  new ScaleRow('CONTENT·内容', AppZIndex.CONTENT),
  new ScaleRow('STICKY·吸顶', AppZIndex.STICKY),
  new ScaleRow('SHEET·半模态', AppZIndex.SHEET),
  new ScaleRow('DIALOG·对话框', AppZIndex.DIALOG),
  new ScaleRow('TOAST·轻提示', AppZIndex.TOAST)
];

/** 行高三比例（正文档 16 对排）。 */
const LINE_HEIGHT_ROWS: LineHeightRow[] = [
  new LineHeightRow('TIGHT·1.2', AppLineHeight.TIGHT),
  new LineHeightRow('NORMAL·1.5', AppLineHeight.NORMAL),
  new LineHeightRow('RELAXED·1.65', AppLineHeight.RELAXED)
];

@ComponentV2
export struct DesignTokensView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /** 色彩令牌色块（画廊 colorSwatch 同构，色值经 $r 资源随深浅色自动切换）。 */
  @Builder
  colorSwatch(label: string, color: ResourceColor) {
    Column({ space: AppSpacing.XXS }) {
      Column()
        .width(AppSize.ICON_XL)
        .height(AppSize.ICON_XL)
        .borderRadius(AppRadius.MD)
        .backgroundColor(color)
        .border({ width: AppStroke.THIN, color: $r('app.color.app_divider') })
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
    }
    .constraintSize({ minWidth: AppSize.TOUCH_COMFORT })
    .alignItems(HorizontalAlign.Center)
    .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
  }

  /** 数值刻度通用标注行（名称 + 值）。 */
  @Builder
  scaleLabel(name: string, value: number) {
    Row({ space: AppSpacing.SM }) {
      Text(name)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .layoutWeight(1)
      Text(`${value}`)
        .fontSize(AppFontSize.CAPTION)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
    }
    .width('100%')
  }

  @Builder
  pageHeader() {
    Column({ space: AppSpacing.XS }) {
      Text('令牌总览')
        .attributeModifier(new AppTextDisplayModifier())
        .width('100%')
      Text('设计令牌真相源可视化——页面即代码真相，可直接用于设计走查。')
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

          AppSection({ sectionTitle: '字阶十档', description: '官方字阶对齐（v3.6）：Display=Light / Title=Bold / Caption=Medium / Body=Regular' }) {
            ForEach(TYPE_SCALE_ROWS, (row: TypeScaleRow) => {
              Row({ space: AppSpacing.SM }) {
                Text(row.name)
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_tertiary'))
                  .layoutWeight(1)
                Text(row.sample)
                  .fontSize(row.size)
                  .fontWeight(row.weight)
                  .fontColor($r('app.color.app_text_primary'))
                  .layoutWeight(2)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
            }, (row: TypeScaleRow) => row.name)
          }

          AppSection({ sectionTitle: '圆角十档', description: '卡片 XL(16) / 按钮·输入框 XXL(20) / 对话框 XXXL(24) / 半模态 HUGE(32)' }) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(RADIUS_ROWS, (row: ScaleRow) => {
                Column({ space: AppSpacing.XXS }) {
                  Column()
                    .width(AppSize.TOUCH_STANDARD)
                    .height(AppSize.TOUCH_STANDARD)
                    .borderRadius(row.value)
                    .backgroundColor($r('app.color.app_bg_card'))
                    .border({ width: AppStroke.THIN, color: $r('app.color.app_divider') })
                  this.scaleLabel(row.name, row.value)
                }
                .alignItems(HorizontalAlign.Center)
                .margin({ right: AppSpacing.MD, bottom: AppSpacing.MD })
              }, (row: ScaleRow) => row.name)
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '间距八档', description: '8pt 栅格：横条宽度 = 间距值' }) {
            ForEach(SPACING_ROWS, (row: ScaleRow) => {
              Row({ space: AppSpacing.MD }) {
                Text(row.name)
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_secondary'))
                  .width(AppSize.TOUCH_COMFORT)
                Column()
                  .height(AppSize.ICON_SM)
                  .width(row.value)
                  .borderRadius(AppRadius.XS)
                  .backgroundColor($r('app.color.qj_brand'))
                Text(`${row.value}vp`)
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_tertiary'))
              }
              .alignItems(VerticalAlign.Center)
              .width('100%')
            }, (row: ScaleRow) => row.name)
          }

          AppSection({ sectionTitle: '描边四档 + 焦点环', description: '常规边框 1 / 选中·焦点 2 / 焦点环外边距 2（官方惯例）' }) {
            ForEach(STROKE_ROWS, (row: ScaleRow) => {
              Row({ space: AppSpacing.MD }) {
                Text(row.name)
                  .fontSize(AppFontSize.CAPTION)
                  .fontColor($r('app.color.app_text_secondary'))
                  .width(AppSize.TOUCH_COMFORT)
                Row()
                  .layoutWeight(1)
                  .border({ width: row.value, color: $r('app.color.app_text_quaternary') })
              }
              .alignItems(VerticalAlign.Center)
              .width('100%')
            }, (row: ScaleRow) => row.name)
            Row({ space: AppSpacing.MD }) {
              Text('焦点环样例')
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_secondary'))
                .width(AppSize.TOUCH_COMFORT)
              Column()
                .width(AppSize.ICON_XL)
                .height(AppSize.ICON_XL)
                .borderRadius(AppRadius.MD)
                .margin(AppStroke.FOCUS_MARGIN)
                .border({ width: AppStroke.MEDIUM, color: $r('app.color.app_state_focus') })
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '阴影六预设', description: 'ShadowStyle 官方预设 + 原始值表（BLUR_*/OFFSET_Y_*）；克制律：同屏 ≤2 档' }) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(SHADOW_ROWS, (row: ShadowRow) => {
                Column({ space: AppSpacing.XS }) {
                  Column()
                    .width('100%')
                    .height(AppSize.TOUCH_STANDARD)
                    .borderRadius(AppRadius.XL)
                    .backgroundColor($r('app.color.app_bg_card'))
                    .shadow(row.style)
                  Text(row.name)
                    .fontSize(AppFontSize.CAPTION)
                    .fontColor($r('app.color.app_text_tertiary'))
                }
                .alignItems(HorizontalAlign.Start)
                .constraintSize({ minWidth: '28%' })
                .layoutWeight(1)
                .margin({ right: AppSpacing.SM, bottom: AppSpacing.MD })
              }, (row: ShadowRow) => row.name)
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '触摸目标三档 + 图标六档', description: '点击热区红线：不得小于 40vp×40vp（HarmonyOS UX 标准）' }) {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(TOUCH_ROWS, (row: ScaleRow) => {
                Column({ space: AppSpacing.XXS }) {
                  Column()
                    .width(row.value)
                    .height(row.value)
                    .borderRadius(AppRadius.MD)
                    .backgroundColor($r('app.color.app_fill_medium'))
                  this.scaleLabel(row.name, row.value)
                }
                .alignItems(HorizontalAlign.Center)
                .margin({ right: AppSpacing.MD, bottom: AppSpacing.MD })
              }, (row: ScaleRow) => row.name)
              ForEach(ICON_ROWS, (row: ScaleRow) => {
                Column({ space: AppSpacing.XXS }) {
                  Column()
                    .width(row.value)
                    .height(row.value)
                    .borderRadius(AppRadius.SM)
                    .backgroundColor($r('app.color.qj_brand'))
                  this.scaleLabel(row.name, row.value)
                }
                .alignItems(HorizontalAlign.Center)
                .margin({ right: AppSpacing.MD, bottom: AppSpacing.MD })
              }, (row: ScaleRow) => row.name)
            }
            .width('100%')
          }

          AppSection({ sectionTitle: '层级序 AppZIndex', description: '自绘浮层排序参考（bindSheet/autoDialog 由组件栈自管）' }) {
            ForEach(ZINDEX_ROWS, (row: ScaleRow) => {
              this.scaleLabel(row.name, row.value)
            }, (row: ScaleRow) => row.name)
          }

          AppSection({ sectionTitle: '行高三比例', description: '中文经验 1.5-1.65；同字号（BODY 16）对排' }) {
            ForEach(LINE_HEIGHT_ROWS, (row: LineHeightRow) => {
              Text(`${row.name} · ${AppLineHeight.for(AppFontSize.BODY, row.ratio)}fp`)
                .fontSize(AppFontSize.BODY)
                .lineHeight(AppLineHeight.for(AppFontSize.BODY, row.ratio))
                .fontColor($r('app.color.app_text_primary'))
                .width('100%')
            }, (row: LineHeightRow) => row.name)
          }

          AppSection({ sectionTitle: '色彩令牌', description: '49 设计令牌 + 20 图表色卡 base/dark 双套 + qj_ 主题三件套（fork 换肤唯一改动点）' }) {
            Text('背景 / 文本 / 填充 / 分割')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_quaternary'))
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              this.colorSwatch('bg_page', $r('app.color.app_bg_page'))
              this.colorSwatch('bg_deep', $r('app.color.app_bg_page_deep'))
              this.colorSwatch('bg_card', $r('app.color.app_bg_card'))
              this.colorSwatch('bg_elev', $r('app.color.app_bg_elevated'))
              this.colorSwatch('bg_inv', $r('app.color.app_bg_inverse'))
              this.colorSwatch('bg_skel', $r('app.color.app_bg_scrim_holder'))
              this.colorSwatch('text_p', $r('app.color.app_text_primary'))
              this.colorSwatch('text_s', $r('app.color.app_text_secondary'))
              this.colorSwatch('text_t', $r('app.color.app_text_tertiary'))
              this.colorSwatch('text_q', $r('app.color.app_text_quaternary'))
              this.colorSwatch('on_brand', $r('app.color.app_text_on_brand'))
              this.colorSwatch('fill_sub', $r('app.color.app_fill_subtle'))
              this.colorSwatch('fill_mid', $r('app.color.app_fill_medium'))
              this.colorSwatch('divider', $r('app.color.app_divider'))
              this.colorSwatch('divider+', $r('app.color.app_divider_strong'))
              this.colorSwatch('skeleton', $r('app.color.app_skeleton'))
            }
            .width('100%')
            Text('反馈语义 × 容器 × 前景 / 交互态 / 遮罩 / 链接 / 禁用 / 阴影')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_quaternary'))
              .width('100%')
              .margin({ top: AppSpacing.SM })
            Flex({ wrap: FlexWrap.Wrap }) {
              this.colorSwatch('success', $r('app.color.app_success'))
              this.colorSwatch('success_c', $r('app.color.app_success_container'))
              this.colorSwatch('success_on', $r('app.color.app_success_on_container'))
              this.colorSwatch('warning', $r('app.color.app_warning'))
              this.colorSwatch('warning_c', $r('app.color.app_warning_container'))
              this.colorSwatch('warning_on', $r('app.color.app_warning_on_container'))
              this.colorSwatch('danger', $r('app.color.app_danger'))
              this.colorSwatch('danger_c', $r('app.color.app_danger_container'))
              this.colorSwatch('danger_on', $r('app.color.app_danger_on_container'))
              this.colorSwatch('info', $r('app.color.app_info'))
              this.colorSwatch('info_c', $r('app.color.app_info_container'))
              this.colorSwatch('info_on', $r('app.color.app_info_on_container'))
              this.colorSwatch('acc_pur', $r('app.color.app_accent_purple'))
              this.colorSwatch('acc_teal', $r('app.color.app_accent_teal'))
              this.colorSwatch('acc_pink', $r('app.color.app_accent_pink'))
              this.colorSwatch('hover', $r('app.color.app_state_hover'))
              this.colorSwatch('pressed', $r('app.color.app_state_pressed'))
              this.colorSwatch('focus', $r('app.color.app_state_focus'))
              this.colorSwatch('dragged', $r('app.color.app_state_dragged'))
              this.colorSwatch('scrim', $r('app.color.app_scrim'))
              this.colorSwatch('shadow', $r('app.color.app_shadow'))
              this.colorSwatch('link', $r('app.color.app_link'))
              this.colorSwatch('dis_bg', $r('app.color.app_button_disabled_bg'))
              this.colorSwatch('dis_fg', $r('app.color.app_button_disabled_fg'))
            }
            .width('100%')
            Text('灰阶 ramp（图表 / 插画 building block）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_quaternary'))
              .width('100%')
              .margin({ top: AppSpacing.SM })
            Flex({ wrap: FlexWrap.Wrap }) {
              this.colorSwatch('gray_1', $r('app.color.app_gray_1'))
              this.colorSwatch('gray_2', $r('app.color.app_gray_2'))
              this.colorSwatch('gray_3', $r('app.color.app_gray_3'))
              this.colorSwatch('gray_4', $r('app.color.app_gray_4'))
              this.colorSwatch('gray_5', $r('app.color.app_gray_5'))
              this.colorSwatch('gray_6', $r('app.color.app_gray_6'))
            }
            .width('100%')
            Text('图表色卡 chart_c01~c20（v3.23 · 数据可视化分类色板；图表/取色器/标签同源）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_quaternary'))
              .width('100%')
              .margin({ top: AppSpacing.SM })
            Flex({ wrap: FlexWrap.Wrap }) {
              this.colorSwatch('c01', $r('app.color.chart_c01'))
              this.colorSwatch('c02', $r('app.color.chart_c02'))
              this.colorSwatch('c03', $r('app.color.chart_c03'))
              this.colorSwatch('c04', $r('app.color.chart_c04'))
              this.colorSwatch('c05', $r('app.color.chart_c05'))
              this.colorSwatch('c06', $r('app.color.chart_c06'))
              this.colorSwatch('c07', $r('app.color.chart_c07'))
              this.colorSwatch('c08', $r('app.color.chart_c08'))
              this.colorSwatch('c09', $r('app.color.chart_c09'))
              this.colorSwatch('c10', $r('app.color.chart_c10'))
              this.colorSwatch('c11', $r('app.color.chart_c11'))
              this.colorSwatch('c12', $r('app.color.chart_c12'))
              this.colorSwatch('c13', $r('app.color.chart_c13'))
              this.colorSwatch('c14', $r('app.color.chart_c14'))
              this.colorSwatch('c15', $r('app.color.chart_c15'))
              this.colorSwatch('c16', $r('app.color.chart_c16'))
              this.colorSwatch('c17', $r('app.color.chart_c17'))
              this.colorSwatch('c18', $r('app.color.chart_c18'))
              this.colorSwatch('c19', $r('app.color.chart_c19'))
              this.colorSwatch('c20', $r('app.color.chart_c20'))
            }
            .width('100%')
            Text('同值对齐纪律：ChartPalette.forMode(isDark) 常量轨与资源表 chart_c01~c20 逐位同值——改一处须同步另一处（Canvas 不支持 $r，故图表走常量）。')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
              .width('100%')
              .margin({ top: AppSpacing.XS })
            Text('主题三件套（qj_ 前缀，fork 换肤唯一改动点）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_quaternary'))
              .width('100%')
              .margin({ top: AppSpacing.SM })
            Flex({ wrap: FlexWrap.Wrap }) {
              this.colorSwatch('qj_brand', $r('app.color.qj_brand'))
              this.colorSwatch('qj_brand_light', $r('app.color.qj_brand_light'))
              this.colorSwatch('qj_on_brand', $r('app.color.qj_on_brand'))
            }
            .width('100%')
          }

          AppSection({ sectionTitle: 'DesignToken 语义方法实测', description: '响应式语义间距/宽度按当前断点求值（页面实测行）' }) {
            Text(`当前断点 bp=${this.bp()} · pagePadding=${DesignToken.pagePadding(this.bp())}vp · contentMaxWidth=${DesignToken.contentMaxWidth(this.bp())}vp · gridGap=${DesignToken.gridGap(this.bp())}vp`)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_primary'))
              .width('100%')
            Text(`cardPadding=${DesignToken.cardPadding()}vp · cardGap=${DesignToken.cardGap()}vp · listItemSpacing=${DesignToken.listItemSpacing()}vp · sectionSpacing=${DesignToken.sectionSpacing()}vp · screenEdgePadding=${DesignToken.screenEdgePadding(this.bp())}vp`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
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
