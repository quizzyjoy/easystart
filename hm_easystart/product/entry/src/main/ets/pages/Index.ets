import { BreakpointManager, CapabilityManager, RouterManager, WindowAdapter } from '@quizzyjoy/platform';
import { AppRoute } from '@easystart/app-routes';
import { isSettingsRoute, SettingsDestination } from '@easystart/app-settings';
import {
  ChartsDashboardView,
  ComponentGroupView,
  DemoSample,
  DesignTokensView,
  DeviceCapabilityView,
  ExamplesView,
  FeedbackFlowView,
  FormSampleView,
  HoverSplitView,
  LearnChapterView,
  LearnView,
  ListStateView,
  SearchView,
  TemplateAboutView,
  ToolsView,
  galleryGroupTitle,
  learnChapterOrDefault
} from '@easystart/demo-feature';
import {
  HomeDetailView,
  HomeItem,
  HomeTarget
} from '@easystart/home-feature';
import { AppFontSize, AppRadius, AppSize, AppSpacing } from '@quizzyjoy/foundation';
import { TabsBarModel } from '../model/TabsBarModel';
import { HomeCatalogView } from '../view/HomeCatalogView';
import { CardLaunchTarget } from '../model/CardLaunchTarget';
import {
  HdsNavigation,
  HdsNavigationMenuContentOptions,
  HdsNavDestination,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType,
  hdsMaterial
} from '@kit.UIDesignKit';
import { ComponentContent } from '@kit.ArkUI';

/**
 * lg+ Split 分栏右栏空态占位（B01-UI-005）。
 * 仅在 HdsNavigation 处于 Split 且路由栈为空时由组件渲染；Stack 模式不参与布局。
 */
