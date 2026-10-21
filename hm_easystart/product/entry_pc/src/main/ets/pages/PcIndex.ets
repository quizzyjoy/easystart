import { BreakpointManager, BreakpointType, CapabilityManager, HoverStore, RouterManager, WindowAdapter } from '@quizzyjoy/platform';
import { AppRoute } from '@easystart/app-routes';
import { isSettingsRoute, SettingsDestination } from '@easystart/app-settings';
import {
  AccountSampleView,
  ChartsDashboardView,
  CodecToolView,
  HashToolView,
  IdToolView,
  JsonToolView,
  RegexToolView,
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
} from '@easystart/demo-feature';
import {
  HomeDetailView,
  HomeItem,
  HomeListView,
  HomeTarget
} from '@easystart/home-feature';
import { AppFontSize, AppRadius, AppSize, AppSpacing } from '@quizzyjoy/foundation';
import { UiThemeManager } from '@quizzyjoy/vitalui';
import { TabsBarModel } from '../model/TabsBarModel';
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
 * 2in1（PC）专用入口首页（v2.3.2）。
 *
 * 结构与 pages/Index 同源（Tab 一律 HdsTabs、导航一律 HdsNavigation），
 * 差异定位：PC 自由窗口可任意调整大小，断点逻辑必须保留（窗口拉窄即回 sm/md 布局）；
 * PC 专属交互（键鼠 hover、右键菜单、快捷键）在业务视图内按 CapabilityManager 分支扩展。
 */
@Entry
@ComponentV2
struct PcIndex {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 悬停态全局信号（鼠标是否在页面内）；元素级高亮走 hoverEffect，见 HomeListView。 */
  @Local hoverStore: HoverStore = HoverStore.getInstance();
  @Local pathStack: NavPathStack = new NavPathStack();
  private tabController: HdsTabsController = new HdsTabsController();
  /** 运行时主题：页签选中色跟随换肤（传 hex，见 TabsBarModel 注释）。 */
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  /** 页签样式（BottomTabBarStyle 不响应状态，主题变化时用新颜色重建）。 */
  @Local tabsBar: BottomTabBarStyle[] = TabsBarModel.getTabBarByPage(UiThemeManager.getInstance().effectiveAccent());
  /** Split 分栏右栏空态占位（aboutToAppear 中构建，getUIContext 就绪后可用） */
  private splitPlaceholder: ComponentContent<Object> | undefined = undefined;

  /**
   * PC 分栏阈值（v3.31 实测裁定）：**仅 xl（≥1440vp）分栏**。
   *
   * bp_2in1 实证：lg（840~1440vp，实测窗口 868vp）下 Split 后左栏仅 320~440vp，
   * HdsTabs 页签被压到内容区上方并与 Swiper 重叠——`uiInput click` 落在内容层，
   * 页签实际不可点（点「首页」反而触发画廊内部视图切换）。同窗口改用 Stack 后
   * 页签落到底部、与手机/平板同构，交互正常。故 PC 只在 xl 具备双栏空间时拆分。
   */
  private isPcSplit(): boolean {
    return this.breakpoint.breakpoint === BreakpointType.XL;
  }

  /** 切主题包 / 改强调色时重建页签样式，让选中态跟上主题色。 */
  @Monitor('theme.presetId', 'theme.accentColor')
  onThemeChanged(): void {
    this.tabsBar = TabsBarModel.getTabBarByPage(this.theme.effectiveAccent());
  }

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
      // v3.38：示例首页即画廊入口（L1），深链落到 Tab0
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

  /** 打开设置独立子页（首页 titleBar 齿轮回调）。 */
  private openSettings(): void {
    RouterManager.getInstance().push(AppRoute.SETTINGS);
  }

  /** 场景卡 id -> DemoSample -> openDemoPage（v3.38 示例首页场景行用）。 */
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

