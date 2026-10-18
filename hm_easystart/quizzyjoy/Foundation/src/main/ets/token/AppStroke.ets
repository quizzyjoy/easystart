/**
 * 描边宽度刻度（vp）。
 *
 * v3.0 新增。官方惯例对表：常规边框 1（checkbox/switch/radio/badge）、
 * 选中描边 2（checkbox stroke / picker·rating focus border）、
 * 焦点环 2vp + 2vp 外边距（官方 picker focus border width+margin）。
 */
export class AppStroke {
  /** 头发丝线（仅高分屏细线场景）。 */
  static readonly HAIR: number = 0.5;
  /** 常规边框（官方 checkbox/switch/badge=1）。 */
  static readonly THIN: number = 1;
  /** 选中描边 / 焦点环（官方 checkbox stroke / focus border=2）。 */
  static readonly MEDIUM: number = 2;
  /** 重分隔 / 进度环。 */
  static readonly THICK: number = 4;
  /** 焦点环外边距（官方 picker focus border margin=2）。 */
  static readonly FOCUS_MARGIN: number = 2;
}
