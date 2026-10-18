/**
 * @quizzyjoy/foundation 统一导出入口。
 *
 * 本层只做"与业务无关、零系统调用"的工程基础：
 * 1. 基础设施原语：日志、异常、结果类型、断言、脱敏；
 * 2. 数值设计令牌：间距/圆角/字号/字重/行高/阴影/描边/尺寸/层级刻度与语义布局令牌；
 * 3. 响应式值 DSL：规则 + 求值器（纯计算，数据源快照由调用方注入）。
 * 不要在本层引入 ArkUI 组件、import '@kit.*'，也不要出现任何业务语义。
 */
export { LogLevel, LogLevelUtil } from './src/main/ets/log/LogLevel';
export { LogRecord, LogSink, ConsoleSink, MemorySink } from './src/main/ets/log/LogSink';
export { Logger } from './src/main/ets/log/Logger';

export { ErrorDomain, ErrorCode } from './src/main/ets/error/ErrorCode';
export { AppError, ErrorLevel } from './src/main/ets/error/AppError';

export { Result } from './src/main/ets/result/Result';

export { Assert } from './src/main/ets/util/Assert';
export { MaskUtil } from './src/main/ets/util/MaskUtil';

export { AppSpacing } from './src/main/ets/token/AppSpacing';
export { AppRadius } from './src/main/ets/token/AppRadius';
export { AppFontSize } from './src/main/ets/token/AppFontSize';
export { AppFontWeight } from './src/main/ets/token/AppFontWeight';
export { AppLineHeight } from './src/main/ets/token/AppLineHeight';
export { AppShadow } from './src/main/ets/token/AppShadow';
export { AppSize } from './src/main/ets/token/AppSize';
export { AppStroke } from './src/main/ets/token/AppStroke';
export { AppZIndex } from './src/main/ets/token/AppZIndex';
export { DesignToken } from './src/main/ets/token/DesignToken';

export { ResponsiveOperator, ResponsiveRule, RuleValue } from './src/main/ets/responsive/ResponsiveRule';
export { ResponsiveCase, ResponsiveValueResolver } from './src/main/ets/responsive/ResponsiveValue';