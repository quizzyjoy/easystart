import { deviceInfo } from '@kit.BasicServicesKit';
import { BreakpointType } from '../breakpoint/BreakpointConstants';

/**
 * 设备形态：把「设备物理形态」与「窗口尺寸形态」解耦。
 * 业务侧判断布局时优先使用 getFormFactor()，而非直接判断 deviceType。
 */
export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  TWO_IN_ONE = '2in1',
  TV = 'tv',
  WEARABLE = 'wearable',
  CAR = 'car',
  UNKNOWN = 'unknown'
}

/** 业务布局形态（跨设备统一语义）。 */
export enum FormFactor {
  COMPACT = 'compact',
  MEDIUM = 'medium',
  EXPANDED = 'expanded'
}

export class DeviceManager {
  private static cachedType: DeviceType | undefined = undefined;

  static getDeviceType(): DeviceType {
    if (DeviceManager.cachedType !== undefined) {
      return DeviceManager.cachedType;
    }
    let raw: string = '';
    try {
      raw = deviceInfo.deviceType;
    } catch (err) {
      raw = '';
    }
    // 注意：ArkTS 禁止把 class/enum 当对象遍历，故用显式分支
    let matched: DeviceType = DeviceType.UNKNOWN;
    if (raw === DeviceType.PHONE) {
      matched = DeviceType.PHONE;
    } else if (raw === DeviceType.TABLET) {
      matched = DeviceType.TABLET;
    } else if (raw === DeviceType.TWO_IN_ONE) {
      matched = DeviceType.TWO_IN_ONE;
    } else if (raw === DeviceType.TV) {
      matched = DeviceType.TV;
    } else if (raw === DeviceType.WEARABLE) {
      matched = DeviceType.WEARABLE;
    } else if (raw === DeviceType.CAR) {
      matched = DeviceType.CAR;
    }
    DeviceManager.cachedType = matched;
    return matched;
  }

  static isTV(): boolean {
    return DeviceManager.getDeviceType() === DeviceType.TV;
  }

  static isWearable(): boolean {
    return DeviceManager.getDeviceType() === DeviceType.WEARABLE;
  }

  static is2in1(): boolean {
    return DeviceManager.getDeviceType() === DeviceType.TWO_IN_ONE;
  }

  static isTablet(): boolean {
    return DeviceManager.getDeviceType() === DeviceType.TABLET;
  }

  static isPhone(): boolean {
    return DeviceManager.getDeviceType() === DeviceType.PHONE;
  }

  /** 由「设备类型 + 断点 + 横竖屏」推导统一布局形态。 */
  static getFormFactor(breakpoint: BreakpointType, isLandscape: boolean): FormFactor {
    const type: DeviceType = DeviceManager.getDeviceType();
    if (type === DeviceType.WEARABLE || breakpoint === BreakpointType.XS) {
      return FormFactor.COMPACT;
    }
    if (type === DeviceType.TWO_IN_ONE || type === DeviceType.TV) {
      return FormFactor.EXPANDED;
    }
    if (breakpoint === BreakpointType.XL) {
      return FormFactor.EXPANDED;
    }
    if (breakpoint === BreakpointType.LG) {
      return type === DeviceType.TABLET && isLandscape ? FormFactor.EXPANDED : FormFactor.MEDIUM;
    }
    if (breakpoint === BreakpointType.MD && type === DeviceType.TABLET && isLandscape) {
      return FormFactor.EXPANDED;
    }
    return FormFactor.MEDIUM;
  }
}