  /**
   * 模板能力目录分发（v3.26；v3.38 收口为三项）：feature 只上抛 HomeTarget 语义，
   * 路由名映射唯一出处在入口。设置 / 详情走 push；设备能力切换到底部「开发工具」Tab。
   */
  /** 开发工具分发（v3.46）：与手机端同一套 id → 路由映射。 */
  private openDevTool(id: string): void {
    switch (id) {
      case 'iconkit':
        RouterManager.getInstance().push(AppRoute.ICON_KIT);
        break;
      case 'transitions':
        RouterManager.getInstance().push(AppRoute.TRANSITIONS);
        break;
      case 'hash':
        RouterManager.getInstance().push(AppRoute.HASH_TOOL);
        break;
      case 'codec':
        RouterManager.getInstance().push(AppRoute.CODEC_TOOL);
        break;
      case 'idtool':
        RouterManager.getInstance().push(AppRoute.ID_TOOL);
        break;
      case 'regex':
        RouterManager.getInstance().push(AppRoute.REGEX_TOOL);
        break;
      case 'jsontool':
        RouterManager.getInstance().push(AppRoute.JSON_TOOL);
        break;
      default:
        RouterManager.getInstance().push(AppRoute.DEVICE_CAPABILITY);
        break;
    }
  }
  private openHomeTarget(item: HomeItem): void {
    switch (item.target) {
      case HomeTarget.SETTINGS:
        RouterManager.getInstance().push(AppRoute.SETTINGS);
        break;
      case HomeTarget.ACCOUNT_SAMPLE:
        RouterManager.getInstance().push(AppRoute.ACCOUNT_SAMPLE);
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
      HdsNavDestination() {
        LearnChapterView({ chapterId: `${param}` })
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '学习',
            subTitle: '学习文档'
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
    } else if (name === AppRoute.ACCOUNT_SAMPLE) {
      // 账号登录页范式（v3.40 从设置域迁出）
      HdsNavDestination() {
        AccountSampleView()
      }
      .titleBar({
        content: {
          title: {
            mainTitle: '账号登录页范式'
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
    } else if (name === AppRoute.HASH_TOOL) {
      HdsNavDestination() {
        HashToolView()
      }
      .titleBar({
        content: { title: { mainTitle: '哈希校验', subTitle: 'cryptoFramework 本地摘要' } },
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
    } else if (name === AppRoute.CODEC_TOOL) {
      HdsNavDestination() {
        CodecToolView()
      }
      .titleBar({
        content: { title: { mainTitle: '编码工作台', subTitle: 'Base64 / URL / HTML 实体 / JSON 转义' } },
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
    } else if (name === AppRoute.ID_TOOL) {
      HdsNavDestination() {
        IdToolView()
      }
      .titleBar({
        content: { title: { mainTitle: 'ID 生成', subTitle: 'UUID v4 / ULID' } },
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
    } else if (name === AppRoute.REGEX_TOOL) {
      HdsNavDestination() {
        RegexToolView()
      }
      .titleBar({
        content: { title: { mainTitle: '正则测试器', subTitle: '命中 / 捕获组 / 替换预览' } },
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
    } else if (name === AppRoute.JSON_TOOL) {
      HdsNavDestination() {
        JsonToolView()
      }
      .titleBar({
        content: { title: { mainTitle: 'JSON 工具台', subTitle: '格式化 / 压缩 / 排序 / 路径' } },
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
        HomeListView({
          onOpenDetail: (item: HomeItem): void => {
            this.openHomeTarget(item);
          }
        })
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
            subTitle: `2in1 入口 · device=${CapabilityManager.getDeviceType()} · bp=${this.breakpoint.breakpoint} · grid=${this.breakpoint.gridColumns()}`
          },
          // 设置齿轮：仅首页 tab 可见（HdsTitleBar 菜单槽，点击进 SETTINGS 独立子页）
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
      // 仅 xl 分栏（见 isPcSplit 注释）：lg 及以下走 Stack，页签落到底部，交互与手机同构
      .mode(this.isPcSplit() ? NavigationMode.Split : NavigationMode.Stack)
      // 分栏宽度约束（xl 分栏时生效）：左栏 ≥320vp、右栏 ≥360vp，避免系统按窗口比例
      // 把左栏压到约 152vp（bp_2in1 lg 实测值），导致内容逐字竖排。
      .navBarWidthRange({ minWidth: 320, maxWidth: 440 })
      .minContentWidth(360)
      // Split 分栏右栏空态占位（PC 恒为 wide，占位在 2in1 上最常驻；B01-UI-005）
      .splitPlaceholder(this.getSplitPlaceholder())
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    // 鼠标悬停全局信号（v3.31）：HoverStore.isHover 从此有真实来源，
    // 供 PC 专属交互（悬浮控制条 / 快捷键提示等）按需消费。
    .onHover((isHover: boolean) => {
      this.hoverStore.reportHover(isHover);
    })
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
          onOpenTool: (id: string): void => {
            this.openDevTool(id);
          }
        })
      }
      .tabBar(this.tabsBar[2])
    }
    .layoutWeight(1)
    .barPosition(this.isPcSplit() ? BarPosition.Start : BarPosition.End)
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
