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
import {
  AppGalleryHelper,
  StorePrivacyKind,
  StorePrivacyRecord,
  StorePrivacySnapshot,
  StorePrivacyState
} from '@quizzyjoy/platform';

@ComponentV2
export struct PolicyView {
  @Param kind: string = 'privacy';
  /** 隐私签署状态文案（空串 = 不展示该行；v3.54 来自 getAppPrivacyResult）。 */
  @Local privacyState: string = '';

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

  aboutToAppear(): void {
    this.refreshPrivacyState();
  }

  /**
   * 查询隐私签署结果（AppGallery Kit `privacyManager.getAppPrivacyResult`，v3.54）。
   *
   * 只在隐私政策 / 用户协议页展示；未上架或未接入隐私托管服务时返回空数组，
   * 此时显示「状态未知」，不把"查不到"说成"没同意"。
   */
  private refreshPrivacyState(): void {
    if (this.kind === 'sdk') {
      this.privacyState = '';
      return;
    }
    const snapshot: StorePrivacySnapshot = AppGalleryHelper.getInstance().getPrivacySnapshot();
    if (snapshot.state === StorePrivacyState.UNSUPPORTED) {
      this.privacyState = '隐私状态：当前设备不支持查询（未连接应用市场服务）';
      return;
    }
    if (snapshot.state === StorePrivacyState.NOT_SUBSCRIBED) {
      // 1006700003：本应用未接入应用市场隐私托管服务，系统侧没有签署记录可查
      this.privacyState = '隐私状态：未接入应用市场隐私托管服务（无签署记录）';
      return;
    }
    if (snapshot.state === StorePrivacyState.NO_RECORD) {
      this.privacyState = '隐私状态：未签署';
      return;
    }
    const records: StorePrivacyRecord[] = snapshot.records;
    const agreed: StorePrivacyRecord | undefined =
      records.find((r: StorePrivacyRecord): boolean => r.agreed);
    if (agreed === undefined) {
      this.privacyState = `隐私状态：已撤回（协议 v${records[0].versionCode}）`;
      return;
    }
    if (agreed.signingTimestamp > 0) {
      const d: Date = new Date(agreed.signingTimestamp);
      const day: string = `${d.getFullYear()}-${this.pad(d.getMonth() + 1)}-${this.pad(d.getDate())}`;
      this.privacyState = `隐私状态：已同意 · 版本 ${agreed.versionCode} · ${day}`;
    } else {
      this.privacyState = `隐私状态：已同意 · 版本 ${agreed.versionCode}`;
    }
  }

  private pad(v: number): string {
    return v < 10 ? `0${v}` : `${v}`;
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
    Column() {
      if (this.privacyState.length > 0) {
        Row({ space: 6 }) {
          SymbolGlyph($r('sys.symbol.info_circle'))
            .fontSize(12)
            .fontColor([$r('app.color.app_text_secondary')])
          Text(this.privacyState)
            .fontSize(12)
            .fontColor($r('app.color.app_text_secondary'))
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8 })
        .backgroundColor($r('app.color.app_bg_page_deep'))
      }
      RawFileTextView({
        fileName: this.policyFileName(),
        infoTip: this.kind === 'sdk' ? PolicyView.SDK_INFO_TIP : '',
        onlineUrl: this.onlineUrl()
      })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
