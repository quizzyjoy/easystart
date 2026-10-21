import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

/**
 * 编码工作台的纯逻辑（v3.46）：Base64 / URL / HTML 实体 / JSON 字符串转义。
 *
 * 全部本地计算，不依赖网络；每个方法都返回结构化的 ok/error，不向上抛异常——
 * 页面只需要看 `ok` 决定展示结果还是错误文案（这是本项目「错误不出 UI 层」的约定）。
 */
export enum CodecMode {
  BASE64,
  URL,
  HTML,
  JSON_STRING
}

export class CodecResult {
  ok: boolean = false;
  output: string = '';
  error: string = '';

  static done(output: string): CodecResult {
    const r = new CodecResult();
    r.ok = true;
    r.output = output;
    return r;
  }

  static fail(error: string): CodecResult {
    const r = new CodecResult();
    r.ok = false;
    r.error = error;
    return r;
  }
}

/** 单次输入上限：超过就提示改按钮触发，避免逐字计算卡 UI。 */
export const CODEC_INPUT_LIMIT: number = 262144;

export class ToolCodec {
  private static readonly ALPHABET_UNRESERVED: string =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*\'()';

  static encode(mode: CodecMode, input: string, urlSafe: boolean): CodecResult {
    try {
      if (mode === CodecMode.BASE64) {
        const bytes: Uint8Array = new util.TextEncoder().encodeInto(input);
        const type: util.Type = urlSafe ? util.Type.BASIC_URL_SAFE : util.Type.BASIC;
        return CodecResult.done(new util.Base64Helper().encodeToStringSync(bytes, type));
      }
      if (mode === CodecMode.URL) {
        return CodecResult.done(ToolCodec.percentEncode(input));
      }
      if (mode === CodecMode.HTML) {
        return CodecResult.done(ToolCodec.htmlEncode(input));
      }
      return CodecResult.done(ToolCodec.jsonEscape(input));
    } catch (err) {
      return CodecResult.fail(`编码失败：${(err as BusinessError).message ?? '未知错误'}`);
    }
  }

  static decode(mode: CodecMode, input: string, urlSafe: boolean): CodecResult {
    try {
      if (mode === CodecMode.BASE64) {
        const helper = new util.Base64Helper();
        const preferred: util.Type = urlSafe ? util.Type.BASIC_URL_SAFE : util.Type.BASIC;
        let bytes: Uint8Array = new Uint8Array(0);
        try {
          bytes = helper.decodeSync(input, preferred);
        } catch (e) {
          // 用户可能贴了另一种变体（含 + / 或 - _），换一种再试一次
          const fallback: util.Type = urlSafe ? util.Type.BASIC : util.Type.BASIC_URL_SAFE;
          bytes = helper.decodeSync(input, fallback);
        }
        return CodecResult.done(new util.TextDecoder().decodeToString(bytes));
      }
      if (mode === CodecMode.URL) {
        return CodecResult.done(ToolCodec.percentDecode(input));
      }
      if (mode === CodecMode.HTML) {
        return CodecResult.done(ToolCodec.htmlDecode(input));
      }
      return CodecResult.done(ToolCodec.jsonUnescape(input));
    } catch (err) {
      return CodecResult.fail(`解码失败：${(err as BusinessError).message ?? '输入不是合法的编码结果'}`);
    }
  }

  /** percent-encoding（等价 encodeURIComponent）：未保留字符原样，其余按 UTF-8 字节转 %XX。 */
  private static percentEncode(input: string): string {
    const bytes: Uint8Array = new util.TextEncoder().encodeInto(input);
    let out: string = '';
    for (let i = 0; i < bytes.length; i++) {
      const b: number = bytes[i];
      const ch: string = String.fromCharCode(b);
      if (b < 128 && ToolCodec.ALPHABET_UNRESERVED.indexOf(ch) >= 0) {
        out += ch;
      } else {
        out += '%' + b.toString(16).toUpperCase().padStart(2, '0');
      }
    }
    return out;
  }

  private static percentDecode(input: string): string {
    const bytes: number[] = [];
    let i: number = 0;
    while (i < input.length) {
      const ch: string = input.charAt(i);
      if (ch === '%' && i + 2 < input.length) {
        const hex: string = input.substring(i + 1, i + 3);
        const v: number = parseInt(hex, 16);
        if (!Number.isNaN(v)) {
          bytes.push(v);
          i += 3;
          continue;
        }
      }
      // 非百分号序列：按 UTF-8 编回字节（保持与其他片段可拼接）
      const seg: Uint8Array = new util.TextEncoder().encodeInto(ch);
      for (let k = 0; k < seg.length; k++) {
        bytes.push(seg[k]);
      }
      i += 1;
    }
    const arr: Uint8Array = new Uint8Array(bytes.length);
    for (let k = 0; k < bytes.length; k++) {
      arr[k] = bytes[k];
    }
    return new util.TextDecoder().decodeToString(arr);
  }

  private static htmlEncode(input: string): string {
    let out: string = '';
    for (let i = 0; i < input.length; i++) {
      const ch: string = input.charAt(i);
      if (ch === '&') {
        out += '&amp;';
      } else if (ch === '<') {
        out += '&lt;';
      } else if (ch === '>') {
        out += '&gt;';
      } else if (ch === '"') {
        out += '&quot;';
      } else if (ch === '\'') {
        out += '&#39;';
      } else {
        const code: number = input.charCodeAt(i);
        out += code > 127 ? `&#${code};` : ch;
      }
    }
    return out;
  }

  private static htmlDecode(input: string): string {
    const named: string[] = ['&amp;', '&lt;', '&gt;', '&quot;', '&#39;', '&apos;', '&nbsp;'];
    const values: string[] = ['&', '<', '>', '"', '\'', '\'', ' '];
    let out: string = input;
    for (let i = 0; i < named.length; i++) {
      out = out.split(named[i]).join(values[i]);
    }
    // 数字实体：&#65; / &#x41;
    out = out.replace(new RegExp('&#x([0-9a-fA-F]+);', 'g'), (m: string, hex: string): string =>
      String.fromCharCode(parseInt(hex, 16)));
    out = out.replace(new RegExp('&#([0-9]+);', 'g'), (m: string, dec: string): string =>
      String.fromCharCode(parseInt(dec, 10)));
    return out;
  }

  private static jsonEscape(input: string): string {
    const quoted: string = JSON.stringify(input);
    return quoted.length >= 2 ? quoted.substring(1, quoted.length - 1) : '';
  }

  private static jsonUnescape(input: string): string {
    // 包一层引号交给 JSON.parse：\n \t \" \uXXXX 都能按标准还原
    const wrapped: string = `"${input.replace(new RegExp('"', 'g'), '\\"')}"`;
    const parsed: string = JSON.parse(wrapped) as string;
    return parsed;
  }
}
