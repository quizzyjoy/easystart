/**
 * 纯函数色彩数学：Hex ⇄ RGB ⇄ HSL / HSV。
 *
 * 为 CommonColorPicker（HdsColorPicker 的 API 23 仿照复刻，见指南 E7 例外）提供换算。
 * 零依赖、零 @kit，可独立单测；输出统一小写 '#rrggbb'，
 * 与 UiThemeManager.setAccentColor 的校验格式一致。
 */

/** 8-bit RGB 分量（0-255）。 */
export class Rgb {
  r: number = 0;
  g: number = 0;
  b: number = 0;

  constructor(r: number, g: number, b: number) {
    this.r = r;
    this.g = g;
    this.b = b;
  }
}

/** HSL 分量：h∈[0,360)、s∈[0,100]、l∈[0,100]。 */
export class Hsl {
  h: number = 0;
  s: number = 0;
  l: number = 0;

  constructor(h: number, s: number, l: number) {
    this.h = h;
    this.s = s;
    this.l = l;
  }
}

/** HSV（HSB）分量：h∈[0,360]、s∈[0,100]、v∈[0,100]——原生 SLIDERS/光谱页签的色度学维度。 */
export class Hsv {
  h: number = 0;
  s: number = 0;
  v: number = 0;

  constructor(h: number, s: number, v: number) {
    this.h = h;
    this.s = s;
    this.v = v;
  }
}

export class ColorMath {
  static clamp(value: number, min: number, max: number): number {
    return value < min ? min : (value > max ? max : value);
  }

  /** HSL → RGB（整数 0-255）。 */
  static hslToRgb(h: number, s: number, l: number): Rgb {
    const sn: number = s / 100;
    const ln: number = l / 100;
    const chroma: number = sn * Math.min(ln, 1 - ln);
    const hueNorm: number = h / 30;
    const compute = (n: number): number => {
      const k: number = (n + hueNorm) % 12;
      const t: number = Math.min(Math.min(k - 3, 9 - k), 1);
      return Math.round((ln - chroma * Math.max(t, -1)) * 255);
    };
    return new Rgb(
      ColorMath.clamp(compute(0), 0, 255),
      ColorMath.clamp(compute(8), 0, 255),
      ColorMath.clamp(compute(4), 0, 255)
    );
  }

