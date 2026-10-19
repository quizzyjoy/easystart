import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager } from '@quizzyjoy/platform';

/** 示例 Tab 的一张入口卡。 */
class ExampleCard {
  readonly id: string;
  readonly title: string;
  readonly desc: string;
  readonly symbol: Resource;
  readonly tint: Resource;

  constructor(id: string, title: string, desc: string, symbol: Resource, tint: Resource) {
    this.id = id;
    this.title = title;
    this.desc = desc;
    this.symbol = symbol;
    this.tint = tint;
  }
}

const GALLERY_CARDS: ExampleCard[] = [
  new ExampleCard('basic', '入口与基础',
    '样例子页入口 + 按钮 / 标签 / 搜索 / 轻提示 / 对话框 / 骨架屏 / 卡片 / 选择器',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand')),
  new ExampleCard('visual', '数据可视化',
    '四图表（玫瑰 / 饼 / 季度玫瑰 / 雷达）+ 取色器 + Loading 三形态',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand_light')),
  new ExampleCard('platform', '平台能力与令牌',
    '响应式 DSL / 折叠态折痕 / 色彩令牌 / 沉浸避让 / 系统分享 / 照片选择 / 剪贴板',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand')),
  new ExampleCard('app', '应用组件',
    'AppComponent：反馈族 / modifier 族 / 主题化控件工厂 / 容器 / 表单 / 扩展换肤',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand_light'))
];

const SCENE_CARDS: ExampleCard[] = [
  new ExampleCard('tokens', '令牌总览', '字阶 / 圆角 / 间距 / 描边 / 阴影 / 触摸目标 / 色彩全量对照',
    $r('sys.symbol.paintpalette'), $r('app.color.qj_brand')),
  new ExampleCard('feedback', '反馈流', '提交失败重试 / 危险确认 / 筛选 Sheet 多选回写 / 轻提示降级对照',
    $r('sys.symbol.message'), $r('app.color.qj_brand_light')),
  new ExampleCard('charts', '数据看板', '四图表断点栅格 + 深浅色联动重绘 + 20 色卡取色 + 选中详情',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand')),
  new ExampleCard('form', '表单范式', '受控表单域 + 逐域校验红线 + 取色实时联动 + 提交确认闭环',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand_light')),
  new ExampleCard('list', '列表四态', '加载 / 空 / 错误 / 内容四态 + RefreshList 刷新与分页状态机',
    $r('sys.symbol.list_bullet'), $r('app.color.qj_brand')),
  new ExampleCard('search', '搜索场景', '防抖受控输入 + 热词提示 / 结果列表 / 无匹配空态三态流转',
    $r('sys.symbol.magnifyingglass'), $r('app.color.qj_brand_light')),
  new ExampleCard('hover', '悬停态分屏', '折叠屏半折叠（帐篷）真实折痕分屏示例',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand'))
];

/**
 * 示例 Tab（v3.37）：组件示例 / 场景示例 / 能力目录 三个垂直分组。
 *
 * 原「画廊分组索引卡 + 首页能力目录」两块合并为此页；分组用垂直小标题隔开，
 * 卡片栅格按断点 1/2/3 列，内容限宽 contentMaxWidth。
 */
@ComponentV2
export struct ExamplesView {
  @Param onOpenGalleryGroup: (groupId: string) => void = (_groupId: string): void => {
  };
  @Param onOpenScene: (sceneId: string) => void = (_sceneId: string): void => {
  };
  @Param onOpenCatalog: () => void = (): void => {
  };
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private columnsTemplate(): string {
    const bp: string = this.bp();
    if (bp === 'xs' || bp === 'sm') {
      return '1fr';
    }
    if (bp === 'md') {
      return '1fr 1fr';
    }
    return '1fr 1fr 1fr';
  }

  @Builder
  groupHeader(title: string) {
    Text(title)
      .fontSize(AppFontSize.BODY_SM)
      .fontWeight(AppFontWeight.MEDIUM)
      .fontColor($r('app.color.app_text_secondary'))
      .width('100%')
  }

  @Builder
  card(item: ExampleCard) {
    Column({ space: AppSpacing.SM }) {
      Row({ space: AppSpacing.SM }) {
        Column() {
          SymbolGlyph(item.symbol)
            .fontSize(AppSize.ICON_LG)
            .fontColor([$r('app.color.app_text_on_brand')])
        }
        .width(AppSize.ICON_CHIP)
        .height(AppSize.ICON_CHIP)
        .borderRadius(AppRadius.FULL)
        .backgroundColor(item.tint)
        .justifyContent(FlexAlign.Center)

        Text(item.title)
          .fontSize(AppFontSize.BODY)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(item.desc)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.LG)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      if (item.id === 'tokens' || item.id === 'feedback' || item.id === 'charts' || item.id === 'form' ||
        item.id === 'list' || item.id === 'search' || item.id === 'hover') {
        this.onOpenScene(item.id);
      } else {
        this.onOpenGalleryGroup(item.id);
      }
    })
  }

  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Column({ space: AppSpacing.SM }) {
          this.groupHeader('组件示例')
          Grid() {
            ForEach(GALLERY_CARDS, (item: ExampleCard) => {
              GridItem() {
                this.card(item)
              }
            }, (item: ExampleCard): string => item.id)
          }
          .columnsTemplate(this.columnsTemplate())
          .columnsGap(AppSpacing.SM)
          .rowsGap(AppSpacing.SM)
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: AppSpacing.SM }) {
          this.groupHeader('场景示例')
          Grid() {
            ForEach(SCENE_CARDS, (item: ExampleCard) => {
              GridItem() {
                this.card(item)
              }
            }, (item: ExampleCard): string => item.id)
          }
          .columnsTemplate(this.columnsTemplate())
          .columnsGap(AppSpacing.SM)
          .rowsGap(AppSpacing.SM)
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: AppSpacing.SM }) {
          this.groupHeader('能力目录')
          Row({ space: AppSpacing.SM }) {
            Column() {
              SymbolGlyph($r('sys.symbol.list_bullet'))
                .fontSize(AppSize.ICON_LG)
                .fontColor([$r('app.color.app_text_on_brand')])
            }
            .width(AppSize.ICON_CHIP)
            .height(AppSize.ICON_CHIP)
            .borderRadius(AppRadius.FULL)
            .backgroundColor($r('app.color.qj_brand'))
            .justifyContent(FlexAlign.Center)

            Column({ space: AppSpacing.XXS }) {
              Text('模板能力目录')
                .fontSize(AppFontSize.BODY)
                .fontWeight(AppFontWeight.MEDIUM)
                .fontColor($r('app.color.app_text_primary'))
                .width('100%')
              Text('12 项能力入口（列表 → 详情标准范式）')
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_tertiary'))
                .width('100%')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(AppFontSize.TITLE_SM)
              .fontColor([$r('app.color.app_text_tertiary')])
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.LG)
          .backgroundColor($r('app.color.app_bg_card'))
          .onClick((): void => {
            this.onOpenCatalog();
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: AppSpacing.XXXL
      })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
