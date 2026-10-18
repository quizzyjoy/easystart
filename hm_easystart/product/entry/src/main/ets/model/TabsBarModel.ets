import { SymbolGlyphModifier } from '@kit.ArkUI';

/**
 * 底部页签样式模型（参考官方 SmartReach 示例）。
 *
 * 图标 + 文字双行页签（BottomTabBarStyle + SymbolGlyphModifier），
 * 选中/未选中颜色走 sys.color 令牌，随深浅色自动切换。
 * tab_* 文案定义在 AppScope，全入口共享。
 */
export class TabsBarModel {
  private static cachedTabBarStyleList?: BottomTabBarStyle[];

  public static getTabBarByPage(): BottomTabBarStyle[] {
    if (!TabsBarModel.cachedTabBarStyleList) {
      const tabBarStyleList: BottomTabBarStyle[] = [];
      BAR_ITEMS.forEach((item: BarItem) => {
        const tabBarStyle = new BottomTabBarStyle({
          normal: new SymbolGlyphModifier(item.normalSymbolResource)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor([item.normalColor]),
          selected: new SymbolGlyphModifier(item.selectedSymbolResource)
            .renderingStrategy(SymbolRenderingStrategy.SINGLE)
            .fontColor([item.selectedColor])
        }, item.label)
          .labelStyle({
            unselectedColor: item.normalColor,
            selectedColor: item.selectedColor
          });
        tabBarStyleList.push(tabBarStyle);
      });
      TabsBarModel.cachedTabBarStyleList = tabBarStyleList;
    }
    return TabsBarModel.cachedTabBarStyleList;
  }
}

const BAR_ITEMS: BarItem[] = [
  {
    label: $r('app.string.tab_home'),
    normalColor: $r('sys.color.icon_primary'),
    normalSymbolResource: $r('sys.symbol.house_fill'),
    selectedColor: $r('sys.color.icon_emphasize'),
    selectedSymbolResource: $r('sys.symbol.house_fill')
  },
  {
    label: $r('app.string.tab_gallery'),
    normalColor: $r('sys.color.icon_primary'),
    normalSymbolResource: $r('sys.symbol.square_grid_2x2'),
    selectedColor: $r('sys.color.icon_emphasize'),
    selectedSymbolResource: $r('sys.symbol.square_grid_2x2')
  },
  {
    label: $r('app.string.tab_device'),
    normalColor: $r('sys.color.icon_primary'),
    normalSymbolResource: $r('sys.symbol.display'),
    selectedColor: $r('sys.color.icon_emphasize'),
    selectedSymbolResource: $r('sys.symbol.display')
  }
];

interface BarItem {
  normalSymbolResource: Resource;
  selectedSymbolResource: Resource;
  label: ResourceStr;
  normalColor: ResourceColor;
  selectedColor: ResourceColor;
}
