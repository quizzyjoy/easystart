import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'NetworkMonitor';

/** 网络状态（业务语义）。 */
export enum NetworkStatus {
  UNKNOWN = 'unknown',
  NONE = 'none',
  WIFI = 'wifi',
  CELLULAR = 'cellular',
  ETHERNET = 'ethernet'
}

/**
 * 网络状态监听。
 *
 * 使用 connection 模块级 API（getDefaultNet / getNetCapabilities）。
 * 需要在 entry module.json5 声明权限 ohos.permission.GET_NETWORK_INFO（system_grant）。
 *
 * 生命周期：init() 注册；destroy() 注销（与 init 成对，宿主 onWindowStageDestroy 中调用）。
 */
export class NetworkMonitor {
  private static netConnection: connection.NetConnection | null = null;
  private static status: NetworkStatus = NetworkStatus.UNKNOWN;
  private static listeners: Array<(status: NetworkStatus) => void> = [];

  private static onNetEvent(): void {
    NetworkMonitor.refresh();
  }

  /** 初始化（幂等）。 */
  static init(): void {
    if (NetworkMonitor.netConnection !== null) {
      return;
    }
    try {
      const net = connection.createNetConnection();
      net.on('netAvailable', NetworkMonitor.onNetEvent);
      net.on('netLost', NetworkMonitor.onNetEvent);
      net.on('netCapabilitiesChange', NetworkMonitor.onNetEvent);
      net.register((err: BusinessError) => {
        if (err) {
          Logger.error(DOMAIN, TAG, `register failed, code=${err.code}`);
        }
      });
      NetworkMonitor.netConnection = net;
      NetworkMonitor.refresh();
    } catch (err) {
      Logger.error(DOMAIN, TAG, `init failed: ${ErrorMapper.from(err, DOMAIN, 'init').toLog()}`);
    }
  }

  /**
   * 注销并释放（与 init 成对）。
   * 注：NetConnection 只提供 register/unregister（整连接级），
   * unregister 会取消该连接上的全部订阅，无逐事件 off。
   */
  static destroy(): void {
    const net = NetworkMonitor.netConnection;
    if (net === null) {
      return;
    }
    try {
      net.unregister((err: BusinessError) => {
        if (err) {
          Logger.warn(DOMAIN, TAG, `unregister failed, code=${err.code}`);
        }
      });
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `destroy failed: ${ErrorMapper.from(err, DOMAIN, 'destroy').toLog()}`);
    }
    NetworkMonitor.netConnection = null;
    NetworkMonitor.listeners = [];
    NetworkMonitor.status = NetworkStatus.UNKNOWN;
  }

  private static async refresh(): Promise<void> {
    try {
      const netHandle: connection.NetHandle = await connection.getDefaultNet();
      if (netHandle.netId === 0) {
        NetworkMonitor.publish(NetworkStatus.NONE);
        return;
      }
      const caps: connection.NetCapabilities = await connection.getNetCapabilities(netHandle);
      NetworkMonitor.publish(NetworkMonitor.mapBearer(caps));
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `refresh failed, treat as offline: ${ErrorMapper.from(err, DOMAIN, 'refresh').toLog()}`);
      NetworkMonitor.publish(NetworkStatus.NONE);
    }
  }

  private static mapBearer(caps: connection.NetCapabilities): NetworkStatus {
    const bearers: number[] = caps.bearerTypes;
    if (bearers.indexOf(connection.NetBearType.BEARER_WIFI) >= 0) {
      return NetworkStatus.WIFI;
    }
    if (bearers.indexOf(connection.NetBearType.BEARER_CELLULAR) >= 0) {
      return NetworkStatus.CELLULAR;
    }
    if (bearers.indexOf(connection.NetBearType.BEARER_ETHERNET) >= 0) {
      return NetworkStatus.ETHERNET;
    }
    return NetworkStatus.UNKNOWN;
  }

  private static publish(status: NetworkStatus): void {
    NetworkMonitor.status = status;
    NetworkMonitor.listeners.forEach((cb: (status: NetworkStatus) => void) => cb(status));
  }

  static getStatus(): NetworkStatus {
    return NetworkMonitor.status;
  }

  static isOnline(): boolean {
    return NetworkMonitor.status !== NetworkStatus.NONE && NetworkMonitor.status !== NetworkStatus.UNKNOWN;
  }

  static onChange(cb: (status: NetworkStatus) => void): void {
    if (NetworkMonitor.listeners.indexOf(cb) < 0) {
      NetworkMonitor.listeners.push(cb);
    }
  }

  static offChange(cb: (status: NetworkStatus) => void): void {
    NetworkMonitor.listeners = NetworkMonitor.listeners.filter(
      (item: (status: NetworkStatus) => void) => item !== cb);
  }
}
