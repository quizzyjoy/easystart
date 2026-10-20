import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, AppStroke, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { GALLERY_GROUPS, GalleryGroupEntry } from '../model/GalleryGroup';

/** 大卡内的一个子入口行（只承载文案与去向 id）。 */
class ExampleRow {
  readonly id: string;
  readonly title: string;
  readonly desc: string;

  constructor(id: string, title: string, desc: string) {
    this.id = id;
    this.title = title;
    this.desc = desc;
  }
}

/**
 * L1 首页的一个能力域大卡。
 *
 * target 语义（入口装配层分发，本视图不感知路由）：
 * - `gallery` / `scene`：卡内多行，行 id 上抛给对应回调；
 * - 其余：整卡可点，单一路向（模板能力目录 / 令牌总览 / 关于模板）。
 */
class ExampleSection {
  readonly id: string;
  readonly title: string;
  readonly desc: string;
  readonly symbol: Resource;
  readonly tint: Resource;
  readonly target: string;
  readonly rows: ExampleRow[];

  constructor(id: string, title: string, desc: string, symbol: Resource, tint: Resource, target: string,
    rows: ExampleRow[]) {
    this.id = id;
    this.title = title;
    this.desc = desc;
    this.symbol = symbol;
    this.tint = tint;
    this.target = target;
    this.rows = rows;
  }
}

/** 组件示例四行（元数据唯一出处在 model/GalleryGroup）。 */
const GALLERY_ROWS: ExampleRow[] = GALLERY_GROUPS.map((group: GalleryGroupEntry): ExampleRow =>
  new ExampleRow(group.id, group.title, group.desc));

/**
 * 场景示例六行（v3.38 去重：令牌总览移入「设计令牌」卡，不再在此重复）。
 * id 与入口 openSceneById 的 switch 一一对应。
 */
const SCENE_ROWS: ExampleRow[] = [
  new ExampleRow('feedback', '反馈流', '提交失败重试链路 / 危险确认 / 筛选 Sheet 多选回写'),
  new ExampleRow('charts', '数据看板', '四图表断点栅格 + 深浅色联动重绘 + 选中详情联动'),
  new ExampleRow('form', '表单范式', 'AppFormField 受控域 + 逐域校验红线 + 取色联动'),
  new ExampleRow('list', '列表四态', 'StateContainer 四态切换 + RefreshList 刷新与分页'),
  new ExampleRow('search', '搜索场景', 'CommonSearchBar 防抖受控 + 热词 / 结果 / 空态'),
  new ExampleRow('hover', '悬停态分屏', '折叠屏半折叠（帐篷态）真实折痕分屏示例')
];

/**
 * L1 首页五个能力域（顺序即首页顺序）。
 *
 * chip 底色一律用饱和色 + on_brand 白色图标：浅色模式下 qj_brand_light 配白图标
 * 对比度不足（v3.38 真机走查），故按域取不同饱和色区分，深浅色都不失可读性。
 */
