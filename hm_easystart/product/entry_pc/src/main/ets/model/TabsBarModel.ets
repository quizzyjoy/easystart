import { SymbolGlyphModifier } from '@kit.ArkUI';

/**
 * 底部页签样式模型（参考官方 SmartReach 示例）。
 *
 * 图标 + 文字双行页签（BottomTabBarStyle + SymbolGlyphModifier）。
 * 未选中色走 `sys.color.icon_primary`（随深浅色切换）；
 * 选中色由调用方以 **hex 字符串**注入运行时主题色（`UiThemeManager.effectiveAccent()`）。
 *
 * 为什么必须传 hex 而不能传 `$r(...)`：`BottomTabBarStyle` 在 build 之外构造，
 * 传 Resource 取色会回落到默认色（真机表现为选中页签变黑）；传 `'#RRGGBB'` 正常。
 *
 * 注意：`BottomTabBarStyle` 是普通类，构造后不响应状态变化，
 * 主题一变必须用新颜色重建（入口页用 `@Monitor` 触发）。
 * tab_* 文案定义在 AppScope，全入口共享。
 */
export class TabsBarModel {
  /** 按当前主题色构建页签样式（不做缓存：颜色变化必须重建）。 */
  public static getTabBarByPage(selectedHex: string): BottomTabBarStyle[] {
    const tabBarStyleList: BottomTabBarStyle[] = [];
    BAR_ITEMS.forEach((item: BarItem) => {
      const tabBarStyle = new BottomTabBarStyle({
        normal: new SymbolGlyphModifier(item.normalSymbolResource)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([item.normalColor]),
        selected: new SymbolGlyphModifier(item.selectedSymbolResource)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .fontColor([selectedHex])
      }, item.label)
        .labelStyle({
          unselectedColor: item.normalColor,
          selectedColor: selectedHex
        });
      tabBarStyleList.push(tabBarStyle);
    });
    return tabBarStyleList;
  }
}

const BAR_ITEMS: BarItem[] = [
  {
    label: $r('app.string.tab_home'),
    normalColor: $r('sys.color.icon_primary'),
    normalSymbolResource: $r('sys.symbol.house_fill'),
    selectedSymbolResource: $r('sys.symbol.house_fill')
  },
  {
    label: $r('app.string.tab_gallery'),
    normalColor: $r('sys.color.icon_primary'),
    normalSymbolResource: $r('sys.symbol.square_grid_2x2'),
    selectedSymbolResource: $r('sys.symbol.square_grid_2x2')
  },
  {
    label: $r('app.string.tab_device'),
    normalColor: $r('sys.color.icon_primary'),
    normalSymbolResource: $r('sys.symbol.display'),
    selectedSymbolResource: $r('sys.symbol.display')
  }
];

interface BarItem {
  normalSymbolResource: Resource;
  selectedSymbolResource: Resource;
  label: ResourceStr;
  normalColor: ResourceColor;
}
