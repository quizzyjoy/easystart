import { AppError, Logger, Result } from '@quizzyjoy/foundation';
import { ErrorMapper } from '@quizzyjoy/platform';

const DOMAIN: string = 'demo';
const TAG: string = 'HomeRepository';

/**
 * 模板能力目录项的目标（导航语义载荷，v3.38 收口为三项）。
 *
 * feature 不感知路由名：本枚举由**入口装配层** switch 映射到 `AppRoute` 常量后再 push
 * （与 DemoFeature 的 `DemoSample` 同一范式），feature 侧零 RouterManager import；
 * 枚举到路由名的映射唯一出处在 product 入口层。
 *
 * v3.38：场景子页（令牌 / 反馈 / 看板 / 表单 / 列表 / 搜索）已统一收口到示例 Tab 首页，
 * 本目录只留「模板已装好的基础设施」三项，避免同一入口在首页与目录各一份。
 */
export enum HomeTarget {
  /** 设置中心子页 */
  SETTINGS,
  /** 详情页范式（push 本项**对象**，示例「列表 → 详情」链路） */
  DETAIL,
  /** 账号登录页范式（v3.40 从设置域迁出，push 独立页） */
  ACCOUNT_SAMPLE,
  /** 设备能力（入口切换到底部「开发工具」Tab，不 push） */
  DEVICE
}

/**
 * 首页目录项模型（模板能力目录：一行一卡，点击由入口按 target 分发）。
 *
 * v3.26 起首页由「One..Four 占位卡」改为**能力目录**：卡片即模板能力入口，
 * fork 后把本文件的数据换成真实接口（或真实业务条目）即可，视图与装配无需改动。
 */
export class HomeItem {
  id: string = '';
  title: string = '';
  description: string = '';
  /** 点击目标（入口 switch 分发；默认落在详情页范式）。 */
  target: HomeTarget = HomeTarget.DETAIL;
  /** 详情页元信息标签（仅 DETAIL 项使用；HomeDetailView 对空数组安全）。 */
  tags: string[] = [];
  /** 详情页正文段落（仅 DETAIL 项使用）。 */
  body: string[] = [];

  constructor(id: string, title: string, description: string, target: HomeTarget) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.target = target;
  }

  /** 链式设置详情标签（目录数据声明更紧凑）。 */
  withTags(tags: string[]): HomeItem {
    this.tags = tags;
    return this;
  }

  /** 链式设置详情正文段落。 */
  withBody(body: string[]): HomeItem {
    this.body = body;
    return this;
  }
}

/**
 * 数据仓库（Repository）。
 *
 * 三条约定：
 * 1. feature 内的数据获取一律走 Repository，View / ViewModel 不得直接发请求。
 * 2. 返回值用 Result<T> 表达"可预期的失败"，只有意外才 throw。
 * 3. 边界处（网络 / 存储 / 系统 API）统一用 ErrorMapper 把系统异常转成 AppError。
 *
 * 当前为模板能力目录（占位实现），接入真实接口时只替换本文件。
 */
export class HomeRepository {
  async fetchItems(): Promise<Result<HomeItem[]>> {
    Logger.info(DOMAIN, TAG, 'fetchItems start (placeholder)');
    try {
      const items: HomeItem[] = [
        new HomeItem('1', '设置中心',
          '显示模式 / 强调色 / 语言 / 字号 / 触感 / 屏幕方向 / 清缓存 / 关于与政策许可',
          HomeTarget.SETTINGS),
        new HomeItem('2', '详情页范式',
          '「列表 → 详情」标准骨架：徽标 + 元信息 + 正文 + 操作条（宽屏落 Split 右栏）',
          HomeTarget.DETAIL)
          .withTags(['详情范式', 'Split 适配', '分享接入'])
          .withBody([
            '本页是「列表 → 详情」标准范式：从能力目录进入，宽屏（lg 以上）由 HdsNavigation 的 Split 模式自动落到右栏，窄屏为整页 push。',
            '结构自上而下：品牌徽标 + 标题副标题 → 元信息标签行 → 正文段落 → 底部操作条（分享 / 收藏）。',
            '导航纪律：detail 视图不感知路由（不 import RouterManager），点击经 @Event 上抛给入口装配层；分享机制由 Platform 的 ShareHelper 承担，页面只决定「分享什么」。'
          ]),
        new HomeItem('3', '账号登录页范式',
          '手机号 + 验证码 / 第三方登录 / 注销入口的完整登录页骨架（预览态，未接账号体系）',
          HomeTarget.ACCOUNT_SAMPLE)
      ];
      if (items.length === 0) {
        // 可预期失败：属于正常业务分支，用 Result 返回而非抛异常
        return Result.fail<HomeItem[]>(AppError.expected(1, 'empty data set', DOMAIN));
      }
      Logger.info(DOMAIN, TAG, `fetchItems done, size=${items.length}`);
      return Result.ok<HomeItem[]>(items);
    } catch (err) {
      // 意外失败：映射成 AppError 后仍以 Result 交给上层，由上层决定 UI 表现
      const appError: AppError = ErrorMapper.from(err, DOMAIN, 'fetchItems');
      return Result.fail<HomeItem[]>(appError);
    }
  }
}