const EXAMPLE_SECTIONS: ExampleSection[] = [
  new ExampleSection('gallery', '组件示例', '单组件一页式对照：按钮 / 图表 / 控件 / 容器 / 平台能力 / 动效',
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand'), 'gallery', GALLERY_ROWS),
  new ExampleSection('scene', '场景示例', '可整体复制的页面范式：反馈 / 看板 / 表单 / 列表 / 搜索 / 分屏',
    $r('sys.symbol.doc_text_badge_clock'), $r('app.color.app_accent_purple'), 'scene', SCENE_ROWS),
  new ExampleSection('capability', '模板能力', '设置中心 / 详情页范式 / 账号登录页 / 设备能力：模板已装好的四块基础设施',
    $r('sys.symbol.gearshape_fill'), $r('app.color.app_accent_teal'), 'catalog', []),
  new ExampleSection('tokens', '设计令牌', '字阶 / 圆角 / 间距 / 描边 / 阴影 / 触摸目标 / 色彩全量对照',
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_pink'), 'tokens', []),
  new ExampleSection('about', '关于模板', '这是什么 / 怎么用 / 如何 fork：上手路径与目录约定',
    $r('sys.symbol.info_circle'), $r('app.color.qj_brand'), 'template', [])
];

/**
 * 示例 Tab · L1 首页（v3.38 三级架构）。
 *
 * 页面职责只有一个：**展示这个模板**。五个能力域大卡，卡内子入口直达 L2；
 * 组件示例 → 四个分组页，场景示例 → 六个场景页，模板能力 → 能力目录，
 * 设计令牌 / 关于模板 → L3 单页。原「组件索引卡 + 场景卡 + 目录卡」三块重复入口已收口到此。
 */
@ComponentV2
export struct ExamplesView {
  /** 组件示例分组（basic / visual / platform / app）。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();

  @Param onOpenGalleryGroup: (groupId: string) => void = (_groupId: string): void => {
  };
  /** 场景示例（feedback / charts / form / list / search / hover）。 */
  @Param onOpenScene: (sceneId: string) => void = (_sceneId: string): void => {
  };
  /** 模板能力目录（设置中心 / 详情页范式 / 设备能力）。 */
  @Param onOpenCatalog: () => void = (): void => {
  };
  /** 设计令牌总览。 */
  @Param onOpenTokens: () => void = (): void => {
  };
  /** 关于模板（这是什么 / 怎么用 / 如何 fork）。 */
  @Param onOpenTemplate: () => void = (): void => {
  };
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private openSection(section: ExampleSection): void {
    if (section.target === 'catalog') {
      this.onOpenCatalog();
    } else if (section.target === 'tokens') {
      this.onOpenTokens();
    } else if (section.target === 'template') {
      this.onOpenTemplate();
    }
  }

  private openRow(section: ExampleSection, row: ExampleRow): void {
    if (section.target === 'gallery') {
      this.onOpenGalleryGroup(row.id);
    } else if (section.target === 'scene') {
      this.onOpenScene(row.id);
    }
  }

  /** 大卡头部：图标 chip + 标题 + 一句话说明。 */
  @Builder
  sectionHead(section: ExampleSection) {
    Row({ space: AppSpacing.SM }) {
      Column() {
        SymbolGlyph(section.symbol)
          .fontSize(AppSize.ICON_LG)
          .fontColor([$r('app.color.app_text_on_brand')])
      }
      .width(AppSize.ICON_CHIP)
      .height(AppSize.ICON_CHIP)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(this.chipTint(section))
      .justifyContent(FlexAlign.Center)

      Column({ space: AppSpacing.XXS }) {
        Text(section.title)
          .fontSize(AppFontSize.TITLE_SM)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(section.desc)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /** 大卡内的一行子入口（标题 + 说明 + 箭头）。 */
  @Builder
  rowItem(section: ExampleSection, row: ExampleRow) {
    Row({ space: AppSpacing.SM }) {
      Column({ space: AppSpacing.XXS }) {
        Text(row.title)
          .fontSize(AppFontSize.BODY_SM)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(row.desc)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(AppFontSize.TITLE_SM)
        .fontColor([$r('app.color.app_text_tertiary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
    .onClick((): void => {
      this.openRow(section, row);
    })
  }

  /** 多行大卡（组件示例 / 场景示例）。 */
  @Builder
  sectionWithRows(section: ExampleSection) {
    Column({ space: AppSpacing.XS }) {
      this.sectionHead(section)
      Column() {
        ForEach(section.rows, (row: ExampleRow, index: number) => {
          if (index > 0) {
            Divider()
              .strokeWidth(AppStroke.THIN)
              .color($r('app.color.app_divider'))
          }
          this.rowItem(section, row)
        }, (row: ExampleRow): string => `${section.id}_${row.id}`)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(AppSpacing.MD)
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
  }

  /** 单路大卡（模板能力 / 设计令牌 / 关于模板）：整卡可点。 */
  @Builder
  sectionLink(section: ExampleSection) {
    Row({ space: AppSpacing.SM }) {
      Column() {
        SymbolGlyph(section.symbol)
          .fontSize(AppSize.ICON_LG)
          .fontColor([$r('app.color.app_text_on_brand')])
      }
      .width(AppSize.ICON_CHIP)
      .height(AppSize.ICON_CHIP)
      .borderRadius(AppRadius.FULL)
      .backgroundColor(this.chipTint(section))
      .justifyContent(FlexAlign.Center)

      Column({ space: AppSpacing.XXS }) {
        Text(section.title)
          .fontSize(AppFontSize.TITLE_SM)
          .fontWeight(AppFontWeight.MEDIUM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(section.desc)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
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
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.openSection(section);
    })
  }

  @Builder
  section(section: ExampleSection) {
    if (section.rows.length > 0) {
      this.sectionWithRows(section)
    } else {
      this.sectionLink(section)
    }
  }

  /**
   * chip 底色：**品牌域（组件示例 / 关于模板）跟随主题包**，其余域保留各自强调色以区分。
   *
   * 数据表是 const（不能读 this），所以取色放在渲染期按 id 判定：这是 v3.44「静态色接入
   * 主题系统」的落地点 —— 页面装饰色走主题，语义/演示色保持固定。
   */
  private chipTint(section: ExampleSection): ResourceColor {
    return (section.id === 'gallery' || section.id === 'about')
      ? this.theme.brandColor() : section.tint;
  }
  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Text('一次开发、四端部署的鸿蒙模板骨架：点开任一卡片进入下一级。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')

        ForEach(EXAMPLE_SECTIONS, (section: ExampleSection) => {
          this.section(section)
        }, (section: ExampleSection): string => section.id)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        // Tab 页统一避让：悬浮页签栏 + 手势条（barOverlap 下内容会延伸到底部 bar 之后）
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
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
