/**
 * 政策文本子页（隐私政策 / 用户协议 / 第三方 SDK 清单共用，v3.13；v3.28 扩 'sdk'）。
 *
 * SettingsDestination 按 param（'privacy' | 'terms' | 'sdk'）传入 kind 并装配
 * titleBar 标题；正文读域 rawfile，fork 替换文本即可。kind 用 string 接收，
 * 非 'terms' / 'sdk' 一律按隐私政策渲染（兜底）。
 */
import { RawFileTextView } from '../../component/RawFileTextView';

@ComponentV2
export struct PolicyView {
  @Param kind: string = 'privacy';

  private policyFileName(): string {
    if (this.kind === 'terms') {
      return 'policy_terms.txt';
    }
    if (this.kind === 'sdk') {
      return 'sdk_list.txt';
    }
    return 'policy_privacy.txt';
  }

  build() {
    RawFileTextView({
      fileName: this.policyFileName()
    })
  }
}
