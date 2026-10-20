import { HomeItem, HomeListView } from '@easystart/home-feature';

/**
 * 模板能力目录页（v3.37；v3.40 修正分发）。
 *
 * 放在入口层（product/entry）而不是 DemoFeature —— 因为 DemoFeature 的依赖方向里没有
 * HomeFeature，薄壳放这里才能同时引用 HomeListView 与入口的路由分发。
 *
 * 【v3.40 修正】原实现把 onOpenDetail 恒推到 HOME_DETAIL，导致「设置中心」「设备能力」
 * 「账号登录页范式」这些非详情项也进详情页（真机走查发现）。现在把点击整项上抛给入口，
 * 由 openHomeTarget 按 HomeTarget 分发（与 PC 端同一路径）。
 */
@ComponentV2
export struct HomeCatalogView {
  /** 点击目录项（入口按 HomeTarget 分发；feature 不感知路由）。 */
  @Param onOpenItem: (item: HomeItem) => void = (_item: HomeItem): void => {
  };

  build() {
    HomeListView({
      onOpenDetail: (item: HomeItem): void => {
        this.onOpenItem(item);
      }
    })
  }
}
