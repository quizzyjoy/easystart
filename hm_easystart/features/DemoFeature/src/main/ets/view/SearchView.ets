import { FeedbackText, StateContainer, ViewState } from '@quizzyjoy/vitalui';
import { ActionCard, CommonTag, TagTone } from '@easystart/app-component';
import { AppSection, AppTextDisplayModifier, CommonSearchBar, CommonToast } from '@easystart/app-component';
import { AppFontSize, AppSpacing, DesignToken } from '@quizzyjoy/foundation';
import { BreakpointManager, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';

/**
 * 样例子页 ⑥：搜索场景（v3.10）。
 *
 * 【fork 可整体复制的页面范式】搜索页三态流转：
 * 空查询 → 热词提示区；命中 → 结果列表（内容键 ForEach）；无命中 →
 * StateContainer 空态。CommonSearchBar 已内置 300ms 防抖（受控 @Param value），
 * 页面侧只做同步过滤、零定时器；fork 后把 MOCK_ENTRIES 换成真实
 * Repository 检索即可。
 *
 * 【导航纪律】本视图零 RouterManager import，由入口 pageMap 以
 * AppRoute.DEMO_SEARCH 挂载（DemoSample.SEARCH → 入口 switch 映射）。
 */

/** 示例检索条目（数据值非样式值，不涉 v3.7 豁免登记）。 */
class SearchEntry {
  readonly title: string;
  readonly subtitle: string;
  /** 参与匹配的关键词串（构造时统一小写）。 */
  readonly keywords: string;

  constructor(title: string, subtitle: string, keywords: string) {
    this.title = title;
    this.subtitle = subtitle;
    this.keywords = keywords.toLowerCase();
  }

  /** 关键词命中判断（入参须已小写化）。 */
  matches(normalizedKeyword: string): boolean {
    return this.keywords.includes(normalizedKeyword);
  }
}

/** 示例检索集（fork 后替换为 Repository 数据源）。 */
const MOCK_ENTRIES: SearchEntry[] = [
  new SearchEntry('狼人杀', '6-12 人言语推理局', '狼人杀 语言 推理 桌游 langrensha'),
  new SearchEntry('剧本杀', '4-8 人沉浸推理本', '剧本杀 沉浸 推理 剧本'),
  new SearchEntry('你画我猜', '3-10 人画画猜词', '你画我猜 画画 猜词 休闲'),
  new SearchEntry('谁是卧底', '4-12 人词汇伪装', '谁是卧底 卧底 词汇 派对'),
  new SearchEntry('真心话大冒险', '2-20 人破冰暖场', '真心话 大冒险 破冰 暖场'),
  new SearchEntry('数字炸弹', '2-10 人紧张刺激', '数字炸弹 紧张 刺激 简单'),
  new SearchEntry('骰子工具', '任意人数随机骰', '骰子 工具 随机'),
  new SearchEntry('计时器', '回合倒计时工具', '计时器 工具 倒计时')
];

/** 热词（点击即以该词发起搜索）。 */
const HOT_WORDS: string[] = ['狼人杀', '剧本杀', '工具', '破冰'];

@ComponentV2
export struct SearchView {
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  /** 受控搜索词（CommonSearchBar @Param value 同源）。 */
  @Local keyword: string = '';
  /** 当前命中集（空查询时恒为空数组）。 */
  @Local results: SearchEntry[] = [];

  /** 应用搜索：归一化关键词 → 过滤示例集（同步、零定时器）。 */
  private applySearch(keyword: string): void {
    this.keyword = keyword;
    const normalized: string = keyword.trim().toLowerCase();
    if (normalized === '') {
      this.results = [];
      return;
    }
    this.results = MOCK_ENTRIES.filter((entry: SearchEntry): boolean => entry.matches(normalized));
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  @Builder
  pageHeader() {
    Column({ space: AppSpacing.XS }) {
      Text('CommonSearchBar 防抖受控输入 + 热词/结果/无匹配三态流转。')
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  hotWordSection() {
    AppSection({ sectionTitle: '热词', description: '点击热词或输入关键词开始搜索（输入已内置 300ms 防抖）' }) {
      Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
        ForEach(HOT_WORDS, (word: string) => {
          CommonTag({ text: word, tone: TagTone.NEUTRAL })
            .onClick(() => {
              this.applySearch(word);
            })
        }, (word: string): string => word)
      }
      .width('100%')
    }
  }

  @Builder
  resultRow(item: SearchEntry) {
    ActionCard({
      title: item.title,
      subtitle: item.subtitle,
      onAction: () => {
        CommonToast.info(`选中：${item.title}`);
      }
    })
    .margin({ bottom: DesignToken.listItemSpacing() })
  }

  @Builder
  resultSection() {
    Scroll() {
      Column() {
        Text(`命中 ${this.results.length} 条 · 关键词「${this.keyword}」`)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .margin({ bottom: AppSpacing.MD })
        ForEach(this.results, (item: SearchEntry) => {
          this.resultRow(item)
        }, (item: SearchEntry): string => item.title)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  noMatchSection() {
    StateContainer({
      state: ViewState.EMPTY,
      emptyText: new FeedbackText('未找到匹配', `没有与「${this.keyword}」相关的条目，换个关键词试试`, '')
    })
  }

  build() {
    Column() {
      Column() {
        this.pageHeader()

        CommonSearchBar({
          placeholder: '搜索示例条目（如：狼人杀 / 工具）',
          value: this.keyword,
          onSearch: (keyword: string): void => {
            this.applySearch(keyword);
          }
        })
        .margin({ bottom: AppSpacing.MD })

        if (this.keyword === '') {
          this.hotWordSection()
        } else if (this.results.length === 0) {
          this.noMatchSection()
        } else {
          this.resultSection()
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        top: AppSpacing.LG,
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.app_bg_page'))
  }
}
