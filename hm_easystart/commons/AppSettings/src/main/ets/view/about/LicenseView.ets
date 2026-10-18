import { RawFileTextView } from '../../component/RawFileTextView';

/**
 * 开源许可子页（v3.13）：正文读域 rawfile/license.txt。
 * 模板占位含 HDS / HarmonyOS 商标说明与 Apache-2.0 自许可；
 * fork 应在此追加自身依赖的开源组件许可清单。
 */
@ComponentV2
export struct LicenseView {
  build() {
    RawFileTextView({ fileName: 'license.txt' })
  }
}
