import { ComponentGalleryView } from './ComponentGalleryView';

/**
 * 组件示例分组页（v3.37）：示例 Tab 的 4 张卡进入这里。
 *
 * 薄壳——内部复用 ComponentGalleryView，用 initialGroup 预选对应区块，
 * 避免把 1600 行的组件示例拆成 4 份拷贝。
 */
@ComponentV2
export struct GalleryGroupView {
  @Param groupId: string = '';

  build() {
    ComponentGalleryView({ initialGroup: this.groupId })
  }
}