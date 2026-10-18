import { fileIo } from '@kit.CoreFileKit';
import type { common } from '@kit.AbilityKit';
import { Logger } from '@quizzyjoy/foundation';
import { ErrorMapper } from '../error/ErrorMapper';

const DOMAIN: string = 'platform';
const TAG: string = 'CacheManager';

/**
 * 应用缓存目录管理（设置页「清除缓存」配套）。
 *
 * 作用域铁律：只统计 / 删除 `context.cacheDir`（应用沙箱缓存目录）内的条目，
 * **永不触碰** filesDir / preferences / 数据库 / 外部目录。
 * cacheDir 根目录本身保留，只清空其内容（系统随时可能回收缓存，重建无副作用）。
 *
 * 单项失败（文件被占用 / 权限）跳过并继续，最后由调用方重新统计大小；
 * 整体失败内部降级记日志，不向上抛。
 */
export class CacheManager {
  /**
   * 统计缓存目录总大小（字节）。任何失败返回 0，不抛异常。
   * UI 层自行格式化为 KB / MB。
   */
  static async getCacheSizeBytes(context: common.Context): Promise<number> {
    const dir: string = context.cacheDir;
    try {
      const size: number = CacheManager.sumDir(dir);
      Logger.info(DOMAIN, TAG, `cache size: ${size} bytes at ${dir}`);
      return size;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `getCacheSize failed: ${ErrorMapper.from(err, DOMAIN, 'stat').toLog()}`);
      return 0;
    }
  }

  /**
   * 清空缓存目录内容（保留 cacheDir 根目录）。
   * @returns 实际删除失败的条目数（0 表示全部成功）
   */
  static async clearCache(context: common.Context): Promise<number> {
    const dir: string = context.cacheDir;
    let failed: number = 0;
    try {
      const names: string[] = fileIo.listFileSync(dir);
      for (const name of names) {
        failed += CacheManager.removeAny(`${dir}/${name}`);
      }
      Logger.info(DOMAIN, TAG, `clearCache done, failed=${failed}`);
    } catch (err) {
      Logger.error(DOMAIN, TAG, `clearCache failed: ${ErrorMapper.from(err, DOMAIN, 'clear').toLog()}`);
      failed += 1;
    }
    return failed;
  }

  /** 递归统计目录字节数；单项不可读时按 0 处理。 */
  private static sumDir(dir: string): number {
    let total: number = 0;
    let names: string[] = [];
    try {
      names = fileIo.listFileSync(dir);
    } catch (err) {
      return 0;
    }
    for (const name of names) {
      const path: string = `${dir}/${name}`;
      try {
        const stat: fileIo.Stat = fileIo.statSync(path);
        if (stat.isDirectory()) {
          total += CacheManager.sumDir(path);
        } else {
          total += stat.size;
        }
      } catch (err) {
        // 单项统计失败：忽略，不影响整体
      }
    }
    return total;
  }

  /**
   * 递归删除任意文件或目录（先清空子项再 rmdir）。
   * 同步 IO 全部可能抛异常，统一在本函数内捕获；@returns 该子树删除失败条目数。
   */
  private static removeAny(path: string): number {
    try {
      const stat: fileIo.Stat = fileIo.statSync(path);
      if (stat.isDirectory()) {
        let failed: number = 0;
        const names: string[] = fileIo.listFileSync(path);
        for (const name of names) {
          failed += CacheManager.removeAny(`${path}/${name}`);
        }
        fileIo.rmdirSync(path);
        return failed;
      }
      fileIo.unlinkSync(path);
      return 0;
    } catch (err) {
      Logger.warn(DOMAIN, TAG, `remove failed: ${path} ${ErrorMapper.from(err, DOMAIN, 'remove').toLog()}`);
      return 1;
    }
  }
}
