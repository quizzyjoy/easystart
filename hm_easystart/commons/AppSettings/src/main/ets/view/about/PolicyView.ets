/**
 * 政策文本子页（隐私政策 / 用户协议 / 第三方 SDK 清单共用，v3.13；v3.28 扩 'sdk'）。
 *
 * SettingsDestination 按 param（'privacy' | 'terms' | 'sdk'）传入 kind 并装配
 * titleBar 标题；正文读域 rawfile，fork 替换文本即可。kind 用 string 接收，
 * 非 'terms' / 'sdk' 一律按隐私政策渲染（兜底）。
 *
 * v3.50：SDK 清单正文换成**真实信息**（真实依赖 + 提供方 + 许可 + 是否收集信息），
 * 顶部保留「信息」按钮提示 fork 后替换。
 */
import { RawFileTextView } from '../../component/RawFileTextView';
import { AppGalleryHelper, StorePrivacyKind } from '@quizzyjoy/platform';

@ComponentV2
export struct PolicyView {
  @Param kind: string = 'privacy';

  private static readonly SDK_INFO_TIP: string =
    '本页是模板自带的真实 SDK 清单：实际的四个第三方依赖 + 系统 SDK，并标注均不收集个人信息。\n' +
      'fork 后请按你实际集成的第三方 SDK 逐条替换（名称 / 提供方 / 用途 / 收集的信息 / 链接）。\n' +
      '替换位置：commons/AppSettings/src/main/resources/rawfile/sdk_list.txt';

  private policyFileName(): string {
    if (this.kind === 'terms') {
      return 'policy_terms.txt';
    }
    if (this.kind === 'sdk') {
      return 'sdk_list.txt';
    }
    return 'policy_privacy.txt';
  }

  /**
   * 隐私政策 / 用户协议的在线托管地址（离线副本页的「浏览在线版」出口）。
   *
   * 取址顺序由 AppGalleryHelper 决定：应用市场隐私托管服务返回的官方链接优先，
   * 未托管 / 未上架时回退内置真实托管地址；两者都没有才返回空串（不渲染按钮）。
   */
  private onlineUrl(): string {
    if (this.kind === 'terms') {
      return AppGalleryHelper.getInstance().getPrivacyLink(StorePrivacyKind.USER_AGREEMENT);
    }
    if (this.kind === 'privacy') {
      return AppGalleryHelper.getInstance().getPrivacyLink(StorePrivacyKind.STATEMENT);
    }
    return '';
  }

  build() {
    RawFileTextView({
      fileName: this.policyFileName(),
      infoTip: this.kind === 'sdk' ? PolicyView.SDK_INFO_TIP : '',
      onlineUrl: this.onlineUrl()
    })
  }
}
