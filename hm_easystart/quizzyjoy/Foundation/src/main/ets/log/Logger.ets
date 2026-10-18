import { LogLevel, LogLevelUtil } from './LogLevel';
import { ConsoleSink, LogRecord, LogSink } from './LogSink';

/**
 * 统一日志出口。
 *
 * 铁律：
 * 1. 业务代码禁止直接调用 hilog，一律经过本类——否则无法统一裁剪、上报与脱敏。
 * 2. 每次调用必须给 domain（业务域）与 tag（模块），日志才可检索。
 * 3. 禁止把敏感信息（手机号、token、身份证）拼进 message；如需打印，先用 MaskUtil 脱敏。
 * 4. 禁止在循环体内打 DEBUG 日志；禁止长期保留临时调试日志。
 */
export class Logger {
  private static minLevel: LogLevel = LogLevel.DEBUG;
  private static sinks: LogSink[] = [new ConsoleSink()];

  /** 设置最低输出级别（发布版建议 WARN） */
  static setMinLevel(level: LogLevel): void {
    Logger.minLevel = level;
  }

  /** 追加输出目标（如上报 sink） */
  static addSink(sink: LogSink): void {
    Logger.sinks.push(sink);
  }

  /** 清空输出目标并恢复默认控制台输出（主要用于测试） */
  static resetSinks(): void {
    Logger.sinks = [new ConsoleSink()];
  }

  static debug(domain: string, tag: string, message: string): void {
    Logger.emit(LogLevel.DEBUG, domain, tag, message);
  }

  static info(domain: string, tag: string, message: string): void {
    Logger.emit(LogLevel.INFO, domain, tag, message);
  }

  static warn(domain: string, tag: string, message: string): void {
    Logger.emit(LogLevel.WARN, domain, tag, message);
  }

  static error(domain: string, tag: string, message: string): void {
    Logger.emit(LogLevel.ERROR, domain, tag, message);
  }

  static fatal(domain: string, tag: string, message: string): void {
    Logger.emit(LogLevel.FATAL, domain, tag, message);
  }

  private static emit(level: LogLevel, domain: string, tag: string, message: string): void {
    if (level < Logger.minLevel) {
      return;
    }
    const record: LogRecord = new LogRecord(level, domain, tag, message);
    for (const sink of Logger.sinks) {
      try {
        sink.write(record);
      } catch (err) {
        // 日志系统自身绝不能让业务崩溃
      }
    }
  }

  /** 便于外部统一格式化（如上报前拼级别） */
  static format(level: LogLevel, domain: string, tag: string, message: string): string {
    return `${LogLevelUtil.labelOf(level)} [${domain}][${tag}] ${message}`;
  }
}