@Builder
function splitPlaceholderBuilder() {
  Column({ space: AppSpacing.MD }) {
    Column() {
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .fontSize(AppFontSize.TITLE_LG)
        .fontColor([$r('app.color.qj_brand')])
    }
    .width(AppSize.TOUCH_COMFORT)
    .height(AppSize.TOUCH_COMFORT)
    .justifyContent(FlexAlign.Center)
    .borderRadius(AppRadius.FULL)
    .backgroundColor($r('app.color.qj_brand_light'))

    Text('暂无内容')
      .fontSize(AppFontSize.BODY)
      .fontColor($r('app.color.app_text_secondary'))
    Text('从左侧选择条目，详情将在此处展示')
      .fontSize(AppFontSize.CAPTION)
      .fontColor($r('app.color.app_text_tertiary'))
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .backgroundColor($r('app.color.app_bg_page'))
}

/**
 * 手机 / 平板 / 2in1 统一入口首页。
 *
 * 入口只做装配：Tab 一律 HdsTabs，导航一律 HdsNavigation + HdsNavDestination，
 * 业务视图全部来自 @easystart/home-feature，本页不含业务逻辑。
 * 断点值来自平台（UIContext 断点枚举），页面不硬编码阈值。
 *
 * 注意：
 * 1. @Entry 组件的 build 必须有唯一容器根节点，HdsNavigation 不被识别为容器，
 *    因此这里用 Column 包一层。
 * 2. 自定义组件带尾随构建闭包时不能再链式调用属性，需要外层容器承载样式。
 */
@Entry
@ComponentV2
struct Index {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local pathStack: NavPathStack = new NavPathStack();
  private tabController: HdsTabsController = new HdsTabsController();
  private tabsBar: BottomTabBarStyle[] = TabsBarModel.getTabBarByPage();
  /** Split 分栏右栏空态占位（aboutToAppear 中构建，getUIContext 就绪后可用） */
  private splitPlaceholder: ComponentContent<Object> | undefined = undefined;

  aboutToAppear(): void {
    RouterManager.getInstance().attach(this.pathStack);
    this.splitPlaceholder = new ComponentContent<Object>(
      this.getUIContext(), wrapBuilder(splitPlaceholderBuilder));
    // 卡片深链：注册消费者（应用已在前台时 onNewWant 不会重触发 onPageShow）
    CardLaunchTarget.setConsumer((): void => {
      this.handleCardLaunch();
    });
  }

  aboutToDisappear(): void {
    CardLaunchTarget.clearConsumer();
    this.splitPlaceholder?.dispose();
    this.splitPlaceholder = undefined;
    RouterManager.getInstance().detach();
  }

  /**
   * 页面进入可见（首帧 build 之后，NavPathStack 与 Tab 控制器均已就绪）：
   * 消费服务卡片寄存的深链目标（v3.27）。
   * 用 onPageShow 而非 aboutToAppear 的原因：aboutToAppear 早于 build，
   * 此时 changeIndex/push 可能作用于尚未绑定的控制器；且应用已在后台时点卡片
   * 不会重建页面，只有 onPageShow 会再次触发。
   */
  onPageShow(): void {
    this.handleCardLaunch();
  }

  /** 卡片深链分发（目标由 Ability 的 onCreate/onNewWant 寄存，取走即清空；v3.30 起支持设置子页直达）。 */
  private handleCardLaunch(): void {
    const target: string = CardLaunchTarget.take();
    if (isSettingsRoute(target)) {
      // v3.32 双层栈：设置子页深链先寄存到 AppStorage，由 SettingsDestination
      // 进入设置后压入**内层**栈（外层只 push 设置主页这一个目的地）
      AppStorage.setOrCreate('settings_target', target);
      RouterManager.getInstance().push(AppRoute.SETTINGS);
    } else if (target === 'gallery') {
      // 卡片深链「打开组件示例」：v3.38 起画廊收口到示例 Tab（L1 首页），落到 Tab0
      this.tabController.changeIndex(0);
    }
  }

  /** build 期取占位节点（aboutToAppear 必先于 build，兜底懒建消除非空断言）。 */
  private getSplitPlaceholder(): ComponentContent<Object> {
    if (!this.splitPlaceholder) {
      this.splitPlaceholder = new ComponentContent<Object>(
        this.getUIContext(), wrapBuilder(splitPlaceholderBuilder));
    }
    return this.splitPlaceholder;
  }

  /** 画廊 hub → 样例子页路由映射（DemoSample 枚举 → AppRoute 常量，唯一出处）。 */
  private openDemoPage(sample: DemoSample): void {
    switch (sample) {
      case DemoSample.TOKENS:
        RouterManager.getInstance().push(AppRoute.DEMO_TOKENS);
        break;
      case DemoSample.FEEDBACK:
        RouterManager.getInstance().push(AppRoute.DEMO_FEEDBACK);
        break;
      case DemoSample.CHARTS:
        RouterManager.getInstance().push(AppRoute.DEMO_CHARTS);
        break;
      case DemoSample.FORM:
        RouterManager.getInstance().push(AppRoute.DEMO_FORM);
        break;
      case DemoSample.LIST:
        RouterManager.getInstance().push(AppRoute.DEMO_LIST);
        break;
      case DemoSample.SEARCH:
        RouterManager.getInstance().push(AppRoute.DEMO_SEARCH);
        break;
      case DemoSample.FOLD_HOVER:
        RouterManager.getInstance().push(AppRoute.DEMO_FOLD_HOVER);
        break;
      default:
        break;
    }
  }

  /** 场景卡 id -> DemoSample -> openDemoPage（v3.37 示例 Tab 用）。 */
  private openSceneById(sceneId: string): void {
    let sample: DemoSample = DemoSample.TOKENS;
    if (sceneId === 'feedback') {
      sample = DemoSample.FEEDBACK;
    } else if (sceneId === 'charts') {
      sample = DemoSample.CHARTS;
    } else if (sceneId === 'form') {
      sample = DemoSample.FORM;
    } else if (sceneId === 'list') {
      sample = DemoSample.LIST;
    } else if (sceneId === 'search') {
      sample = DemoSample.SEARCH;
    } else if (sceneId === 'hover') {
      sample = DemoSample.FOLD_HOVER;
    }
    this.openDemoPage(sample);
  }

  /** 打开设置独立子页（首页 titleBar 齿轮回调）。 */
  private openSettings(): void {
    RouterManager.getInstance().push(AppRoute.SETTINGS);
  }

  /**
   * 模板能力目录分发（v3.26；v3.38 收口为三项）：feature 只上抛 HomeTarget 语义，
   * 路由名映射唯一出处在入口。设置 / 详情走 push（详情传 HomeItem **对象**，
   * pageMap 侧 instanceof 收窄）；设备能力切换到底部「开发工具」Tab（不 push 子页）。
   */
  private openHomeTarget(item: HomeItem): void {
    switch (item.target) {
      case HomeTarget.SETTINGS:
        RouterManager.getInstance().push(AppRoute.SETTINGS);
        break;
      case HomeTarget.DEVICE:
        this.tabController.changeIndex(2);
        break;
      case HomeTarget.DETAIL:
        RouterManager.getInstance().push(AppRoute.HOME_DETAIL, item);
        break;
      default:
        RouterManager.getInstance().push(AppRoute.HOME_DETAIL, item);
        break;
    }
  }

  /**
   * titleBar 菜单槽：设置齿轮，所有 tab 常显（v3.12.1 用户裁定）。
   * 用具名方法返回菜单对象，保持 ArkTS 对象字面量类型推断清晰。
   */
  private titleBarMenu(): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            icon: $r('sys.symbol.gearshape_fill'),
            action: (): void => {
              this.openSettings();
            }
          }
        }
      ]
    };
  }

  @Builder
  pageMap(name: string, param: Object) {
    if (name === AppRoute.HOME_DETAIL) {
      HdsNavDestination() {
        if (param instanceof HomeItem) {
          // 详情页范式（v3.26）：HomeFeature 的 HomeDetailView，数据为 HomeItem 实例
          HomeDetailView({ item: param })
        } else {
          // 兜底：旧调用（传标题字符串）或异常参数——保证不白屏
          Column({ space: AppSpacing.MD }) {
            Text(`详情 · ${param}`)
              .fontSize(AppFontSize.TITLE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.app_text_primary'))
            Text('参数不是 HomeItem（兼容旧调用）；「详情页范式」见首页目录第 8 项。')
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .height('100%')
          .padding(AppSpacing.LG)
        }
      }
      // 详情页官方标题栏：沉浸光感材质 + 内容区自动避让 titlebar（enableComponentSafeArea）
      .titleBar({
        content: {
          title: {
            mainTitle: param instanceof HomeItem ? param.title : '详情',
            subTitle: param instanceof HomeItem ? param.description : `${param}`
          }
        },
        style: {
          scrollEffectOpts: {
            enableScrollEffect: false,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      // 组件自带避让：内容区延伸至系统安全区，titlebar 遮挡与避让由 HdsNavDestination 协调
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEMO_TOKENS) {
      // 样例子页标题栏样板（×6 有意重复：入口装配层样板，勿抽共享 helper 进 feature）
      HdsNavDestination() {
        DesignTokensView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '令牌总览'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEMO_FEEDBACK) {
      HdsNavDestination() {
        FeedbackFlowView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '反馈流'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEMO_CHARTS) {
      HdsNavDestination() {
        ChartsDashboardView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '数据看板'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEMO_FORM) {
      HdsNavDestination() {
        FormSampleView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '表单范式'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEMO_LIST) {
      HdsNavDestination() {
        ListStateView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '列表四态'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEMO_SEARCH) {
      HdsNavDestination() {
        SearchView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '搜索场景'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEMO_FOLD_HOVER) {
      HdsNavDestination() {
        HoverSplitView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '悬停态分屏'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.GALLERY_GROUP) {
      // L2 组件分组页（v3.38）：param = basic/visual/platform/app，标题由分组元数据决定
      HdsNavDestination() {
        ComponentGroupView({ groupId: `${param}` })
      }
      .titleBar({
        content: {
          title: {
            mainTitle: galleryGroupTitle(`${param}`)
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: true
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.LEARN_CHAPTER) {
      // 学习 Tab 章节详情（v3.38）：param = 章节 id，标题取章节标题
      HdsNavDestination() {
        LearnChapterView({ chapterId: `${param}` })
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '学习',
            subTitle: learnChapterOrDefault(`${param}`).title
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: true
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.TEMPLATE_ABOUT) {
      // L3 关于模板（v3.38）：这是什么 / 怎么用 / 如何 fork
      HdsNavDestination() {
        TemplateAboutView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '关于模板'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: true
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.HOME_CATALOG) {
      HdsNavDestination() {
        HomeCatalogView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '模板能力'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: true
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (name === AppRoute.DEVICE_CAPABILITY) {
      // 开发工具·设备能力检测（v3.37）：从工具 Tab 卡片进入
      HdsNavDestination() {
        DeviceCapabilityView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '设备能力检测'
          }
        },
        style: {
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: true
      })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    } else if (isSettingsRoute(name)) {
      // 设置域目的地统一装配（v3.28 收口，TODO-019）：视图 + titleBar + 沉浸避让
      // 全部域内自理（SettingsDestination），入口只做一次收口判断
      SettingsDestination({ routeName: name, routeParam: `${param}` })
    }
  }

  build() {
    Column() {
      HdsNavigation(this.pathStack) {
        this.tabArea()
      }
      .navDestination(this.pageMap)
      // 官方标题栏（沉浸光感材质）：标题栏按钮 ADAPTIVE 材质随系统算力自适应
      .titleBar({
        content: {
          title: {
            mainTitle: $r('app.string.app_name'),
            subTitle: `device=${CapabilityManager.getDeviceType()} · bp=${this.breakpoint.breakpoint} · grid=${this.breakpoint.gridColumns()}`
          },
          // 设置齿轮：所有 tab 常显（v3.12.1 用户裁定；HdsTitleBar 菜单槽，点击进 SETTINGS 独立子页）
          menu: this.titleBarMenu()
        },
        style: {
          // 滚动渐变模糊生效（官方示例）：列表滚动时 titleBar 呈现 GRADIENT_BLUR
          scrollEffectOpts: {
            enableScrollEffect: true,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        },
        // 组件自带避让属性：内容区自动避让 titlebar（组件安全区启用）
        avoidLayoutSafeArea: true, // ① titlebar 主动避让状态栏
        enableComponentSafeArea: true // ② 内容区自动避让 titlebar
      })
      // 内容延伸系统安全区，状态栏/手势条避让由 HdsNavigation 协调（官方沉浸光感完整姿势）
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
      .mode(this.breakpoint.isWide() ? NavigationMode.Split : NavigationMode.Stack)
      // Split 分栏右栏空态占位（lg+ 平板/阔折叠；Stack 模式不生效，B01-UI-005）
      .splitPlaceholder(this.getSplitPlaceholder())
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
  }

  @Builder
  tabArea() {
    HdsTabs({ controller: this.tabController }) {
      TabContent() {
        ExamplesView({
          onOpenGalleryGroup: (groupId: string): void => {
            RouterManager.getInstance().push(AppRoute.GALLERY_GROUP, groupId);
          },
          onOpenScene: (sceneId: string): void => {
            this.openSceneById(sceneId);
          },
          onOpenCatalog: (): void => {
            RouterManager.getInstance().push(AppRoute.HOME_CATALOG);
          },
          onOpenTokens: (): void => {
            RouterManager.getInstance().push(AppRoute.DEMO_TOKENS);
          },
          onOpenTemplate: (): void => {
            RouterManager.getInstance().push(AppRoute.TEMPLATE_ABOUT);
          }
        })
      }
      .tabBar(this.tabsBar[0])

      TabContent() {
        LearnView({
          onOpenChapter: (chapterId: string): void => {
            RouterManager.getInstance().push(AppRoute.LEARN_CHAPTER, chapterId);
          }
        })
      }
      .tabBar(this.tabsBar[1])

      TabContent() {
        ToolsView({
          onOpenDeviceCapability: (): void => {
            RouterManager.getInstance().push(AppRoute.DEVICE_CAPABILITY);
          }
        })
      }
      .tabBar(this.tabsBar[2])
    }
    .layoutWeight(1)
    .barPosition(this.breakpoint.isWide() ? BarPosition.Start : BarPosition.End)
    // 沉浸光感完整姿势（官方总览指南）：barOverlap 内容延伸至 bar 之下 + 悬浮态 barFloatingStyle
    .barOverlap(true)
    .barFloatingStyle({
      // 智感握姿（官方 SmartReach 示例）：页签栏自动跟随交互手切换左右位置，零代码无需权限
      adaptToHandedness: true,
      // 官方示例：bar 底边距 = 小白条避让高度（无小白条设备回落 padding_level8）
      barBottomMargin: this.windowAdapter.bottomAvoidVp > 0 ? this.windowAdapter.bottomAvoidVp :
        $r('sys.float.padding_level8'),
      // 沉浸光感：tab bar 用 IMMERSIVE 专用材质（官方 AdaptiveTab 示例），等级随算力自适应
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      }
    })
  }
}
