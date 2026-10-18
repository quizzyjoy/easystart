/**
 * 错误码规范。
 *
 * 编码规则：`域(2位) * 10000 + 序号(4位)`，即 6 位十进制，例如：
 *   0      0000   通用未知
 *   10     0001   网络域-连接失败
 *   20     0001   存储域-写入失败
 *   30     0001   权限域-未授权
 *   40     0001   界面域-渲染异常
 *   50     0001   业务域-业务规则拒绝
 *
 * 约定：
 * - 错误码一经发布不得改变语义；废弃只做注释标记，不复用。
 * - 业务域错误码由各 feature 在自己的常量类中按同一规则申请，不要都堆到这里。
 */
export enum ErrorDomain {
  COMMON = 0,
  NETWORK = 10,
  STORAGE = 20,
  PERMISSION = 30,
  UI = 40,
  BUSINESS = 50
}

export class ErrorCode {
  /** 兜底：未知错误 */
  static readonly UNKNOWN: number = 0;

  /** 通用：入参非法（可预期，应由调用方修正） */
  static readonly PARAM_INVALID: number = 1;
  /** 通用：状态非法（如未初始化就调用） */
  static readonly ILLEGAL_STATE: number = 2;
  /** 通用：能力不可用（syscap 缺失 / 版本不足） */
  static readonly CAPABILITY_UNAVAILABLE: number = 3;
  /** 通用：操作超时 */
  static readonly TIMEOUT: number = 4;

  /** 按"域 + 序号"合成错误码 */
  static make(domain: ErrorDomain, sequence: number): number {
    return domain * 10000 + sequence;
  }

  /** 取错误码所属域 */
  static domainOf(code: number): number {
    return Math.floor(code / 10000);
  }
}