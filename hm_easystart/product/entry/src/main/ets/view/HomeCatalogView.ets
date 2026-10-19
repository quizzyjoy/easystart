import { RouterManager } from '@quizzyjoy/platform';
import { AppRoute } from '@easystart/app-routes';
import { HomeItem, HomeListView } from '@easystart/home-feature';

/**
 * 能力目录页（v3.37）：示例 Tab 的「模板能力目录」卡进入这里。
 *
 * 放在入口层（product/entry）而不是 DemoFeature —— 因为 DemoFeature 的依赖方向里没有
 * HomeFeature / AppRoutes，薄壳放这里才能同时引用 HomeListView 与路由常量。
 */
@ComponentV2
export struct HomeCatalogView {
  build() {
    HomeListView({
      onOpenDetail: (item: HomeItem): void => {
        RouterManager.getInstance().push(AppRoute.HOME_DETAIL, item);
      }
    })
  }
}