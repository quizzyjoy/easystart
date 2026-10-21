import { RawFileTextView } from '../../component/RawFileTextView';

/**
 * 开源许可子页（v3.13）：正文读域 rawfile/license.txt。
 *
 * v3.50：正文换成**真实信息**（Apache-2.0 自许可 + 真实仓库地址 + 真实依赖及其许可）。
 * 顶部保留「信息」按钮，说明这是模板自带的真实信息、fork 后替换为自己的声明。
 */
@ComponentV2
export struct LicenseView {
  private static readonly INFO_TIP: string =
    '本页是模板自带的真实开源信息：Apache-2.0 许可、真实仓库地址与真实依赖清单。\n' +
      'fork 出你自己的应用后，请把「本项目许可 / 著作权人 / 仓库地址 / 第三方组件」' +
      '替换为你的实际信息。\n替换位置：commons/AppSettings/src/main/resources/rawfile/license.txt';

  build() {
    RawFileTextView({
      fileName: 'license.txt',
      infoTip: LicenseView.INFO_TIP
    })
  }
}
