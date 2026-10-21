import { AppSpacing } from './AppSpacing';
import { ResponsiveCase, ResponsiveValueResolver } from '../responsive/ResponsiveValue';
import { ResponsiveRule, ResponsiveOperator } from '../responsive/ResponsiveRule';

/**
 * 设计令牌聚合入口（仅静态方法，不提供对象字段）。
 *
 * breakpoint 入参为语义断点名（'xs' | 'sm' | 'md' | 'lg' | 'xl'），
 * 与 @quizzyjoy/platform 的 BreakpointType 枚举值一一对应；
 * 本层不依赖 platform，故用 string 解耦，调用方传 `${bp}` 即可。
 *
 * v2.4 起 pagePadding 为响应式 DSL（ResponsiveValueResolver）首个消费者：
 * 规则即数据（IN 集合命中），行为与原三元表达式逐档等价。
 *
 * v3.0 起新增语义间距别名（cardPadding / cardGap / listItemSpacing /
 * sectionSpacing / screenEdgePadding）：组件与页面按语义选间距，
 * 不再逐处从 AppSpacing 数字档里挑（多端差异收敛在本层）。
 */

/** pagePadding 响应式规则表：lg/xl → XL，其余 → LG。 */
const PAGE_PADDING_CASES: ResponsiveCase<number>[] = [
  new ResponsiveCase<number>(
    [new ResponsiveRule('breakpoint', ResponsiveOperator.IN, ['lg', 'xl'])],
    AppSpacing.XL
  )
];

/** screenEdgePadding 响应式规则表：lg/xl → XL（TV 大屏安全边距），其余 → LG。 */
const SCREEN_EDGE_CASES: ResponsiveCase<number>[] = [
  new ResponsiveCase<number>(
    [new ResponsiveRule('breakpoint', ResponsiveOperator.IN, ['lg', 'xl'])],
    AppSpacing.XL
  )
];

/** HDS 悬浮页签栏高度（vp）。规范值豁免登记：HdsTabs 悬浮胶囊实测 175px@3.125x=56vp。 */
const TAB_BAR_HEIGHT_VP = 56;
/** 无小白条设备的页签栏底距回落（vp）。= sys.float.padding_level8，与入口 barFloatingStyle
 * 的 barBottomMargin 回落（Index.ets/PcIndex.ets）保持对称。 */
const TAB_BAR_BOTTOM_FALLBACK_VP = 8;

export class DesignToken {
  /** 通用页面水平内边距：宽屏 24，其余 16（响应式 DSL 求值，行为等价改造）。 */
  static pagePadding(breakpoint: string): number {
    const snapshot: Record<string, string | number | boolean> = { 'breakpoint': breakpoint };
    return ResponsiveValueResolver.resolve<number>(
      PAGE_PADDING_CASES, snapshot, AppSpacing.LG);
  }

  /**
   * 按**容器实际宽度**算列数（v3.71）。
   *
   * 为什么不用断点：`isWide()` 回答的是"窗口够宽"，回答不了"分栏左栏 360vp 够不够两列"。
   * 折叠屏 / 2in1 分栏下容器宽往往只有 340–420vp，此时按窗口断点排两列会把卡片压到 ~165vp。
   * 调用方用 `onAreaChange` 拿到自身宽度后传进来即可，无需宿主改签名。
   *
   * @param containerWidthVp 容器宽度（vp）
   * @param minItemVp 单列可读的最小宽度（卡片类建议 320，导航行建议 360）
   * @param gapVp 列间距（默认取 md 档的网格间距）
   */
  static gridColumns(containerWidthVp: number, minItemVp: number, gapVp: number = AppSpacing.MD): number {
    if (containerWidthVp <= 0 || minItemVp <= 0) {
      return 1;
    }
    const perItem: number = minItemVp + gapVp;
    const count: number = Math.floor((containerWidthVp + gapVp) / perItem);
    return count < 1 ? 1 : count;
  }

  /** 容器宽驱动的两列判定：够两列则返回 48.5%，否则 100%（供 Flex wrap 卡片用）。 */
  static twoUpWidth(containerWidthVp: number, minItemVp: number, gapVp: number = AppSpacing.MD): string {
    return DesignToken.gridColumns(containerWidthVp, minItemVp, gapVp) >= 2 ? '48.5%' : '100%';
  }

  /** 内容最大宽度（阅读类页面用，避免超宽屏文字过长）。 */
  static contentMaxWidth(breakpoint: string): number {
    if (breakpoint === 'xl') {
      return 1200;
    }
    if (breakpoint === 'lg') {
      return 1040;
    }
    return 720;
  }

  /** 列表项间距（按断点）。 */
  static gridGap(breakpoint: string): number {
    return (breakpoint === 'lg' || breakpoint === 'xl')
      ? AppSpacing.LG : AppSpacing.MD;
  }

  /** 卡片内边距（统一 16，官方 default padding 12 上取整）。 */
  static cardPadding(): number {
    return AppSpacing.LG;
  }

  /** 卡片组内间距。 */
  static cardGap(): number {
    return AppSpacing.SM;
  }

  /** 列表行间距（官方列表行高体系）。 */
  static listItemSpacing(): number {
    return AppSpacing.MD;
  }

  /** 区块间隔（大段内容之间）。 */
  static sectionSpacing(): number {
    return AppSpacing.XL;
  }

  /** 屏幕安全边距（TV 过扫区加宽；响应式 DSL 求值）。 */
  static screenEdgePadding(breakpoint: string): number {
    const snapshot: Record<string, string | number | boolean> = { 'breakpoint': breakpoint };
    return ResponsiveValueResolver.resolve<number>(
      SCREEN_EDGE_CASES, snapshot, AppSpacing.LG);
  }

  /**
   * Tab 子页底部内边距（v3.11 新增）。
   * 底部悬浮页签栏（barOverlap 沉浸，内容延伸至栏下）的遮挡 = 栏底距 + 栏高 + 呼吸间距；
   * 宽屏（lg/xl）页签栏在侧边、无底部遮挡，保持常规底距 XL。
   * bottomAvoidVp 由调用方从 WindowAdapter 注入（本层不依赖 platform，string/number 解耦）。
   */
  static tabPageBottomPadding(breakpoint: string, bottomAvoidVp: number): number {
    if (breakpoint === 'lg' || breakpoint === 'xl') {
      return AppSpacing.XL;
    }
    const barBottom: number = Math.max(bottomAvoidVp, TAB_BAR_BOTTOM_FALLBACK_VP);
    return barBottom + TAB_BAR_HEIGHT_VP + AppSpacing.LG;
  }
}
