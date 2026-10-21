import { ComponentContent } from '@kit.ArkUI';
import { hdsMaterial, HdsNavDestination, HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { AppEnvManager, AppEnvSnapshot, BreakpointManager, BreakpointType } from '@quizzyjoy/platform';
import { AppDialog, DialogSemantic } from '@easystart/app-component';
import { SettingsRoute } from '../model/SettingsRoute';
import { AppShare } from '../util/AppShare';
import { SettingsView } from './SettingsView';
import { AppearanceView } from './AppearanceView';
import { GeneralView } from './GeneralView';
import { AnnouncementView } from './AnnouncementView';
import { VersionLogView } from './VersionLogView';
import { HelpFeedbackView } from './HelpFeedbackView';
import { DeveloperView } from './DeveloperView';
import { AboutView } from './about/AboutView';
import { PolicyView } from './about/PolicyView';
import { LicenseView } from './about/LicenseView';
import { AppsView } from './about/AppsView';

/** 宽屏分栏右栏空态占位（未选中任何设置项时）。 */
@Builder
function settingsSplitPlaceholder() {
  Column() {
    SymbolGlyph($r('sys.symbol.gearshape'))
      .fontSize(48)
      .fontColor([$r('app.color.app_text_tertiary')])
    Text($r('app.string.settings_select_placeholder'))
      .fontSize(15)
      .fontColor($r('app.color.app_text_tertiary'))
      .margin({ top: 16 })
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .backgroundColor($r('app.color.app_bg_page'))
}

/**
 * 设置域目的地统一装配组件（v3.28 收口；v3.32 双层栈改造，TODO-023）。
 *
 * 【双层栈结构（外层应用 Stack + 设置域内层 Auto）】
 * - 外层：入口 `HdsNavigation` 保持 `NavigationMode.Stack`，设置作为它的目的地之一；
 * - 内层：本组件内嵌 `HdsNavigation(settingStack)`，`NavigationMode.Auto`——
 *   窄屏（≤600vp）Stack 单栏、宽屏 Split「左设置列表 + 右内容页」，按宽度自动切换；
 * - TV 例外：`deviceType === 'tv'` 时强制 `NavigationMode.Stack`（10-foot UI 不做左右分栏）。
 *
 * 【双层栈的三个关键接线（参考 EasyMath 实战解，2026-10-18 调研）】
 * 1. **返回归属**：`handleBack()` 先退内层、内层空才退外层；外层 `HdsNavDestination`
 *    的 `onBackPressed` 拦截自行处理，避免系统默认行为与外层 Stack 抢事件；
 * 2. **外层栈获取**：`onReady(ctx)` 从 `NavDestinationContext.pathStack` 取外层栈；
 * 3. **内层栈下发**：以 `@Param settingsStack` 显式传给 SettingsView 及子组件
 *    （V2 不用 EasyMath 的 V1 `@Provide/@Consume`，保持单向显式依赖）。
 *
 * 【标题层级】外层 `hideTitleBar(true)`；内层 HdsNavigation 的 titleBar 只承载「设置」根页
 * 与返回键；每个内层目的地由 `HdsNavDestination` 自带 titleBar（`titleOf(name)`），
 * 避免改造前"子页标题依赖外层 titleBar"的耦合。
 *
 * 【深链】进入设置时若携带子页目标（`AppStorage('settings_target')` 写入，或旧调用直接以
 * 外层子页路由进入），转为内层栈的初始 push。
 *
 * 【纪律】路由名/参数由入口经 isSettingsRoute 校验后传入；本组件不感知 AppRoutes（域包互禁）；
 * 标题走域 `$r`；未知路由渲染兜底空内容 + 默认标题。
 */
@ComponentV2
export struct SettingsDestination {
  /** 路由名（与 AppRoute.* 同值，经 isSettingsRoute 校验后进入）。 */
  @Param routeName: string = SettingsRoute.SETTINGS;
  /** 路由参数（POLICY 的 kind：'privacy' | 'terms' | 'sdk'）。 */
  @Param routeParam: string = '';
  /** 设置域内层导航栈（域内子页跳转一律走它，不再压外层栈）。 */
  @Local settingStack: NavPathStack = new NavPathStack();
  /** 断点（决定内层是否分栏与左栏宽度）。 */
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  /** 环境快照（TV 判断）。 */
  @Local env: AppEnvSnapshot = AppEnvManager.get();

  /** 外层应用栈（onReady 时从 NavDestinationContext 取得）。 */
  private outerStack: NavPathStack = new NavPathStack();
  private placeholder: ComponentContent<Object> | undefined = undefined;

  aboutToAppear(): void {
    this.placeholder = new ComponentContent<Object>(this.getUIContext(), wrapBuilder(settingsSplitPlaceholder));
    this.pushInitialTarget();
  }

  /** build 期取占位节点（aboutToAppear 必先于 build，兜底懒建消除非空断言）。 */
  private getSplitPlaceholder(): ComponentContent<Object> {
    if (this.placeholder === undefined) {
      this.placeholder = new ComponentContent<Object>(this.getUIContext(), wrapBuilder(settingsSplitPlaceholder));
    }
    return this.placeholder;
  }

  /** 深链 / 旧路由兼容：把目标子页压入内层栈。 */
  private pushInitialTarget(): void {
    let initial: string = '';
    let initialParam: string = this.routeParam;
    const stored: string | undefined = AppStorage.get<string>('settings_target');
    if (stored !== undefined && stored.length > 0) {
      initial = stored;
      AppStorage.setOrCreate('settings_target', '');
    } else if (this.routeName !== SettingsRoute.SETTINGS) {
      initial = this.routeName;
    }
    if (initial.length === 0) {
      return;
    }
    if (initialParam.length > 0) {
      this.settingStack.pushPath({ name: initial, param: initialParam });
    } else {
      this.settingStack.pushPath({ name: initial });
    }
  }

  /** 是否 TV（强制单栏）。 */
  private isTv(): boolean {
    return this.env.deviceType === 'tv';
  }

  /** 左栏宽度：md 50%，lg/xl 36%（参考官方 NavigationSettings 的 navBarWidth 断点策略）。 */
  private navBarWidthValue(): string {
    if (this.breakpoint.breakpoint === BreakpointType.XL || this.breakpoint.breakpoint === BreakpointType.LG) {
      return '36%';
    }
    if (this.breakpoint.breakpoint === BreakpointType.MD) {
      return '50%';
    }
    return '100%';
  }

  /** 双层栈返回：先退内层，内层空才退外层。 */
  private handleBack(): void {
    if (this.settingStack.size() > 0) {
      this.settingStack.pop();
    } else if (this.outerStack.size() > 0) {
      this.outerStack.pop();
    }
  }

  /**
   * 开发者页 titleBar 信息按钮回调：说明 fork 时替换真实开发者信息的位置。
   *
   * HdsNavDestination.titleBar 的 menu 项类型是 HdsNavigationMenuItemOptions
   * （= HdsNavigationBadgeIconOptions），点击回调要放在 content 里
   * （HdsNavigationIconOptions.action），而不是放在 menu 项外层。
   */
  private showForkTip(): void {
    const uiCtx: UIContext = this.getUIContext();
    const host = uiCtx.getHostContext();
    let title: string = '开发者信息说明';
    let body: string = '';
    if (host !== undefined) {
      try {
        title = host.resourceManager.getStringSync($r('app.string.settings_developer_fork_tip_title'));
        body = host.resourceManager.getStringSync($r('app.string.settings_developer_fork_tip_body'));
      } catch (err) {
        body = '';
      }
    }
    AppDialog.open(uiCtx, DialogSemantic.CONFIRM, title, body, (): void => {
    });
  }

  /** 按路由名给出子页标题（策略文本子页按 param 区分三态）。 */
  private titleOf(name: string, param: string): ResourceStr {
    if (name === SettingsRoute.APPEARANCE) {
      return $r('app.string.settings_appearance');
    }
    if (name === SettingsRoute.GENERAL) {
      return $r('app.string.settings_general_title');
    }
    if (name === SettingsRoute.ABOUT) {
      return $r('app.string.settings_about');
    }
    if (name === SettingsRoute.POLICY) {
      if (param === 'terms') {
        return $r('app.string.settings_terms');
      }
      if (param === 'sdk') {
        return $r('app.string.settings_sdk_list');
      }
      return $r('app.string.settings_privacy');
    }
    if (name === SettingsRoute.LICENSE) {
      return $r('app.string.settings_license');
    }
    if (name === SettingsRoute.ANNOUNCEMENT) {
      return $r('app.string.settings_announcement');
    }
    if (name === SettingsRoute.HELP_FEEDBACK) {
      return $r('app.string.settings_help_feedback');
    }
    if (name === SettingsRoute.VERSION_LOG) {
      return $r('app.string.settings_version_log');
    }
    if (name === SettingsRoute.DEVELOPER) {
      return $r('app.string.settings_developer');
    }
    if (name === SettingsRoute.SDK_LIST) {
      return $r('app.string.settings_sdk_list');
    }
    if (name === SettingsRoute.APPS) {
      return $r('app.string.settings_app_matrix');
    }
    return $r('app.string.settings_title');
  }

  /** 按路由名渲染设置视图（内层根内容与内层目的地共用）。 */
  @Builder
  renderSettingsPage(name: string, param: string) {
    if (name === SettingsRoute.SETTINGS) {
      SettingsView({ settingsStack: this.settingStack })
    } else if (name === SettingsRoute.APPEARANCE) {
      AppearanceView()
    } else if (name === SettingsRoute.GENERAL) {
      GeneralView()
    } else if (name === SettingsRoute.ABOUT) {
      AboutView()
    } else if (name === SettingsRoute.POLICY) {
      PolicyView({ kind: param })
    } else if (name === SettingsRoute.LICENSE) {
      LicenseView()
    } else if (name === SettingsRoute.ANNOUNCEMENT) {
      AnnouncementView()
    } else if (name === SettingsRoute.VERSION_LOG) {
      VersionLogView()
    } else if (name === SettingsRoute.HELP_FEEDBACK) {
      HelpFeedbackView()
    } else if (name === SettingsRoute.DEVELOPER) {
      DeveloperView()
    } else if (name === SettingsRoute.SDK_LIST) {
      // SDK 清单直达别名（深链用）：与关于组 SDK 行同落政策文本子页
      PolicyView({ kind: 'sdk' })
    } else if (name === SettingsRoute.APPS) {
      AppsView({
        onOpenSelf: (): void => {
          this.settingStack.pushPath({ name: SettingsRoute.ABOUT });
        }
      })
    }
  }

  /** 内层导航的目的地映射（设置域 12 子页；每个目的地自带 titleBar 与返回）。 */
  @Builder
  innerPageMap(name: string, param: Object) {
    HdsNavDestination() {
      this.renderSettingsPage(name, `${param}`)
    }
    .titleBar({
      content: {
        title: {
          mainTitle: this.titleOf(name, `${param}`)
        },
        // 开发者页专用：titleBar 右侧「信息」按钮（点击弹出 fork 替换说明）。
        // 点击回调必须放在 content.action（HdsNavigationIconOptions.action）。
        menu: name === SettingsRoute.DEVELOPER ? {
          value: [{
            content: {
              icon: $r('sys.symbol.info_circle'),
              label: 'forkTip',
              action: (): void => {
                this.showForkTip();
              }
            }
          }],
          maxCount: 1
        } : undefined
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
  }

  build() {
    HdsNavDestination() {
      HdsNavigation(this.settingStack) {
        // 根内容 = 设置主页：Split 时即左栏，Stack 时即整页
        SettingsView({ settingsStack: this.settingStack })
      }
      // TV 强制单栏；其余设备按宽度自动分栏（≤600vp Stack / >600vp Split）
      .mode(this.isTv() ? NavigationMode.Stack : NavigationMode.Auto)
      .hideToolBar(true)
      .titleMode(HdsNavigationTitleMode.MINI)
      .hideBackButton(false)
      .navDestination(this.innerPageMap)
      .splitPlaceholder(this.getSplitPlaceholder())
      .navBarWidth(this.navBarWidthValue())
      .backgroundColor($r('app.color.app_bg_page'))
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
      .titleBar({
        content: {
          title: {
            mainTitle: $r('app.string.settings_title')
          },
          backIcon: {
            icon: $r('sys.symbol.chevron_left'),
            action: () => {
              this.handleBack();
            }
          },
          // 分享入口（v3.39 用户裁定）：从设置行上移到设置根页 titleBar，所有设置子页常显。
          // 点击回调必须放在 content.action（HdsNavigationIconOptions.action）。
          menu: {
            value: [{
              content: {
                icon: $r('sys.symbol.share'),
                label: 'share',
                action: (): void => {
                  AppShare.share(this.getUIContext());
                }
              }
            }],
            maxCount: 1
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
    }
    // 外层不显示 titleBar（标题由内层 HdsNavigation 承载，避免双层标题）
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.handleBack();
      return true;
    })
    .onReady((context: NavDestinationContext) => {
      // 从上下文取外层应用栈（双层栈返回时使用）
      this.outerStack = context.pathStack;
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
  }
}
