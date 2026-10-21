import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';

const DOMAIN: string = 'demo';
const TAG: string = 'NetRepository';

/**
 * 一次请求的四种收场（模板要教的是"失败也得分类型"）。
 *
 * 为什么不用 `Result<T>`：`Result` 的语义是"可预期的业务失败"（校验不过、无数据）。
 * 网络失败有三类**处置完全不同**的收场——HTTP 状态码错（服务端问题）、超时（弱网/服务端慢）、
 * 传输异常（DNS/断网/证书）——把它们压成一个 `success=false` 会让调用方无法决定要不要重试。
 */
export enum NetOutcome {
  OK,
  /** 收到响应但状态码非 2xx */
  HTTP_ERROR,
  /** 超时（统一由 timeout 参数控制） */
  TIMEOUT,
  /** 传输层异常（无网络 / DNS / 证书 / 连接被拒） */
  TRANSPORT_ERROR,
  /** 调用方主动取消 */
  CANCELED
}

/** 请求结果快照（视图直接渲染，不再二次解析）。 */
export class NetReport {
  readonly outcome: NetOutcome;
  readonly statusCode: number;
  readonly costMs: number;
  readonly bodyPreview: string;
  readonly errorCode: number;
  readonly errorMessage: string;

  constructor(outcome: NetOutcome, statusCode: number, costMs: number, bodyPreview: string,
    errorCode: number = 0, errorMessage: string = '') {
    this.outcome = outcome;
    this.statusCode = statusCode;
    this.costMs = costMs;
    this.bodyPreview = bodyPreview;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
  }

  /** 是否算成功（仅 2xx）。 */
  isOk(): boolean {
    return this.outcome === NetOutcome.OK;
  }

  /** 一行结论，视图直接显示。 */
  summary(): string {
    if (this.outcome === NetOutcome.OK) {
      return `成功 ${this.statusCode} · ${this.costMs}ms`;
    }
    if (this.outcome === NetOutcome.HTTP_ERROR) {
      return `HTTP ${this.statusCode} · ${this.costMs}ms（非 2xx，按键重试或检查接口）`;
    }
    if (this.outcome === NetOutcome.TIMEOUT) {
      return `超时 ${this.costMs}ms（弱网/服务端慢，可加大 timeout 或重试）`;
    }
    if (this.outcome === NetOutcome.CANCELED) {
      return `已取消 · ${this.costMs}ms（destroy 后不再回调）`;
    }
    return `传输失败 code=${this.errorCode} ${this.errorMessage}`;
  }
}

/**
 * 网络请求范式（P0-2：模板缺的那一步）。
 *
 * 约定（fork 时照抄这三条就够）：
 * 1. **每次请求都要 destroy**：`http.createHttp()` 返回的对象持有底层连接，
 *    不 destroy 会泄漏；放在 finally 里最稳。
 * 2. **超时由调用方给**：`connectTimeout`/`readTimeout` 不设会等很久；
 *    这里统一用 `timeoutMs` 同时管两者。
 * 3. **区分 4 类收场**：见 `NetOutcome`，别把它们压成一个 boolean。
 *
 * 权限：需要 `ohos.permission.INTERNET`（system_grant，装包即得，不弹窗）。
 */
export class NetRepository {
  /** 演示用目标（公开只读接口，返回 JSON）。 */
  static readonly URL_OK: string = 'https://httpbin.org/json';
  /** 必返 404 的地址，用来演示「收到响应但状态码不对」。 */
  static readonly URL_404: string = 'https://httpbin.org/status/404';
  /** 慢接口（延迟 10s），配合小 timeout 演示超时。 */
  static readonly URL_SLOW: string = 'https://httpbin.org/delay/10';

  /**
   * 发起一次 GET。
   *
   * @param url 目标地址
   * @param timeoutMs 连接与读取超时（毫秒）
   */
  static async get(url: string, timeoutMs: number = 8000): Promise<NetReport> {
    const started: number = Date.now();
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs,
        expectDataType: http.HttpDataType.STRING,
        header: { 'Accept': 'application/json' }
      });
      const cost: number = Date.now() - started;
      const code: number = response.responseCode;
      // result 的类型是 string | Object | ArrayBuffer：expectDataType=STRING 通常给 string，
      // 但个别实现会回 Object（此时 typeof 判 string 会失败，导致"预览永远空白"），统一兜底。
      const raw: string | Object | ArrayBuffer = response.result;
      let body: string = '';
      if (typeof raw === 'string') {
        body = raw;
      } else if (raw instanceof ArrayBuffer) {
        body = `（${raw.byteLength} 字节二进制响应）`;
      } else {
        body = JSON.stringify(raw);
      }

      if (code >= 200 && code < 300) {
        return new NetReport(NetOutcome.OK, code, cost, NetRepository.preview(body));
      }
      return new NetReport(NetOutcome.HTTP_ERROR, code, cost, NetRepository.preview(body));
    } catch (err) {
      const cost: number = Date.now() - started;
      const be: BusinessError = err as BusinessError;
      const code: number = be.code === undefined ? -1 : be.code;
      const msg: string = be.message === undefined ? 'unknown' : be.message;
      Logger.warn(DOMAIN, TAG, `GET ${url} failed code=${code} msg=${msg}`);

      // 2300028 = 超时；其余归传输异常（断网/证书/DNS 都会落这里）
      const outcome: NetOutcome = code === 2300028 ? NetOutcome.TIMEOUT : NetOutcome.TRANSPORT_ERROR;
      return new NetReport(outcome, 0, cost, '', code, msg);
    } finally {
      // 必须释放：否则底层连接与回调会一直挂着
      request.destroy();
    }
  }

  /** 响应体太长会把页面撑爆，只留前 N 个字符。 */
  private static preview(body: string): string {
    const limit: number = 320;
    if (body.length <= limit) {
      return body;
    }
    return `${body.substring(0, limit)}…（共 ${body.length} 字符）`;
  }
}
