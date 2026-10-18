import { describe, it, expect } from '@ohos/hypium';
import {
  AppSpacing,
  ResponsiveCase,
  ResponsiveOperator,
  ResponsiveRule,
  ResponsiveValueResolver
} from '@quizzyjoy/foundation';

/**
 * ResponsiveValueResolver 本地单测（LocalUnit，纯计算零 UI 依赖）。
 *
 * v3.1 起作为模板测试链路示范：验证 first-match-wins 顺序语义、
 * BETWEEN_CLOSED 闭区间边界、IN/NOT_IN 集合判定、fallback 兜底、
 * 类型不符保守不命中（v2.4.1 裁定的语义）。
 * 运行：DevEco → entry src/test → LocalUnit（hvigor test 任务）。
 */
export default function localUnitTest() {
  describe('ResponsiveValueResolverTest', () => {
    it('firstMatchWins', 0, () => {
      const cases: ResponsiveCase<string>[] = [
        new ResponsiveCase<string>(
          [new ResponsiveRule('widthVp', ResponsiveOperator.GTE, 600)], 'wide'),
        new ResponsiveCase<string>(
          [new ResponsiveRule('widthVp', ResponsiveOperator.GTE, 500)], 'mid')
      ];
      const snapshot: Record<string, string | number | boolean> = { 'widthVp': 712 };
      expect(ResponsiveValueResolver.resolve<string>(cases, snapshot, 'fallback')).assertEqual('wide');
    });

    it('betweenClosedBoundaries', 0, () => {
      const cases: ResponsiveCase<string>[] = [
        new ResponsiveCase<string>(
          [new ResponsiveRule('widthVp', ResponsiveOperator.BETWEEN_CLOSED, [600, 840])], 'mid')
      ];
      const lowerEdge: Record<string, string | number | boolean> = { 'widthVp': 600 };
      const upperEdge: Record<string, string | number | boolean> = { 'widthVp': 840 };
      const below: Record<string, string | number | boolean> = { 'widthVp': 599 };
      const above: Record<string, string | number | boolean> = { 'widthVp': 841 };
      expect(ResponsiveValueResolver.resolve<string>(cases, lowerEdge, 'none')).assertEqual('mid');
      expect(ResponsiveValueResolver.resolve<string>(cases, upperEdge, 'none')).assertEqual('mid');
      expect(ResponsiveValueResolver.resolve<string>(cases, below, 'none')).assertEqual('none');
      expect(ResponsiveValueResolver.resolve<string>(cases, above, 'none')).assertEqual('none');
    });

    it('inAndNotInMembership', 0, () => {
      const inCase: ResponsiveCase<string>[] = [
        new ResponsiveCase<string>(
          [new ResponsiveRule('breakpoint', ResponsiveOperator.IN, ['md', 'lg'])], 'hit')
      ];
      const notInCase: ResponsiveCase<string>[] = [
        new ResponsiveCase<string>(
          [new ResponsiveRule('breakpoint', ResponsiveOperator.NOT_IN, ['sm', 'xs'])], 'wide-only')
      ];
      const md: Record<string, string | number | boolean> = { 'breakpoint': 'md' };
      const sm: Record<string, string | number | boolean> = { 'breakpoint': 'sm' };
      expect(ResponsiveValueResolver.resolve<string>(inCase, md, 'none')).assertEqual('hit');
      expect(ResponsiveValueResolver.resolve<string>(inCase, sm, 'none')).assertEqual('none');
      expect(ResponsiveValueResolver.resolve<string>(notInCase, md, 'none')).assertEqual('wide-only');
    });

    it('fallbackWhenNoRuleMatches', 0, () => {
      const cases: ResponsiveCase<number>[] = [
        new ResponsiveCase<number>(
          [new ResponsiveRule('isWide', ResponsiveOperator.EQ, true)], AppSpacing.XL)
      ];
      const narrow: Record<string, string | number | boolean> = { 'isWide': false };
      expect(ResponsiveValueResolver.resolve<number>(cases, narrow, AppSpacing.LG)).assertEqual(AppSpacing.LG);
    });

    it('typeMismatchIsConservativeMiss', 0, () => {
      // v2.4.1 裁定：类型不符一律保守「不命中」（与官方「非数组即 true」不同）
      const cases: ResponsiveCase<string>[] = [
        new ResponsiveCase<string>(
          [new ResponsiveRule('breakpoint', ResponsiveOperator.NOT_IN, ['sm'])], 'not-small')
      ];
      const numericActual: Record<string, string | number | boolean> = { 'breakpoint': 2 };
      expect(ResponsiveValueResolver.resolve<string>(cases, numericActual, 'fallback')).assertEqual('fallback');
    });
  });
}
