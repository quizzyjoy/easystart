/**
 * 开发工具目录数据（v3.41）。
 *
 * 一项一卡：已实现的工具 status = READY（点击进对应面板），规划中的工具
 * status = PLANNED（卡片灰显 + 「待实现」角标，点击给出提示）。
 *
 * 规划项的 sourceUrl 指向参考实现，统一登记在 docs/权威参考与开源项目盘点.md §6
 * （开源备忘录）：实现新工具时先查备忘录再动代码，避免重复调研。
 */
export enum DevToolStatus {
  /** 已实现，可点击进入 */
  READY,
  /** 待实现（卡片灰显 + 角标） */
  PLANNED
}

/** 卡片图标：不直接存 Resource（不能动态拼 $r），由视图按 key 映射为 sys.symbol。 */
export enum DevToolSymbol {
  DISPLAY,
  PALETTE,
  GRID
}

export class DevToolItem {
  id: string = '';
  title: string = '';
  desc: string = '';
  symbol: DevToolSymbol = DevToolSymbol.DISPLAY;
  status: DevToolStatus = DevToolStatus.READY;
  /** 参考实现地址（仅 PLANNED 项填写；同时登记在开源备忘录） */
  sourceUrl: string = '';

  constructor(id: string, title: string, desc: string, symbol: DevToolSymbol, status: DevToolStatus,
    sourceUrl: string = '') {
    this.id = id;
    this.title = title;
    this.desc = desc;
    this.symbol = symbol;
    this.status = status;
    this.sourceUrl = sourceUrl;
  }
}

/**
 * 开发工具清单。
 *
 * 排序约定：已实现的排前面，待实现的按调研优先级排后面。
 */
export function devTools(): DevToolItem[] {
  const ready: DevToolItem[] = [
    new DevToolItem('device', '设备能力检测', '断点 / 设备形态 / 窗口适配 / 网络 / 国际化',
      DevToolSymbol.DISPLAY, DevToolStatus.READY)
  ];
  const planned: DevToolItem[] = [
    new DevToolItem('uidesign', '图标处理 Kit',
      '图标合成 / 剪切 / 缩放 / 描边：分层与单层图标效果',
      DevToolSymbol.PALETTE, DevToolStatus.PLANNED,
      'https://gitcode.com/HarmonyOS_Samples/uidesign-kit_-sample-code_-arkts'),
    new DevToolItem('transitions', '转场动效合集',
      '基础组件 + 通用属性 + 显式动效的多类转场案例',
      DevToolSymbol.GRID, DevToolStatus.PLANNED,
      'https://gitcode.com/HarmonyOS_Samples/transitions-collection')
  ];
  return ready.concat(planned);
}
