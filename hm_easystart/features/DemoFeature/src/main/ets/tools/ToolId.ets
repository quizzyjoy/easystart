import { util } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

/**
 * ID 生成（v3.46）：UUID v4 用系统 `util.generateRandomUUID`，ULID 手写。
 *
 * ULID = 48 bit 时间戳 + 80 bit 随机，Crockford Base32 编码成 26 字符；字符串天然
 * 字典序 = 时间序，适合当 requestId / traceId / 演示数据主键。
 */
export class ToolId {
  /** UUID v4（第 13 位固定 4、第 17 位 ∈ 89ab 由系统保证）。 */
  static uuidV4(): string {
    return util.generateRandomUUID(true);
  }

  /** 当前时间生成的 ULID。 */
  static ulid(): string {
    return ToolId.ulidAt(Date.now());
  }

  static ulidAt(ms: number): string {
    const bytes: Uint8Array = new Uint8Array(16);
    // 前 6 字节：48 bit 毫秒时间戳（大端）
    let ts: number = ms;
    for (let i = 5; i >= 0; i--) {
      bytes[i] = ts % 256;
      ts = Math.floor(ts / 256);
    }
    // 后 10 字节：密码学随机
    const random: Uint8Array = cryptoFramework.createRandom().generateRandomSync(10).data;
    for (let i = 0; i < 10; i++) {
      bytes[6 + i] = random[i];
    }
    return ToolId.crockfordBase32(bytes);
  }

  /** ISO 时间（UTC）。 */
  static iso(ms: number): string {
    return new Date(ms).toISOString();
  }

  /** 本地可读时间，避免 ISO 的 Z 时区误读。 */
  static local(ms: number): string {
    const d: Date = new Date(ms);
    const pad = (n: number): string => n < 10 ? `0${n}` : `${n}`;
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
      `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  }

  /** 16 字节 → 26 字符 Crockford Base32（128 bit 前补 2 个 0 位对齐到 130 bit）。 */
  private static crockfordBase32(bytes: Uint8Array): string {
    const alphabet: string = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    let out: string = '';
    for (let i = 0; i < 26; i++) {
      let v: number = 0;
      for (let b = 0; b < 5; b++) {
        const bitPos: number = i * 5 + b;
        const idx: number = bitPos - 2;
        let bit: number = 0;
        if (idx >= 0 && idx < 128) {
          const byteIdx: number = Math.floor(idx / 8);
          const bitInByte: number = 7 - (idx % 8);
          bit = (bytes[byteIdx] >> bitInByte) & 1;
        }
        v = v * 2 + bit;
      }
      out += alphabet.charAt(v);
    }
    return out;
  }
}
