/**
 * 日志级别。
 *
 * 级别语义（写日志时按这个判断，不要随意升/降级）：
 * - DEBUG：只在开发期关心的细节（入参出参、状态流转、循环内），发布版默认裁剪
 * - INFO ：关键业务节点（页面进入/退出、流程开始/结束、配置生效）
 * - WARN ：可自动恢复的异常、降级分支、能力缺失（如 syscap 不可用走了兜底）
 * - ERROR：需要人工介入的失败（接口失败、数据解析失败、状态非法）
 * - FATAL：进程级致命错误，通常伴随崩溃或不可继续
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4
}

export class LogLevelUtil {
  /** 级别名称（注意：不能命名为 name，会与 Function.name 冲突） */
  static labelOf(level: LogLevel): string {
    if (level === LogLevel.DEBUG) {
      return 'DEBUG';
    }
    if (level === LogLevel.INFO) {
      return 'INFO';
    }
    if (level === LogLevel.WARN) {
      return 'WARN';
    }
    if (level === LogLevel.ERROR) {
      return 'ERROR';
    }
    return 'FATAL';
  }
}