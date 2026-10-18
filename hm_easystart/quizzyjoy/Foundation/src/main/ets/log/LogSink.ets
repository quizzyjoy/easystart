import { hilog } from '@kit.PerformanceAnalysisKit';
import { LogLevel, LogLevelUtil } from './LogLevel';

/** 一条结构化日志记录 */
export class LogRecord {
  level: LogLevel = LogLevel.DEBUG;
  /** 业务域，如 'home' / 'account' */
  domain: string = '';
  /** 模块或类名 */
  tag: string = '';
  message: string = '';
  timeMs: number = 0;

  constructor(level: LogLevel, domain: string, tag: string, message: string) {
    this.level = level;
    this.domain = domain;
    this.tag = tag;
    this.message = message;
    this.timeMs = Date.now();
  }

  /** 统一格式：[domain][tag] message */
  format(): string {
    return `[${this.domain}][${this.tag}] ${this.message}`;
  }
}

/**
 * 日志输出目标。
 *
 * 工程只依赖这个接口，因此可以按需扩展：
 * - ConsoleSink：本地 hilog（默认，必须保留）
 * - FileSink   ：落盘，便于用户反馈问题时导出（建议补充）
 * - RemoteSink ：上报到埋点/APM 平台（建议补充，注意脱敏与采样）
 */
export interface LogSink {
  write(record: LogRecord): void;
}

const DOMAIN: number = 0x0001;

/** 默认 sink：写入系统 hilog */
export class ConsoleSink implements LogSink {
  write(record: LogRecord): void {
    const tag: string = `${record.domain}`;
    const msg: string = `[${record.tag}] ${record.message}`;
    if (record.level === LogLevel.DEBUG) {
      hilog.debug(DOMAIN, tag, '%{public}s', msg);
    } else if (record.level === LogLevel.INFO) {
      hilog.info(DOMAIN, tag, '%{public}s', msg);
    } else if (record.level === LogLevel.WARN) {
      hilog.warn(DOMAIN, tag, '%{public}s', msg);
    } else if (record.level === LogLevel.ERROR) {
      hilog.error(DOMAIN, tag, '%{public}s', msg);
    } else {
      hilog.fatal(DOMAIN, tag, '%{public}s', msg);
    }
  }
}

/** 内存 sink：把日志收集到内存，便于单测断言与本地诊断 */
export class MemorySink implements LogSink {
  records: string[] = [];

  write(record: LogRecord): void {
    this.records.push(`${LogLevelUtil.labelOf(record.level)} ${record.format()}`);
  }

  clear(): void {
    this.records = [];
  }
}