import { ComponentGalleryView } from './ComponentGalleryView';
import { DemoSample } from './DemoSample';

/**
 * 组件示例分组页（L2，v3.38 三级架构）。
 *
 * 薄壳：L1 首页「组件示例」的四行分别进入本页，按 groupId 只渲染对应分组
 * （原 ComponentGalleryView 的区块索引卡切换已移除，分组选择上移到 L1）。
 * 分组名/描述唯一出处在 model/GalleryGroup，本页不重复维护文案。
 */
@ComponentV2
export struct ComponentGroupView {
  /** basic / visual / platform / app（未知值由 ComponentGalleryView 回落「入口与基础」）。 */
  @Param groupId: string = 'basic';

  /** 独立示例入口（v3.79）：本层只透传，路由映射留在入口装配层。 */
  @Event onOpenSample: (sample: DemoSample) => void = (_sample: DemoSample): void => {
  };

  build() {
    ComponentGalleryView({
      groupId: this.groupId,
      onOpenSample: (sample: DemoSample): void => {
        this.onOpenSample(sample);
      }
    })
  }
}
