/**
 * 长列表数据源（`LazyForEach` 的必填契约）。
 *
 * 为什么不能直接给 `LazyForEach` 一个数组：
 * `LazyForEach` 需要知道"一共有多少条"和"第 N 条是什么"，并在数据变化时被回调通知。
 * 这三点由 `IDataSource` 表达，数组本身不满足。
 *
 * 【fork 提醒】`registerDataChangeListener` 必须真的把 listener 存下来，
 * 否则 `notifyDataReload()` 时列表不会刷新（这是最常见的"改数据不生效"原因）。
 */
export class SimpleDataSource implements IDataSource {
  private items: string[] = [];
  private listeners: DataChangeListener[] = [];

  /** 重建数据（内部按 index 生成，避免模板里手写 2000 行常量）。 */
  reset(count: number, prefix: string): void {
    const next: string[] = [];
    for (let i = 0; i < count; i++) {
      next.push(`${prefix} ${i + 1}`);
    }
    this.items = next;
    this.notifyReload();
  }

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): string {
    return this.items[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  /** 全量刷新（数据整体换掉时用）。 */
  notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }
}
