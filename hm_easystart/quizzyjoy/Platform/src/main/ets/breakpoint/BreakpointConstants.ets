/**
 * 断点规格。
 *
 * 【核心纪律】断点阈值由平台定义，业务代码禁止硬编码像素阈值。
 * 本文件只做「平台枚举 → 语义名 / 栅格列数」的映射。
 *
 * 平台阈值（官方推荐，vp，按"应用窗口宽度"判定；同一设备的不同窗口形态会落入不同断点）：
 *   xl  >= 1440        2in1 全屏、折叠电脑展开
 *   lg  [840, 1440)    平板横屏、智慧屏(TV 1280vp)
 *   md  [600, 840)     平板竖屏、手机横屏、折叠展开态
 *   sm  [320, 600)     手机竖屏、小折叠
 *   xs  < 320          智能穿戴
 *
 * 取值来源：UIContext.getWindowWidthBreakpoint() / getWindowHeightBreakpoint()。
 * WidthBreakpoint / HeightBreakpoint 是 ArkUI 全局枚举，无需 import。
 */
export enum BreakpointType {
  XS = 'xs',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

export class BreakpointConstants {
  /** 平台枚举 → 语义名。xs 与 sm 归为一档时用 normalize()。 */
  static resolve(widthBp: WidthBreakpoint): BreakpointType {
    if (widthBp === WidthBreakpoint.WIDTH_XL) {
      return BreakpointType.XL;
    }
    if (widthBp === WidthBreakpoint.WIDTH_LG) {
      return BreakpointType.LG;
    }
    if (widthBp === WidthBreakpoint.WIDTH_MD) {
      return BreakpointType.MD;
    }
    if (widthBp === WidthBreakpoint.WIDTH_SM) {
      return BreakpointType.SM;
    }
    return BreakpointType.XS;
  }

  /** 栅格总列数（官方 4 / 8 / 12 栅格体系） */
  static gridColumns(type: BreakpointType): number {
    if (type === BreakpointType.MD) {
      return 8;
    }
    if (type === BreakpointType.LG || type === BreakpointType.XL) {
      return 12;
    }
    return 4;
  }

  /** 内容列数（业务列表常用） */
  static contentColumns(type: BreakpointType): number {
    if (type === BreakpointType.MD) {
      return 2;
    }
    if (type === BreakpointType.LG || type === BreakpointType.XL) {
      return 3;
    }
    return 1;
  }

  /** 是否宽屏（lg 及以上）——决定是否启用分栏导航 */
  static isWide(type: BreakpointType): boolean {
    return type === BreakpointType.LG || type === BreakpointType.XL;
  }
}