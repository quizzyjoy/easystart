import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

/**
 * 哈希校验的纯逻辑（v3.46）。
 *
 * 用系统 `cryptoFramework`（syscap `SystemCapability.Security.CryptoFramework`）本地算摘要，
 * 不联网、不需要权限。算法名以 SDK 支持列表为准，逐个调 `createMd` 时用 try/catch 兜住
 * ——不支持就返回 ok=false 并带上原因，页面只负责展示。
 */
export class HashOutcome {
  ok: boolean = false;
  hex: string = '';
  error: string = '';
  /** 与期望值比对结果：'' 表示没填期望值，'一致' / '不一致' 为结论。 */
  compare: string = '';

  static fail(error: string): HashOutcome {
    const o = new HashOutcome();
    o.ok = false;
    o.error = error;
    return o;
  }
}

export class ToolHash {
  /** 页面上的算法选项（顺序即展示顺序）。 */
  static readonly ALGORITHMS: string[] = ['SHA256', 'SHA512', 'SHA1', 'MD5'];

  static async digest(alg: string, text: string): Promise<HashOutcome> {
    try {
      const md: cryptoFramework.Md = cryptoFramework.createMd(alg);
      const bytes: Uint8Array = new util.TextEncoder().encodeInto(text);
      await md.update({ data: bytes });
      const blob: cryptoFramework.DataBlob = await md.digest();
      const out = new HashOutcome();
      out.ok = true;
      out.hex = ToolHash.toHex(blob.data);
      return out;
    } catch (err) {
      const e = err as BusinessError;
      return HashOutcome.fail(`本设备不支持 ${alg}（code=${e.code ?? -1}）`);
    }
  }

  /** 摘要值（小写十六进制）与用户期望值比对，忽略大小写与空白。 */
  static compare(expected: string, actual: string): string {
    const a: string = expected.replace(new RegExp('\\s', 'g'), '').toLowerCase();
    if (a.length === 0) {
      return '';
    }
    return a === actual.toLowerCase() ? '一致' : '不一致';
  }

  private static toHex(bytes: Uint8Array): string {
    let hex: string = '';
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0');
    }
    return hex;
  }
}
