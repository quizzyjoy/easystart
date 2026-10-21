import { UiThemeManager } from '@quizzyjoy/vitalui';
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, AppStroke, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, WindowAdapter } from '@quizzyjoy/platform';
import { GALLERY_GROUPS, GalleryGroupEntry, VITALUI_GROUPS } from '../model/GalleryGroup';
import {ENGINEERING_NAV_ROWS, SCENE_NAV_ROWS, SectionNavRow, LAYOUT_NAV_ROWS } from '../model/SectionNav';

/** 大卡内的一个子入口行（只承载文案与去向 id）。 */
class ExampleRow {
  readonly id: string;
  /** 标题/描述走三语资源（v3.77）：ResourceStr 让 Text 直接渲染当前语言。 */
  readonly title: ResourceStr;
  readonly desc: ResourceStr;

  constructor(id: string, title: ResourceStr, desc: ResourceStr) {
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
  /** 标题/描述走三语资源（v3.77）：写成 ResourceStr，Text 会按当前语言渲染。 */
  readonly title: ResourceStr;
  readonly desc: ResourceStr;
  readonly symbol: Resource;
  readonly tint: Resource;
  readonly target: string;
  readonly rows: ExampleRow[];

  constructor(id: string, title: ResourceStr, desc: ResourceStr, symbol: Resource, tint: Resource,
    target: string, rows: ExampleRow[]) {
    this.id = id;
    this.title = title;
    this.desc = desc;
    this.symbol = symbol;
    this.tint = tint;
    this.target = target;
    this.rows = rows;
  }
}

/** 组件示例的行（元数据唯一出处在 model/GalleryGroup）：通用组件三行。 */
const GALLERY_ROWS: ExampleRow[] = GALLERY_GROUPS.map((group: GalleryGroupEntry): ExampleRow =>
  new ExampleRow(group.id, group.title, group.desc));

/** VitalUI 组件区四行（v3.65 从「组件示例」分出，独立成一张卡）。 */
const VITALUI_ROWS: ExampleRow[] = VITALUI_GROUPS.map((group: GalleryGroupEntry): ExampleRow =>
  new ExampleRow(group.id, group.title, group.desc));

/** 场景示例六行（数据唯一出处 model/SectionNav，二级导航页共用同一份）。 */
const SCENE_ROWS: ExampleRow[] = SCENE_NAV_ROWS.map((row: SectionNavRow): ExampleRow =>
  new ExampleRow(row.id, row.title, row.desc));

/**
 * L1 首页五个能力域（顺序即首页顺序）。
 *
 * chip 底色一律用饱和色 + on_brand 白色图标：浅色模式下 qj_brand_light 配白图标
 * 对比度不足（v3.38 真机走查），故按域取不同饱和色区分，深浅色都不失可读性。
 */
/** 工程能力四行（权限 / 网络 / 长列表 / 无障碍），供 L1 卡显示行数。 */
const ENGINEERING_ROWS: ExampleRow[] = ENGINEERING_NAV_ROWS.map((row: SectionNavRow): ExampleRow =>
  new ExampleRow(row.id, row.title, row.desc));

/** 布局示例四行，供 L1 卡显示行数。 */
const LAYOUT_ROWS: ExampleRow[] = LAYOUT_NAV_ROWS.map((row: SectionNavRow): ExampleRow =>
  new ExampleRow(row.id, row.title, row.desc));

const EXAMPLE_SECTIONS: ExampleSection[] = [
  new ExampleSection('gallery', $r('app.string.examples_card_gallery_title'),
    $r('app.string.examples_card_gallery_desc'),
    $r('sys.symbol.square_grid_2x2'), $r('app.color.qj_brand'), 'gallery', GALLERY_ROWS),
  new ExampleSection('vitalui', $r('app.string.examples_card_vitalui_title'),
    $r('app.string.examples_card_vitalui_desc'),
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_pink'), 'gallery', VITALUI_ROWS),
  new ExampleSection('scene', $r('app.string.examples_card_scene_title'),
    $r('app.string.examples_card_scene_desc'),
    $r('sys.symbol.doc_text_badge_clock'), $r('app.color.app_accent_purple'), 'scene', SCENE_ROWS),
  new ExampleSection('engineering', $r('app.string.examples_card_engineering_title'),
    $r('app.string.examples_card_engineering_desc'),
    $r('sys.symbol.wrench_and_screwdriver_fill'), $r('app.color.app_accent_teal'), 'engineering',
    ENGINEERING_ROWS),
  new ExampleSection('layout', $r('app.string.examples_card_layout_title'),
    $r('app.string.examples_card_layout_desc'),
    $r('sys.symbol.square_grid_2x2'), $r('app.color.app_accent_pink'), 'layout', LAYOUT_ROWS),
  new ExampleSection('capability', $r('app.string.examples_card_capability_title'),
    $r('app.string.examples_card_capability_desc'),
    $r('sys.symbol.gearshape_fill'), $r('app.color.app_accent_teal'), 'catalog', []),
  new ExampleSection('tokens', $r('app.string.examples_card_tokens_title'),
    $r('app.string.examples_card_tokens_desc'),
    $r('sys.symbol.paintpalette'), $r('app.color.app_accent_pink'), 'tokens', []),
  new ExampleSection('about', $r('app.string.examples_card_about_title'),
    $r('app.string.examples_card_about_desc'),
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
  /** 二级导航（v3.66：组件示例 / VitalUI 组件 / 场景示例 三张卡的子入口页）。 */
  @Param onOpenSectionNav: (sectionId: string) => void = (_sectionId: string): void => {
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
  /** 卡片区容器实际宽度（vp）：由 Flex 的 onAreaChange 回填，驱动两列判定。 */
  @Local containerW: number = 0;
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  /**
   * 卡点击（v3.66：首页只显示入口，不再内嵌行）。
   *
   * 有子入口的卡（组件示例 / VitalUI 组件 / 场景示例）统一进二级导航页；
   * 单页卡（模板能力 / 设计令牌 / 关于模板）直接进各自页面——它们本身就是二级页。
   */
  private openSection(section: ExampleSection): void {
    if (section.rows.length > 0) {
      this.onOpenSectionNav(section.id);
      return;
    }
    if (section.target === 'catalog') {
      this.onOpenCatalog();
    } else if (section.target === 'tokens') {
      this.onOpenTokens();
    } else if (section.target === 'template') {
      this.onOpenTemplate();
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
    .width(this.cardWidth())
    .alignItems(VerticalAlign.Center)
    .padding(DesignToken.cardPadding())
    .margin({ bottom: DesignToken.cardGap() })
    .borderRadius(AppRadius.XL)
    .backgroundColor($r('app.color.app_bg_card'))
    .onClick((): void => {
      this.openSection(section);
    })
  }

  /** 首页六卡统一为入口卡（v3.66）：只显示标题/说明/箭头，点击进二级导航或单页。 */
  @Builder
  section(section: ExampleSection) {
    this.sectionLink(section)
  }

  /**
   * chip 底色：**品牌域（组件示例 / 关于模板）跟随主题包**，其余域保留各自强调色以区分。
   *
   * 数据表是 const（不能读 this），所以取色放在渲染期按 id 判定：这是 v3.44「静态色接入
   * 主题系统」的落地点 —— 页面装饰色走主题，语义/演示色保持固定。
   */
  /**
   * 入口卡宽度：按**容器实际宽度**决定两列还是单列（v3.71）。
   *
   * 原先按 `breakpoint.isWide()`（窗口断点）判定，分栏左栏只有 340–420vp 时仍排两列，
   * 卡片被压到 ~165vp。改为容器宽驱动：单卡最小可读宽 320vp。
   */
  private cardWidth(): string {
    return DesignToken.twoUpWidth(this.containerW > 0 ? this.containerW : this.breakpoint.windowWidthVp, 320);
  }

  private chipTint(section: ExampleSection): ResourceColor {
    return (section.id === 'gallery' || section.id === 'about')
      ? this.theme.brandColor() : section.tint;
  }
  build() {
    Scroll() {
      Column({ space: DesignToken.sectionSpacing() }) {
        Text($r('app.string.examples_intro'))
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
          ForEach(EXAMPLE_SECTIONS, (section: ExampleSection) => {
            this.section(section)
          }, (section: ExampleSection): string => section.id)
        }
        .width('100%')
        .onAreaChange((_old: Area, area: Area): void => {
          this.containerW = Number(area.width);
        })
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