  /** RGB → HSL。 */
  static rgbToHsl(r: number, g: number, b: number): Hsl {
    const rn: number = r / 255;
    const gn: number = g / 255;
    const bn: number = b / 255;
    const max: number = Math.max(rn, gn, bn);
    const min: number = Math.min(rn, gn, bn);
    const l: number = (max + min) / 2;
    let h: number = 0;
    let s: number = 0;
    if (max !== min) {
      const d: number = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max === rn) {
        h = ((gn - bn) / d + (gn < bn ? 6 : 0)) / 6;
      } else if (max === gn) {
        h = ((bn - rn) / d + 2) / 6;
      } else {
        h = ((rn - gn) / d + 4) / 6;
      }
    }
    return new Hsl(Math.round(h * 360), Math.round(s * 100), Math.round(l * 100));
  }

  /** RGB → '#rrggbb'（小写）。 */
  static rgbToHex(r: number, g: number, b: number): string {
    const toHex = (v: number): string => {
      return ColorMath.clamp(Math.round(v), 0, 255).toString(16).padStart(2, '0');
    };
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
  }

  /** HSL → '#rrggbb'（小写）。 */
  static hslToHex(h: number, s: number, l: number): string {
    const rgb: Rgb = ColorMath.hslToRgb(h, s, l);
    return ColorMath.rgbToHex(rgb.r, rgb.g, rgb.b);
  }

  /** Hex → RGB；支持 #RGB / #RRGGBB / #AARRGGBB（忽略 alpha）；非法输入返回 undefined。 */
  static hexToRgb(hex: string): Rgb | undefined {
    if (hex.length === 0 || hex.charAt(0) !== '#') {
      return undefined;
    }
    const clean: string = hex.substring(1).toLowerCase();
    if (clean.length === 3) {
      const r: number = parseInt(clean.charAt(0) + clean.charAt(0), 16);
      const g: number = parseInt(clean.charAt(1) + clean.charAt(1), 16);
      const b: number = parseInt(clean.charAt(2) + clean.charAt(2), 16);
      if (Number.isNaN(r) || Number.isNaN(g) || Number.isNaN(b)) {
        return undefined;
      }
      return new Rgb(r, g, b);
    }
    if (clean.length === 6 || clean.length === 8) {
      const offset: number = clean.length === 8 ? 2 : 0;
      const r: number = parseInt(clean.substring(offset, offset + 2), 16);
      const g: number = parseInt(clean.substring(offset + 2, offset + 4), 16);
      const b: number = parseInt(clean.substring(offset + 4, offset + 6), 16);
      if (Number.isNaN(r) || Number.isNaN(g) || Number.isNaN(b)) {
        return undefined;
      }
      return new Rgb(r, g, b);
    }
    return undefined;
  }

  /** Hex → HSL；非法输入返回 undefined。 */
  static hexToHsl(hex: string): Hsl | undefined {
    const rgb: Rgb | undefined = ColorMath.hexToRgb(hex);
    if (rgb === undefined) {
      return undefined;
    }
    return ColorMath.rgbToHsl(rgb.r, rgb.g, rgb.b);
  }

  /** RGB → HSV（h∈[0,360]，纯黑返回 h=0）。 */
  static rgbToHsv(r: number, g: number, b: number): Hsv {
    const rn: number = r / 255;
    const gn: number = g / 255;
    const bn: number = b / 255;
    const max: number = Math.max(rn, gn, bn);
    const min: number = Math.min(rn, gn, bn);
    const d: number = max - min;
    const s: number = max === 0 ? 0 : d / max;
    let h: number = 0;
    if (max !== min) {
      if (max === rn) {
        h = ((gn - bn) / d + (gn < bn ? 6 : 0)) / 6;
      } else if (max === gn) {
        h = ((bn - rn) / d + 2) / 6;
      } else {
        h = ((rn - gn) / d + 4) / 6;
      }
    }
    return new Hsv(Math.round(h * 360), Math.round(s * 100), Math.round(max * 100));
  }

  /** HSV → RGB（h 允许 360，内部按 360≡0 归一）。 */
  static hsvToRgb(h: number, s: number, v: number): Rgb {
    const sn: number = s / 100;
    const vn: number = v / 100;
    const chroma: number = vn * sn;
    const hueNorm: number = (h % 360) / 60;
    const x: number = chroma * (1 - Math.abs(hueNorm % 2 - 1));
    let r: number = 0;
    let g: number = 0;
    let b: number = 0;
    if (hueNorm < 1) {
      r = chroma;
      g = x;
    } else if (hueNorm < 2) {
      r = x;
      g = chroma;
    } else if (hueNorm < 3) {
      g = chroma;
      b = x;
    } else if (hueNorm < 4) {
      g = x;
      b = chroma;
    } else if (hueNorm < 5) {
      r = x;
      b = chroma;
    } else {
      r = chroma;
      b = x;
    }
    const m: number = vn - chroma;
    return new Rgb(
      ColorMath.clamp(Math.round((r + m) * 255), 0, 255),
      ColorMath.clamp(Math.round((g + m) * 255), 0, 255),
      ColorMath.clamp(Math.round((b + m) * 255), 0, 255)
    );
  }

  /** HSV → '#rrggbb'（小写）。 */
  static hsvToHex(h: number, s: number, v: number): string {
    const rgb: Rgb = ColorMath.hsvToRgb(h, s, v);
    return ColorMath.rgbToHex(rgb.r, rgb.g, rgb.b);
  }

  /** Hex → HSV；非法输入返回 undefined。 */
  static hexToHsv(hex: string): Hsv | undefined {
    const rgb: Rgb | undefined = ColorMath.hexToRgb(hex);
    if (rgb === undefined) {
      return undefined;
    }
    return ColorMath.rgbToHsv(rgb.r, rgb.g, rgb.b);
  }
}
