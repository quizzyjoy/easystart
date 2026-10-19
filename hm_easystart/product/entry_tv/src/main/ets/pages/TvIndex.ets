import { BreakpointManager, CapabilityManager, RouterManager, WindowAdapter } from '@quizzyjoy/platform';
import { AppRoute } from '@easystart/app-routes';
import { isSettingsRoute, SettingsDestination } from '@easystart/app-settings';
import { ComponentGalleryView, DeviceCapabilityView } from '@easystart/demo-feature';
import { AppFontSize, AppFontWeight, AppSize, AppSpacing } from '@quizzyjoy/foundation';
import { HdsNavigation } from '@kit.UIDesignKit';

/**
 * TV 独立入口首页。
 *
 * 【HDS 例外 E1 · 必读】
 * 本页 Tab 使用原生 Tabs 而非 HdsTabs。
 * 依据：SDK 设备支持矩阵（sdk/default/hms/ets/api/device-define/api-version/UIDesignKit.json）
 * 中 HdsTabsAttribute / HdsTabsController / HdsTabsOptions 的 deviceTypes 均为
 * phone / tablet / 2in1 / car，**不含 tv**；HdsNavigation 则包含 tv（起始 5.1.1(19)）。
 * 因此 TV 形态回退原生 Tabs，其余形态（phone/tablet/2in1）统一使用 HdsTabs。
 *
 * v3.12 起：HdsNavigation（官方支持 tv）作为本页导航宿主，承载设置独立子页；
 * 标题区仍用自绘 header（TV 10-foot UI 大字号范式），设置入口为 header 右侧齿轮
 * （圆形按钮，遥控器方向键可自然聚焦）。画廊子页 hub 仍隐藏（demo 子页不向 TV 开放）。
 *
 * TV 形态其余要点：
 * - 10-foot UI：大字号、大间距、宽焦点区；
 * - 遥控器交互：依赖系统焦点与方向键，不使用触摸手势。
 *
 * 注意：自定义组件带尾随构建闭包时（Comp() { ... }）不能再链式调属性，
 * 需要外层容器承载样式，这是 ArkTS 的语法约束。
 */
@Entry
@ComponentV2
struct TvIndex {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local currentIndex: number = 0;
  @Local pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    RouterManager.getInstance().attach(this.pathStack);
  }

  aboutToDisappear(): void {
    RouterManager.getInstance().detach();
  }

  build() {
    Column() {
      HdsNavigation(this.pathStack) {
        Column() {
          this.header()
          this.tabArea()
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.app_bg_page'))
      }
      .navDestination(this.pageMap)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .padding({
      top: this.windowAdapter.topAvoidVp,
      bottom: this.windowAdapter.bottomAvoidVp
    })
  }

  @Builder
  header() {
    Row({ space: AppSpacing.MD }) {
      Column({ space: AppSpacing.XS }) {
        Text($r('app.string.app_name'))
          .fontSize(AppFontSize.DISPLAY)
          .fontWeight(AppFontWeight.LIGHT)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
        Text(`TV · device=${CapabilityManager.getDeviceType()} · bp=${this.breakpoint.breakpoint} · tabs=native(HDS exception E1)`)
          .fontSize(AppFontSize.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 设置入口：圆形图标按钮（TV 焦点可自然到达），进 SETTINGS 独立子页
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.gearshape_fill'))
          .fontSize(AppFontSize.TITLE_LG)
          .fontColor([$r('sys.color.icon_primary')])
      }
      .width(AppSize.TOUCH_COMFORT)
      .height(AppSize.TOUCH_COMFORT)
      .backgroundColor($r('app.color.app_bg_card'))
      .onClick((): void => {
        RouterManager.getInstance().push(AppRoute.SETTINGS);
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: AppSpacing.XXXL, right: AppSpacing.XXXL, top: AppSpacing.XL, bottom: AppSpacing.SM })
  }

  @Builder
  pageMap(name: string, param: Object) {
    // 设置域目的地统一装配（v3.28 收口，TODO-019）：视图 + titleBar + 沉浸避让
    // 全部域内自理（SettingsDestination）；TV 仅开放设置域路由
    if (isSettingsRoute(name)) {
      SettingsDestination({ routeName: name, routeParam: `${param}` })
    }
  }

  @Builder
  tabArea() {
    Tabs({ barPosition: BarPosition.Start, index: this.currentIndex }) {
      TabContent() {
        // TV 无 Navigation 宿主，直接把四组按序全渲染（groupId 省略 = 全量长页）；
        // 样例子页（场景范式）不向 TV 开放，入口事件已随 v3.38 移除。
        ComponentGalleryView()
      }
      .tabBar($r('app.string.tab_gallery'))

      TabContent() {
        DeviceCapabilityView()
      }
      .tabBar($r('app.string.tab_device'))
    }
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .layoutWeight(1)
    .width('100%')
    .barMode(BarMode.Fixed)
  }
}
