import { ErrorCode } from './ErrorCode';

/**
 * 错误严重级别——决定调用方该怎么处理，这是异常设计的核心。
 */
export enum ErrorLevel {
  /** 可预期：属于正常业务分支（校验不通过、无数据），调用方应直接处理，不要当异常上报 */
  EXPECTED = 'expected',
  /** 可恢复：临时失败（超时、网络抖动），调用方可重试或降级，需要记 WARN/ERROR */
  RECOVERABLE = 'recoverable',
  /** 致命：数据损坏、状态不可恢复，必须上抛到全局兜底并上报，页面做安全降级 */
  FATAL = 'fatal'
}

/**
 * 全工程唯一的错误类型。
 *
 * 铁律：
 * 1. 只允许 throw AppError（或其子类）；禁止 throw 字符串 / 数字 / 裸 Error。
 * 2. 只有 ErrorLevel.EXPECTED 的场景可用返回值（Result）表达，不必 throw。
 * 3. 构造时必须给 domain，否则日志与上报无法归因。
 */
export class AppError extends Error {
  readonly code: number;
  readonly level: ErrorLevel;
  readonly domain: string;
  readonly detail: string;
  readonly causeError: Error | undefined;

  constructor(code: number, message: string, level: ErrorLevel, domain: string, detail: string,
    causeError?: Error) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.level = level;
    this.domain = domain;
    this.detail = detail;
    this.causeError = causeError;
  }

  /** 可预期失败（业务分支），不产生异常日志噪音 */
  static expected(code: number, message: string, domain: string = 'common', detail: string = ''): AppError {
    return new AppError(code, message, ErrorLevel.EXPECTED, domain, detail);
  }

  /** 可恢复失败（临时性），需要记 WARN/ERROR */
  static recoverable(code: number, message: string, domain: string = 'common', detail: string = '',
    cause?: Error): AppError {
    return new AppError(code, message, ErrorLevel.RECOVERABLE, domain, detail, cause);
  }

  /** 致命失败，必须上抛到全局兜底 */
  static fatal(code: number, message: string, domain: string = 'common', detail: string = '',
    cause?: Error): AppError {
    return new AppError(code, message, ErrorLevel.FATAL, domain, detail, cause);
  }

  /** 附加上下文（如 requestId / 页面名），返回新实例，保持不可变 */
  withDetail(detail: string): AppError {
    return new AppError(this.code, this.message, this.level, this.domain, detail, this.causeError);
  }

  /** 是否需要上报（EXPECTED 不上报） */
  needReport(): boolean {
    return this.level !== ErrorLevel.EXPECTED;
  }

  /** 统一日志/上报文本 */
  toLog(): string {
    const caused: string = this.causeError === undefined ? '' : ` cause=${this.causeError.message}`;
    return `code=${this.code} level=${this.level} domain=${this.domain} message=${this.message}`
      + ` detail=${this.detail}${caused}`;
  }

  /** 是否属于某域 */
  isDomain(domain: string): boolean {
    return this.domain === domain;
  }

  /** 通用未知错误 */
  static unknown(message: string = 'unknown error', domain: string = 'common'): AppError {
    return AppError.recoverable(ErrorCode.UNKNOWN, message, domain);
  }
}