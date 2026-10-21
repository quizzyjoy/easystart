import { ChartEntry, ChartSeries, ColorMath, CommonColorPicker, CommonLoading, FeedbackText, ListStatus, LoadingVariant, MotionEffects, MotionSpec, PieChart, QuarterRoseChart, RadarChart, RoseChart, SkeletonBlock, SizeLevel, StateContainer, UiThemeManager, ViewState } from '@quizzyjoy/vitalui';
import { ActionCard, ButtonVariant, CommonButton, CommonTag, TagTone } from '@easystart/app-component';
import {
  AppBadge,
  AppButtonGhostModifier,
  AppButtonPrimaryModifier,
  AppCapsuleSegment,
  AppCard,
  AppCheckbox,
  AppDialog,
  AppDividerModifier,
  AppEmptyState,
  AppGauge,
  AppIconButtonModifier,
  AppImageModifier,
  AppInputModifier,
  AppLoadingProgress,
  AppProgress,
  AppProgressDialog,
  AppProgressModifier,
  AppOverlay,
  AppRadio,
  AppRefresh,
  AppSearch,
  AppSelect,
  AppSheetContainer,
  AppSheetOptions,
  AppSlider,
  AppSnackBar,
  AppTabSegment,
  AppTextBodyModifier,
  AppTextColorModifier,
  AppTextHeadlineModifier,
  AppToggle,
  CommonDialog,
  CommonSearchBar,
  CommonToast,
  DialogAction,
  DialogSemantic,
  SegmentButtonV2Items
} from '@easystart/app-component';
import { AppFontSize, AppFontWeight, AppRadius, AppSize, AppSpacing, AppStroke, DesignToken, ResponsiveCase, ResponsiveOperator, ResponsiveRule, ResponsiveValueResolver } from '@quizzyjoy/foundation';
import { AppFoldStatus, BreakpointManager, ColorModeManager, DeviceManager, DeviceType, HoverStore, ShareHelper, UiMetrics, WindowAdapter } from '@quizzyjoy/platform';
import { ClipboardUtil } from '../util/ClipboardUtil';
import { FileDemoUtil } from '../util/FileDemoUtil';
import { PhotoPickUtil } from '../util/PhotoPickUtil';

/** 画廊 DSL 示例规则：first-match-wins（EQ / BETWEEN_CLOSED / IN 三种运算符各一）。 */
/** 状态与列表示例用：StateContainer 的四态（v3.64）。 */
class GalleryStateCase {
  readonly label: string;
  readonly state: ViewState;

  constructor(label: string, state: ViewState) {
    this.label = label;
    this.state = state;
  }
}

const GALLERY_STATE_CASES: GalleryStateCase[] = [
  new GalleryStateCase('content 内容', ViewState.CONTENT),
  new GalleryStateCase('loading 加载中', ViewState.LOADING),
  new GalleryStateCase('empty 空态', ViewState.EMPTY),
  new GalleryStateCase('error 错误态', ViewState.ERROR)
];

/** ListStatus 五态文案（RefreshList 状态机取值）。 */
const GALLERY_LIST_STATUSES: string[] = [
  ListStatus.IDLE,
  ListStatus.LOADING,
  ListStatus.SUCCESS,
  ListStatus.EMPTY,
  ListStatus.ERROR
];

const GALLERY_DSL_CASES: ResponsiveCase<string>[] = [
  new ResponsiveCase<string>(
    [new ResponsiveRule('isWide', ResponsiveOperator.EQ, true)],
    '宽屏 · 分栏'
  ),
  new ResponsiveCase<string>(
    [new ResponsiveRule('widthVp', ResponsiveOperator.BETWEEN_CLOSED, [600, 840])],
    '中屏 · 双列'
  ),
  new ResponsiveCase<string>(
    [new ResponsiveRule('breakpoint', ResponsiveOperator.IN, ['md'])],
    '中屏 · 单列'
  )
];

/** 文本轮播选择器示例数据（TextPickerDialog range，v3.29）。 */
const WHEEL_PICKER_RANGE: string[] = ['轻量', '标准', '专业', '旗舰', '定制'];

/**
 * 组件画廊视图：VitalUI / AppComponent 组件的一页式示例。
 *
 * v3.38 三级架构：本组件只渲染**一个分组**（groupId = basic/visual/platform/app，
 * 由 L2 分组页传入），或 groupId 为空时按分组顺序渲染四段的完整长页（TV / PC 入口用）。
 * 原「区块索引卡切换」已移除——分组选择上移到 L1 首页，组件内不再有分组态。
 *
 * 运行时主题通过 UiThemeManager 单例注入 accentColor；
 * 对话框使用 getPromptAction().openCustomDialog + 成员 @Builder（全局 @Builder 会闪退）。
 */
@ComponentV2
export struct ComponentGalleryView {
  /** 分组 id（basic / visual / platform / app）；空 = 四组按序全渲染（TV / PC 入口）。 */
  @Param groupId: string = '';
  @Local theme: UiThemeManager = UiThemeManager.getInstance();
  @Local keyword: string = '';
  @Local dialogId: number = -1;
  @Local demoColor: string = '#0A59F7';
  @Local breakpoint: BreakpointManager = BreakpointManager.getInstance();
  @Local fold: HoverStore = HoverStore.getInstance();
  @Local windowAdapter: WindowAdapter = WindowAdapter.getInstance();
  @Local colorMode: ColorModeManager = ColorModeManager.getInstance();
  private share: ShareHelper = ShareHelper.getInstance();
  /** AppSheet 示例显隐（V2：单向绑定 + onDisappear/onClose 回写，不用 $$ 双向语法） */
  @Local sheetShow: boolean = false;

  /** 主题化控件工厂示例态（选中/激活态随 theme.accentColor 彻底换肤）。 */
  @Local ctlSwitch: boolean = true;
  @Local ctlCheck: boolean = true;
  @Local ctlRadio: string = 'a';
  @Local ctlSlider: number = 40;
  @Local ctlTabIndex: number = 0;
  @Local ctlCapIndex: number = 1;
  @Local ctlTabItems: SegmentButtonV2Items =
    new SegmentButtonV2Items([{ text: '列表' }, { text: '网格' }, { text: '卡片' }]);
  @Local ctlCapItems: SegmentButtonV2Items =
    new SegmentButtonV2Items([{ text: '0.5x' }, { text: '1x' }, { text: '2x' }]);
  /** 扩展换肤组件示例态（v3.21：Select/Search/Refresh 受控值）。 */
  @Local ctlSelectIndex: number = 0;
  @Local ctlSearchValue: string = '';
  @Local ctlRefreshing: boolean = false;

  /** 动效示例态：方块尺寸切换（animateTo + MotionEffects.appearParam）。 */
  @Local motionExpanded: boolean = false;
  /** 动效示例态：列表项增删（ForEach + MotionEffects.listItem 过渡）。 */
  @Local motionItems: string[] = ['列表条目 1', '列表条目 2'];
  @Local motionSeq: number = 2;
  /** ColorMath 示例色（点击预设按钮切换，换算表随动）。 */
  @Local colorMathSeed: string = '#0A59F7';
  /** 选择器弹窗示例结果（v3.29；值一律在 Text 元素内直读，不经 @Builder 值参数中转——模板两次踩坑铁律）。 */
  @Local pickerDateText: string = '未选择';
  @Local pickerLunarText: string = '未选择';
  @Local pickerTimeText: string = '未选择';
  @Local pickerCalendarText: string = '未选择';
  @Local pickerWheelText: string = '未选择';
  /** PhotoViewPicker 选中 URI（Image 直渲；photoUris 永久授权，亦作 SaveButton 图源）。 */
  @Local photoUris: string[] = [];
  /** PasteButton 授权读取结果 / SaveButton 图库保存状态。 */
  @Local pastedText: string = '（暂无）';
  @Local gallerySaveText: string = '未保存';

  /** AppSnackBar 四档示例：语义时长与容器色由应用规范决定（AppComponent 落位注释）。 */
  private showSnack(kind: string): void {
    const uiContext: UIContext = this.getUIContext();
    if (kind === 'success') {
      AppSnackBar.success(uiContext, '已保存：操作成功完成');
    } else if (kind === 'warning') {
      AppSnackBar.warning(uiContext, '存储空间不足', '注意');
    } else if (kind === 'error') {
      AppSnackBar.error(uiContext, '网络请求失败，请稍后重试', '错误');
    } else {
          AppSnackBar.info(uiContext, '趣开发 应用级组件示例');
    }
  }

  aboutToAppear(): void {
    this.fold.attach();
  }

  aboutToDisappear(): void {
    this.fold.detach();
  }

  private bp(): string {
    return `${this.breakpoint.breakpoint}`;
  }

  private foldStatusLabel(): string {
    switch (this.fold.foldStatus) {
      case AppFoldStatus.EXPANDED:
        return '展开';
      case AppFoldStatus.FOLDED:
        return '折叠';
      case AppFoldStatus.HALF_FOLDED:
        return '半折叠（悬停态）';
      case AppFoldStatus.EXPANDED_WITH_SECOND_EXPANDED:
        return '双展开（三折叠）';
      case AppFoldStatus.FOLDED_WITH_SECOND_EXPANDED:
        return '折叠+副屏展开（三折叠）';
      default:
        return '未知';
    }
  }

  private showToast(): void {
    CommonToast.info('轻提示：统一时长与语义入口');
  }

  private showToastWarn(): void {
    CommonToast.warn('警告提示：2.5 秒后消失');
  }

  /** TV 门控（v3.29）：照片选择面板与触控安全组件面向手机/平板/2in1，TV 不渲染（编译仍四端通过）。 */
  private isTvDevice(): boolean {
    return DeviceManager.getDeviceType() === DeviceType.TV;
  }

  private formatDate(value: Date): string {
    const month: string = String(value.getMonth() + 1).padStart(2, '0');
    const day: string = String(value.getDate()).padStart(2, '0');
    return `${value.getFullYear()}-${month}-${day}`;
  }

  /** 日期选择弹窗（UIContext.showDatePickerDialog，替代已弃用全局 dialog；lunar 切农历面板）。 */
  private openDatePicker(lunar: boolean): void {
    this.getUIContext().showDatePickerDialog({
      selected: new Date(),
      lunar: lunar,
      onDateAccept: (value: Date): void => {
        if (lunar) {
          this.pickerLunarText = this.formatDate(value);
        } else {
          this.pickerDateText = this.formatDate(value);
        }
      }
    });
  }

  /** 时间选择弹窗（UIContext.showTimePickerDialog；useMilitaryTime 跟随系统 12 小时制示例）。 */
  private openTimePicker(): void {
    this.getUIContext().showTimePickerDialog({
      selected: new Date(),
      useMilitaryTime: false,
      onAccept: (value: TimePickerResult): void => {
        const hour: string = String(value.hour).padStart(2, '0');
        const minute: string = String(value.minute).padStart(2, '0');
        this.pickerTimeText = `${hour}:${minute}`;
      }
    });
  }

  /** 日历选择弹窗（全局 CalendarPickerDialog.show——UIContext 无对应方法，已对表 d.ts）。 */
  private openCalendarDialog(): void {
    CalendarPickerDialog.show({
      selected: new Date(),
      onAccept: (value: Date): void => {
        this.pickerCalendarText = this.formatDate(value);
      }
    });
  }

  /** 文本轮播选择弹窗（UIContext.showTextPickerDialog）。 */
  private openWheelPicker(): void {
    this.getUIContext().showTextPickerDialog({
      range: WHEEL_PICKER_RANGE,
      selected: 1,
      onAccept: (value: TextPickerResult): void => {
        this.pickerWheelText = `${value.value}（索引 ${value.index}）`;
      }
    });
  }

  /** PhotoViewPicker 选图（免权限 Picker 路线；取消/失败按未选择提示）。 */
  private pickPhoto(maxCount: number): void {
    PhotoPickUtil.selectPhoto(maxCount).then((uris: string[]): void => {
      this.photoUris = uris;
      if (uris.length === 0) {
        CommonToast.info('未选择图片（取消或图库为空）');
      }
    });
  }

  /** PasteButton 点击回调：SUCCESS 即获一次性剪贴板读取权（安全组件「点击即许可」）。 */
  private onPasteGranted(result: PasteButtonOnClickResult): void {
    if (result === PasteButtonOnClickResult.SUCCESS) {
      ClipboardUtil.readText().then((text: string): void => {
        this.pastedText = text.length > 0 ? text : '（剪贴板为空或非文本内容）';
      });
    } else {
      this.pastedText = '授权失败（安全组件样式不合规或被遮挡）';
    }
  }

  /** SaveButton 点击回调：SUCCESS 后在授权窗口（API20+ 1 分钟）内把已选图片存进系统图库。 */
  private onSaveToGallery(result: SaveButtonOnClickResult): void {
    if (result !== SaveButtonOnClickResult.SUCCESS) {
      this.gallerySaveText = '授权失败（组件样式不合规或被遮挡）';
      return;
    }
    if (this.photoUris.length === 0) {
      this.gallerySaveText = '待选图（先在上方选择照片）';
      CommonToast.info('请先在上方选择一张照片');
      return;
    }
    this.gallerySaveText = '保存中…';
    FileDemoUtil.saveImageToGallery(getContext(this), this.photoUris[0]).then((ok: boolean): void => {
      this.gallerySaveText = ok ? '已保存进系统图库' : '保存失败';
      if (ok) {
        CommonToast.success('已保存进系统图库');
      }
    });
  }

  private openDialog(): void {
    try {
      this.getUIContext().getPromptAction().openCustomDialog({
        builder: () => {
          this.dialogContent()
        },
        alignment: DialogAlignment.Center,
        autoCancel: true,
        isModal: true
      }).then((id: number) => {
        this.dialogId = id;
      }).catch(() => {
        CommonToast.error('对话框打开失败');
      });
    } catch (err) {
      CommonToast.error('对话框打开失败');
    }
  }

  private closeDialog(): void {
    if (this.dialogId >= 0) {
      try {
        this.getUIContext().getPromptAction().closeCustomDialog(this.dialogId);
      } catch (err) {
        // 关闭失败不阻断流程
      }
      this.dialogId = -1;
    }
  }

  @Builder
  dialogContent() {
    CommonDialog({
      title: '统一对话框',
      message: '标题 + 正文 + 操作区的标准结构，视觉与交互全应用一致。',
      vertical: true,
      actions: [
        new DialogAction('确认', ButtonVariant.PRIMARY, () => {
          this.closeDialog();
          CommonToast.success('已确认');
        }),
        new DialogAction('取消', ButtonVariant.TEXT, () => {
          this.closeDialog();
        })
      ]
    })
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize(AppFontSize.CAPTION)
      .fontColor($r('app.color.app_text_tertiary'))
      .width('100%')
      .margin({ top: AppSpacing.LG })
  }

  /** 色彩令牌色块（label 为短名，色值经 $r 资源随深浅色自动切换）。 */
  @Builder
  colorSwatch(label: string, color: ResourceColor) {
    Column({ space: AppSpacing.XXS }) {
      Column()
        .width(28)
        .height(28)
        .borderRadius(6)
        .backgroundColor(color)
        .border({ width: 1, color: $r('app.color.app_divider') })
      Text(label)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
    }
    .width(64)
    .alignItems(HorizontalAlign.Center)
  }

  /** AppSheet 示例内容（AppSheetContainer 标题栏 + 内容插槽 + @Event onClose 上抛）。 */
  @Builder
  demoSheetBuilder() {
    AppSheetContainer({
      sheetTitle: '应用级 Sheet 示例',
      contentBuilder: (): void => {
        this.demoSheetContent()
      },
      onClose: () => {
        this.sheetShow = false;
      }
    })
  }

  @Builder
  demoSheetContent() {
    Column({ space: AppSpacing.MD }) {
      Text('Sheet 圆角/底色/detents 由 AppSheetOptions 统一规范（elevated 底 + 双档高度）；标题栏与关闭钮为应用统一结构。')
        .fontSize(AppFontSize.BODY_SM)
        .fontColor($r('app.color.app_text_secondary'))
      Text('内容区由宿主注入——本示例来自 DemoFeature 画廊。')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }


  /** 操作与状态（v3.69：原「入口与基础」按内容拆成 act / input / feedback / overlay 四页）。 */
  @Builder
  groupAct() {
        this.sectionTitle('1 · 操作 · 按钮 ButtonVariant')
        Text('六种形态：主 / 次 / 文字 / 危险 / 加载中 / 已禁用；强调色由主题注入。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({ text: '主操作', variant: ButtonVariant.PRIMARY, accentColor: this.theme.accentColor, onAction: () => {
            CommonToast.info('主操作');
          } })
          CommonButton({ text: '次操作', variant: ButtonVariant.SECONDARY, accentColor: this.theme.accentColor, onAction: () => {
            CommonToast.info('次操作');
          } })
          CommonButton({ text: '文字', variant: ButtonVariant.TEXT, onAction: () => {
            CommonToast.info('文字按钮');
          } })
          CommonButton({ text: '危险', variant: ButtonVariant.DANGER, onAction: () => {
            this.showToastWarn();
          } })
          CommonButton({ text: '加载中', variant: ButtonVariant.PRIMARY, loading: true, accentColor: this.theme.accentColor })
          CommonButton({ text: '已禁用', variant: ButtonVariant.PRIMARY, disabled: true })
        }
        .width('100%')
        Text('说明：「加载中」「已禁用」两态点击无回调是设计如此，用于演示不可交互态。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_quaternary'))
          .width('100%')

        this.sectionTitle('2 · 状态 · 标签 TagTone')
        Text('五档语义色 + 可关闭态；品牌档跟随运行时强调色。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonTag({ text: '中性', tone: TagTone.NEUTRAL })
          CommonTag({ text: '品牌', tone: TagTone.BRAND, accentColor: this.theme.accentColor })
          CommonTag({ text: '成功', tone: TagTone.SUCCESS })
          CommonTag({ text: '警示', tone: TagTone.WARNING })
          CommonTag({ text: '危险', tone: TagTone.DANGER })
          CommonTag({
            text: '可关闭', tone: TagTone.NEUTRAL, closable: true,
            onClose: () => {
              CommonToast.info('标签已关闭');
            }
          })
        }
        .width('100%')

  }

  /** 输入与检索（v3.69）：搜索框受控 + 防抖，独立一页。 */
  @Builder
  groupInput() {
        this.sectionTitle('3 · 输入 · 搜索 CommonSearchBar')
        Text('受控 + 300ms 防抖；回车与取消分别回调，适合列表页顶部。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        CommonSearchBar({
          value: this.keyword,
          showCancel: true,
          onSearch: (keyword: string) => {
            this.keyword = keyword;
            CommonToast.info(`搜索：${keyword}`);
          },
          onCancel: () => {
            this.keyword = '';
          }
        })

  }

  /** 反馈与容器（v3.69）：轻提示 / 失败提示 / 确认对话框 + ActionCard。 */
  @Builder
  groupFeedback() {
        this.sectionTitle('4 · 反馈 · 轻提示与确认')
        Text('语义由触发方式决定：info 用于结果告知、warning 用于失败提示、对话框用于需要用户决策的确认。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({ text: '轻提示', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.showToast();
          } })
          CommonButton({ text: '失败提示', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.showToastWarn();
          } })
          CommonButton({ text: '确认对话框', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.openDialog();
          } })
        }
        .width('100%')

        this.sectionTitle('5 · 容器 · 卡片 ActionCard')
        Text('按压缩放反馈，标题/副标题两行排版，强调色跟随主题；列表与看板的通用容器。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        ActionCard({
          title: 'ActionCard',
          subtitle: '按压缩放反馈，颜色跟随令牌，支持运行时强调色注入',
          accentColor: this.theme.accentColor,
          onAction: () => {
            CommonToast.info('卡片点击');
          }
        })

  }

  /** 弹层与选择器（v3.69）：四类选择器 + Sheet。 */
  @Builder
  groupOverlay() {
        this.sectionTitle('6 · 弹层 · 选择器与 Sheet')
        Text('四类选择器与 Sheet 都走 UIContext 弹层 API（替代已弃用的全局 dialog）；结果回写到下方只读文本。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({ text: '日期', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.openDatePicker(false);
          } })
          CommonButton({ text: '日期（农历）', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.openDatePicker(true);
          } })
          CommonButton({ text: '时间', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.openTimePicker();
          } })
          CommonButton({ text: '日历', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.openCalendarDialog();
          } })
          CommonButton({ text: '文本轮播', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.openWheelPicker();
          } })
          CommonButton({ text: 'Sheet', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.sheetShow = true;
          } })
        }
        .width('100%')

        Column({ space: AppSpacing.XS }) {
          Text(`日期：${this.pickerDateText} · 农历：${this.pickerLunarText}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
          Text(`时间：${this.pickerTimeText} · 日历：${this.pickerCalendarText}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
          Text(`文本轮播：${this.pickerWheelText}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
  }

  /** 画廊分组区块：groupChart（v3.64 从 groupVisual 拆出，VitalUI 数据图表聚合页） */
  @Builder
  groupChart() {
        this.sectionTitle('ChartSeries / ChartEntry / ChartPalette / ChartStyle')
        Text('四个图表共用同一套数据模型：ChartSeries 带一组 ChartEntry，点击扇区/顶点回调 onSelect。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .margin({ bottom: AppSpacing.SM })

        this.sectionTitle('玫瑰 / 饼 / 季度玫瑰 / 雷达（Canvas 自绘，点击扇区/顶点）')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          Column() {
            RoseChart({
              data: new ChartSeries('玫瑰图', [
                new ChartEntry('A', 1), new ChartEntry('B', 2), new ChartEntry('C', 3),
                new ChartEntry('D', 2), new ChartEntry('E', 1), new ChartEntry('F', 3)
              ]),
              isDark: this.colorMode.isDarkNow(),
              onSelect: (entry: ChartEntry): void => {
                CommonToast.info(`玫瑰图选中：${entry.text}`);
              }
            })
          }
          .width('48%')

          Column() {
            PieChart({
              data: new ChartSeries('饼图', [
                new ChartEntry('一季度', 3), new ChartEntry('二季度', 2),
                new ChartEntry('三季度', 2), new ChartEntry('四季度', 1)
              ]),
              showDot: true,
              isDark: this.colorMode.isDarkNow(),
              onSelect: (entry: ChartEntry): void => {
                CommonToast.info(`饼图选中：${entry.text}`);
              }
            })
          }
          .width('48%')

          Column() {
            QuarterRoseChart({
              data: new ChartSeries('季度玫瑰', [
                new ChartEntry('春', 1), new ChartEntry('夏', 3),
                new ChartEntry('秋', 2), new ChartEntry('冬', 2)
              ]),
              isDark: this.colorMode.isDarkNow(),
              onSelect: (entry: ChartEntry): void => {
                CommonToast.info(`季度玫瑰选中：${entry.text}`);
              }
            })
          }
          .width('48%')

          Column() {
            RadarChart({
              data: new ChartSeries('能力雷达', [
                new ChartEntry('敏捷', 2), new ChartEntry('力量', 3), new ChartEntry('智慧', 3),
                new ChartEntry('耐力', 2), new ChartEntry('速度', 1)
              ]),
              isDark: this.colorMode.isDarkNow(),
              onSelect: (entry: ChartEntry): void => {
                CommonToast.info(`雷达选中：${entry.text}`);
              }
            })
          }
          .width('48%')
        }
        .width('100%')
  }

  /** 画廊分组区块：groupLoading（v3.64 从 groupVisual + groupBasic 合并，加载与骨架独立页） */
  @Builder
  groupLoading() {
        this.sectionTitle('Loading（四形态 · LoadingVariant）')
        Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, space: UiMetrics.uniformFlexSpace(AppSpacing.LG) }) {
          CommonLoading({ variant: LoadingVariant.SPINNER })
          CommonLoading({ variant: LoadingVariant.DOTS })
          CommonLoading({ variant: LoadingVariant.BAR })
          CommonLoading({ variant: LoadingVariant.SPINNER, sizeLevel: SizeLevel.SMALL, text: '加载中…' })
        }
        .width('100%')

        this.sectionTitle('骨架屏 SkeletonBlock（尺寸可调，占位不跳动）')
        Column({ space: AppSpacing.MD }) {
          SkeletonBlock({ heightValue: 24 })
          SkeletonBlock({ heightValue: 24 })
          SkeletonBlock({ widthValue: '55%', heightValue: 24 })
        }
        .width('100%')
  }

  /** 画廊分组区块：groupColor（v3.64 从 groupVisual 拆出，颜色选择器独立页） */
  @Builder
  groupColor() {
        this.sectionTitle('CommonColorPicker（HdsColorPicker 的 API 23 复刻）')
        CommonColorPicker({
          initialColor: this.demoColor,
          onColorSelected: (color: string): void => {
            this.demoColor = color;
          }
        })
        Text('选中色会实时下发到下面两个组件的 accentColor，用于验证「运行时换肤」链路。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          CommonButton({ text: '当前色', variant: ButtonVariant.PRIMARY, accentColor: this.demoColor })
          CommonTag({ text: '实时联动', tone: TagTone.BRAND, accentColor: this.demoColor })
        }
        .width('100%')

        this.colorMathBlock()
  }

  /** 画廊分组区块：groupState（v3.64 新增，VitalUI 状态与列表独立页） */
  @Builder
  groupState() {
        this.sectionTitle('StateContainer（四态容器）')
        Text('content 渲染子内容，loading / empty / error 由组件接管，error 态提供重试回调。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
          .margin({ bottom: AppSpacing.SM })

        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          ForEach(GALLERY_STATE_CASES, (item: GalleryStateCase) => {
            Column({ space: AppSpacing.XS }) {
              Text(item.label)
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_secondary'))
              Column() {
                StateContainer({
                  state: item.state,
                  emptyText: new FeedbackText('暂无数据', '换个条件试试', ''),
                  errorText: new FeedbackText('加载失败', '请检查网络后重试', '重试'),
                  onRetry: (): void => {
                    CommonToast.info('error 态：onRetry 已触发');
                  }
                }) {
                  Text('content 态：这里是业务内容')
                    .fontSize(AppFontSize.BODY_SM)
                    .fontColor($r('app.color.app_text_primary'))
                }
              }
              .width('100%')
              .height(140)
              .borderRadius(AppRadius.MD)
              .backgroundColor($r('app.color.app_bg_page_deep'))
            }
            .width('48%')
          }, (item: GalleryStateCase): string => item.label)
        }
        .width('100%')

        this.sectionTitle('RefreshList（下拉刷新 / 上拉加载状态机）')
        Text('ListStatus 五态：IDLE / LOADING / SUCCESS / EMPTY / ERROR；LOADING 且无数据时自动显示骨架，终态收起刷新指示器。完整交互示例见「模板能力 → 列表状态」。')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_tertiary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          ForEach(GALLERY_LIST_STATUSES, (status: string) => {
            CommonTag({ text: status, tone: TagTone.NEUTRAL })
          }, (status: string): string => status)
        }
        .width('100%')
  }

  /** 响应式与令牌（v3.69：原「平台能力与令牌」拆成两页）。 */
  @Builder
  groupResponsive() {
        this.sectionTitle('响应式 DSL（规则求值示例）')
        Column({ space: AppSpacing.XS }) {
          Text(`快照：bp=${this.breakpoint.breakpoint} · widthVp=${Math.round(this.breakpoint.windowWidthVp)} · isWide=${this.breakpoint.isWide()}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
          Text(`规则（EQ/BETWEEN/IN，first-match-wins）→ ${ResponsiveValueResolver.resolve<string>(GALLERY_DSL_CASES, this.breakpoint.snapshot(), '紧凑单列')}`)
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
          Text(`DesignToken.pagePadding 经 DSL → ${DesignToken.pagePadding(`${this.breakpoint.breakpoint}`)}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        this.sectionTitle('折叠态 / 折痕（HoverStore 实采，官方 WindowOrientation 模式）')
        Column({ space: AppSpacing.XS }) {
          Text(`可折叠：${this.fold.isFoldable ? '是' : '否（非折叠设备降级，数据恒 0）'}`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
          if (this.fold.isFoldable) {
            Text(`折叠形态：${this.foldStatusLabel()}`)
              .fontSize(AppFontSize.BODY_SM)
              .fontColor($r('app.color.app_text_primary'))
            Text(`折痕：上沿 ${this.fold.creaseTopVp}vp · 高度 ${this.fold.creaseHeightVp}vp`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
            Text('避让示意：内容区与折痕间插入等高占位（官方视频页模式）')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_tertiary'))
            Column() {
              Column()
                .width('100%')
                .height(40)
                .borderRadius(AppRadius.MD)
                .backgroundColor($r('app.color.app_bg_card'))
              Blank()
                .width('100%')
                .height(Math.min(this.fold.creaseHeightVp, 48))
                .borderRadius(AppRadius.XS)
                .backgroundColor(this.fold.creaseHeightVp > 0 ? this.theme.accentColor : Color.Transparent)
                .opacity(0.25)
              Column()
                .width('100%')
                .layoutWeight(1)
                .borderRadius(AppRadius.MD)
                .backgroundColor($r('app.color.app_bg_card'))
            }
            .width('100%')
            .height(140)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        this.sectionTitle('色彩令牌（49 设计令牌 + 20 图表色卡 · base/dark 双套 · 非主题色全 app 通用）')
        Text('背景 / 文本 / 填充 / 分割')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_quaternary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          this.colorSwatch('bg_page', $r('app.color.app_bg_page'))
          this.colorSwatch('bg_deep', $r('app.color.app_bg_page_deep'))
          this.colorSwatch('bg_card', $r('app.color.app_bg_card'))
          this.colorSwatch('bg_elev', $r('app.color.app_bg_elevated'))
          this.colorSwatch('bg_inv', $r('app.color.app_bg_inverse'))
          this.colorSwatch('bg_skel', $r('app.color.app_bg_scrim_holder'))
          this.colorSwatch('text_p', $r('app.color.app_text_primary'))
          this.colorSwatch('text_s', $r('app.color.app_text_secondary'))
          this.colorSwatch('text_t', $r('app.color.app_text_tertiary'))
          this.colorSwatch('text_q', $r('app.color.app_text_quaternary'))
          this.colorSwatch('on_brand', $r('app.color.app_text_on_brand'))
          this.colorSwatch('fill_sub', $r('app.color.app_fill_subtle'))
          this.colorSwatch('fill_mid', $r('app.color.app_fill_medium'))
          this.colorSwatch('divider', $r('app.color.app_divider'))
          this.colorSwatch('divider+', $r('app.color.app_divider_strong'))
          this.colorSwatch('skeleton', $r('app.color.app_skeleton'))
        }
        .width('100%')
        Text('反馈语义 × 容器 × 前景 / 交互态 / 遮罩 / 链接 / 禁用 / 阴影')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_quaternary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          this.colorSwatch('success', $r('app.color.app_success'))
          this.colorSwatch('success_c', $r('app.color.app_success_container'))
          this.colorSwatch('success_on', $r('app.color.app_success_on_container'))
          this.colorSwatch('warning', $r('app.color.app_warning'))
          this.colorSwatch('warning_c', $r('app.color.app_warning_container'))
          this.colorSwatch('warning_on', $r('app.color.app_warning_on_container'))
          this.colorSwatch('danger', $r('app.color.app_danger'))
          this.colorSwatch('danger_c', $r('app.color.app_danger_container'))
          this.colorSwatch('danger_on', $r('app.color.app_danger_on_container'))
          this.colorSwatch('info', $r('app.color.app_info'))
          this.colorSwatch('info_c', $r('app.color.app_info_container'))
          this.colorSwatch('info_on', $r('app.color.app_info_on_container'))
          this.colorSwatch('acc_pur', $r('app.color.app_accent_purple'))
          this.colorSwatch('acc_teal', $r('app.color.app_accent_teal'))
          this.colorSwatch('acc_pink', $r('app.color.app_accent_pink'))
          this.colorSwatch('hover', $r('app.color.app_state_hover'))
          this.colorSwatch('pressed', $r('app.color.app_state_pressed'))
          this.colorSwatch('focus', $r('app.color.app_state_focus'))
          this.colorSwatch('dragged', $r('app.color.app_state_dragged'))
          this.colorSwatch('scrim', $r('app.color.app_scrim'))
          this.colorSwatch('shadow', $r('app.color.app_shadow'))
          this.colorSwatch('link', $r('app.color.app_link'))
          this.colorSwatch('dis_bg', $r('app.color.app_button_disabled_bg'))
          this.colorSwatch('dis_fg', $r('app.color.app_button_disabled_fg'))
        }
        .width('100%')
        Text('灰阶 ramp（图表 / 插画 building block）')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_quaternary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          this.colorSwatch('gray_1', $r('app.color.app_gray_1'))
          this.colorSwatch('gray_2', $r('app.color.app_gray_2'))
          this.colorSwatch('gray_3', $r('app.color.app_gray_3'))
          this.colorSwatch('gray_4', $r('app.color.app_gray_4'))
          this.colorSwatch('gray_5', $r('app.color.app_gray_5'))
          this.colorSwatch('gray_6', $r('app.color.app_gray_6'))
        }
        .width('100%')
        Text('图表色卡 chart_c01~c20（v3.23 · 数据可视化分类色板，与 ChartPalette 常量轨逐位同值）')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_quaternary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          this.colorSwatch('c01', $r('app.color.chart_c01'))
          this.colorSwatch('c02', $r('app.color.chart_c02'))
          this.colorSwatch('c03', $r('app.color.chart_c03'))
          this.colorSwatch('c04', $r('app.color.chart_c04'))
          this.colorSwatch('c05', $r('app.color.chart_c05'))
          this.colorSwatch('c06', $r('app.color.chart_c06'))
          this.colorSwatch('c07', $r('app.color.chart_c07'))
          this.colorSwatch('c08', $r('app.color.chart_c08'))
          this.colorSwatch('c09', $r('app.color.chart_c09'))
          this.colorSwatch('c10', $r('app.color.chart_c10'))
          this.colorSwatch('c11', $r('app.color.chart_c11'))
          this.colorSwatch('c12', $r('app.color.chart_c12'))
          this.colorSwatch('c13', $r('app.color.chart_c13'))
          this.colorSwatch('c14', $r('app.color.chart_c14'))
          this.colorSwatch('c15', $r('app.color.chart_c15'))
          this.colorSwatch('c16', $r('app.color.chart_c16'))
          this.colorSwatch('c17', $r('app.color.chart_c17'))
          this.colorSwatch('c18', $r('app.color.chart_c18'))
          this.colorSwatch('c19', $r('app.color.chart_c19'))
          this.colorSwatch('c20', $r('app.color.chart_c20'))
        }
        .width('100%')
        Text('主题三件套（fork 换肤唯一改动点，qj_ 前缀）')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_quaternary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
          this.colorSwatch('brand', $r('app.color.qj_brand'))
          this.colorSwatch('brand_lt', $r('app.color.qj_brand_light'))
          this.colorSwatch('on_brand', $r('app.color.qj_on_brand'))
        }
        .width('100%')

  }

  /** 平台能力（v3.69）：沉浸避让 / 分享 / 选图 / 剪贴板。 */
  @Builder
  groupPlatform() {
        this.sectionTitle('沉浸式避让（WindowAdapter，v2.6 默认开）')
        Column({ space: AppSpacing.XS }) {
          Text(`沉浸：${this.windowAdapter.isImmersive ? '开' : '关'} · 顶避让 ${Math.round(this.windowAdapter.topAvoidVp)}vp · 底避让 ${Math.round(this.windowAdapter.bottomAvoidVp)}vp`)
            .fontSize(AppFontSize.BODY_SM)
            .fontColor($r('app.color.app_text_primary'))
          Text(`状态栏 ${Math.round(this.windowAdapter.statusBarHeightVp)}vp · 手势条 ${Math.round(this.windowAdapter.navIndicatorHeightVp)}vp · 挖孔 CUTOUT 取最大值`)
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
          Text('页面根 padding 避让，bg_page 底色延伸至系统栏后；系统栏字色随深浅色联动（切换可验证）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_tertiary'))
          CommonButton({
            text: '切换深浅色', variant: ButtonVariant.SECONDARY,
            onAction: () => {
              this.colorMode.toggle();
            }
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        this.sectionTitle('系统分享（ShareHelper，官方 Share Kit 机制封装）')
        Column({ space: AppSpacing.XS }) {
          Text('机制收敛 Platform（utd 推断 + fileUri + 面板容错 + 回调订阅）；分享内容由应用层注入')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_secondary'))
          Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
            CommonButton({
              text: '分享文本', variant: ButtonVariant.SECONDARY,
              onAction: () => {
                this.share.shareText('趣开发 分享示例：机制在框架层，策略在应用层。', {
                  title: '趣开发',
                  onPanelDismiss: () => {
                    CommonToast.info('分享面板已关闭');
                  }
                });
              }
            })
            CommonButton({
              text: '分享链接', variant: ButtonVariant.SECONDARY,
              onAction: () => {
                this.share.shareLink('https://developer.huawei.com/consumer/cn/', {
                  title: '华为开发者',
                  onShareCompleted: (targetName: string): void => {
                    CommonToast.info(`已分享至：${targetName}`);
                  }
                });
              }
            })
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        if (!this.isTvDevice()) {
          this.sectionTitle('照片选择（PhotoViewPicker，免权限 Picker 路线）')
          Column({ space: AppSpacing.XS }) {
            Text('官方推荐：拉起系统图库选择，无需申请媒体库权限（bpta-permission-application）；返回 URI 具永久读授权')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
            Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
              CommonButton({ text: '单选图片', variant: ButtonVariant.SECONDARY, onAction: () => {
                this.pickPhoto(1);
              } })
              CommonButton({ text: '多选（≤5）', variant: ButtonVariant.SECONDARY, onAction: () => {
                this.pickPhoto(5);
              } })
            }
            .width('100%')
            if (this.photoUris.length > 0) {
              Text(`已选 ${this.photoUris.length} 张，URI 示例：${this.photoUris[0]}`)
                .fontSize(AppFontSize.CAPTION)
                .fontColor($r('app.color.app_text_tertiary'))
              Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.XS) }) {
                ForEach(this.photoUris, (uri: string) => {
                  Image(uri)
                    .width(96)
                    .height(96)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                }, (uri: string) => uri)
              }
              .width('100%')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          this.sectionTitle('剪贴板与安全组件（复制 / 粘贴 / 保存，点击即许可）')
          Column({ space: AppSpacing.XS }) {
            Text('复制写入免权限；读取与保存走安全组件临时授权（免权限弹窗）；保存链 = 沙箱中转 + createImageAssetRequest + applyChanges')
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
            Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
              CommonButton({
                text: '复制示例文本', variant: ButtonVariant.SECONDARY,
                onAction: () => {
                  ClipboardUtil.copyText('趣开发 剪贴板示例文本').then((ok: boolean): void => {
                    if (ok) {
                      CommonToast.success('已复制，可点下方粘贴按钮读取');
                    } else {
                      CommonToast.error('复制失败');
                    }
                  });
                }
              })
            }
            .width('100%')
            PasteButton({ icon: PasteIconStyle.LINES, text: PasteDescription.PASTE, buttonType: ButtonType.Capsule })
              .onClick((event: ClickEvent, result: PasteButtonOnClickResult): void => {
                this.onPasteGranted(result);
              })
            Text(`粘贴读取：${this.pastedText}`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
            SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE_TO_GALLERY, buttonType: ButtonType.Capsule })
              .onClick((event: ClickEvent, result: SaveButtonOnClickResult): void => {
                this.onSaveToGallery(result);
              })
            Text(`图库保存：${this.gallerySaveText}（图源取上方照片选择的第一张）`)
              .fontSize(AppFontSize.CAPTION)
              .fontColor($r('app.color.app_text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
  }

  /** 画廊分组区块：groupApp（v3.26 自 build() 抽出，内容等价） */
  @Builder
  groupApp() {
        this.sectionTitle('应用级组件（AppComponent：应用交互规范载体，v3.4）')
        Text('判据：结构原语归框架层，应用交互规范归本应用——SnackBar 语义时长 / Dialog 危险语义 / Sheet 统一规格 / modifier 样式族')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .width('100%')
        Column({ space: AppSpacing.XS }) {
          Text('SnackBar 四档（官方 HdsSnackBar 封装，手表降级 Toast）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
            CommonButton({ text: '成功', variant: ButtonVariant.SECONDARY, onAction: () => {
              this.showSnack('success');
            } })
            CommonButton({ text: '警示', variant: ButtonVariant.SECONDARY, onAction: () => {
              this.showSnack('warning');
            } })
            CommonButton({ text: '错误', variant: ButtonVariant.SECONDARY, onAction: () => {
              this.showSnack('error');
            } })
            CommonButton({ text: '信息', variant: ButtonVariant.SECONDARY, onAction: () => {
              this.showSnack('info');
            } })
          }
          .width('100%')

          Text('AppDialog 两语义（组合 CommonDialog 原语 + 应用文案规范）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
            CommonButton({ text: '确认对话框', variant: ButtonVariant.SECONDARY, onAction: () => {
              AppDialog.open(this.getUIContext(), DialogSemantic.CONFIRM, '确认操作', '应用级标准确认对话框：文案与按钮语义由 AppComponent 统一。', () => {
                CommonToast.success('已确认');
              });
            } })
            CommonButton({ text: '危险操作', variant: ButtonVariant.SECONDARY, onAction: () => {
              AppDialog.open(this.getUIContext(), DialogSemantic.DANGER, '删除该项？', '此操作不可撤销。危险语义自动切换红色主按钮。', () => {
                CommonToast.info('已删除');
              });
            } })
          }
          .width('100%')

          Text('AppProgressDialog（进度弹窗：ComponentContent.update 数据交互）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          CommonButton({ text: '打开进度弹窗', variant: ButtonVariant.SECONDARY, onAction: () => {
            const ctx = this.getUIContext();
            AppProgressDialog.open(ctx, '上传中…', 0, false);
            let p: number = 0;
            const timer: number = setInterval(() => {
              p += 10;
              if (p >= 100) {
                clearInterval(timer);
                AppProgressDialog.close(ctx);
              } else {
                AppProgressDialog.update(p);
              }
            }, 300);
          } })

          Text('AppOverlay（OverlayManager 悬浮球：常驻悬浮 + 点击语义）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Flex({ wrap: FlexWrap.Wrap, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
            CommonButton({ text: '显示悬浮球', variant: ButtonVariant.SECONDARY, onAction: () => {
              AppOverlay.show(this.getUIContext(), $r('sys.symbol.gearshape_fill'), () => {
                CommonToast.info('悬浮球点击');
              }, { x: 16, y: 120 });
            } })
            CommonButton({ text: '关闭悬浮球', variant: ButtonVariant.SECONDARY, onAction: () => {
              AppOverlay.dismiss(this.getUIContext());
            } })
          }
          .width('100%')

          Text('AppSheet（bindSheet 选项工厂 + 标题栏容器）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          CommonButton({ text: '打开示例 Sheet', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.sheetShow = true;
          } })

          Text('modifier 样式族（原生组件 + attributeModifier，与 CommonButton 并存）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, space: UiMetrics.uniformFlexSpace(AppSpacing.SM) }) {
            Button('原生·主操作')
              .attributeModifier(new AppButtonPrimaryModifier())
            Button('原生·幽灵')
              .attributeModifier(new AppButtonGhostModifier())
            Text('原生 Text · Headline 档')
              .attributeModifier(new AppTextHeadlineModifier())
            Text('原生 Text · Body 档')
              .attributeModifier(new AppTextBodyModifier())
          }
          .width('100%')

          Text('主题化控件工厂（原生控件选中/激活态随运行时强调色彻底换肤；设置页 HDS 开关走 HDS 原生范式不在此列）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Column({ space: AppSpacing.MD }) {
            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, space: UiMetrics.uniformFlexSpace(AppSpacing.LG) }) {
              AppToggle({
                isOn: this.ctlSwitch,
                onChange: (on: boolean): void => {
                  this.ctlSwitch = on;
                }
              })
              AppCheckbox({
                label: '复选框',
                isChecked: this.ctlCheck,
                onChange: (on: boolean): void => {
                  this.ctlCheck = on;
                }
              })
              AppRadio({
                value: 'a',
                group: 'ctl_radio',
                checked: this.ctlRadio === 'a',
                label: '单选 A',
                onChange: (): void => {
                  this.ctlRadio = 'a';
                }
              })
              AppRadio({
                value: 'b',
                group: 'ctl_radio',
                checked: this.ctlRadio === 'b',
                label: '单选 B',
                onChange: (): void => {
                  this.ctlRadio = 'b';
                }
              })
            }
            .width('100%')

            AppTabSegment({
              items: this.ctlTabItems,
              selectedIndex: this.ctlTabIndex,
              onIndexChange: (index: number): void => {
                this.ctlTabIndex = index;
              }
            })
              .width('100%')
            AppCapsuleSegment({
              items: this.ctlCapItems,
              selectedIndex: this.ctlCapIndex,
              onIndexChange: (index: number): void => {
                this.ctlCapIndex = index;
              }
            })

            AppSlider({
              value: this.ctlSlider,
              min: 0,
              max: 100,
              step: 1,
              onChange: (value: number): void => {
                this.ctlSlider = value;
              }
            })
            Row({ space: AppSpacing.LG }) {
              AppProgress({ value: this.ctlSlider })
                .layoutWeight(1)
              AppProgress({ value: this.ctlSlider, type: ProgressType.Ring, strokeWidth: 8 })
                .width(56)
                .height(56)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Text('容器组件（AppCard / AppEmptyState，v3.21）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          AppCard() {
            Text('AppCard 卡片容器：app_bg_card 底 + XL 圆角 + LG 内边距')
              .fontSize(AppFontSize.BODY)
              .fontColor($r('app.color.app_text_secondary'))
          }
          AppEmptyState({
            title: 'AppEmptyState 空态',
            description: '图标 + 标题 + 说明 + 可选主操作',
            actionText: '刷新',
            onAction: () => {
              CommonToast.info('空态主操作：刷新');
            }
          })
          Text('另有「无操作空态」：不传 actionText 时只渲染图标 + 文案。')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))

          Text('modifier 新增（AppInputModifier / AppIconButtonModifier，v3.21）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Row({ space: AppSpacing.MD }) {
            TextInput({ text: '', placeholder: 'AppInputModifier 输入框' })
              .attributeModifier(new AppInputModifier())
              .layoutWeight(1)
            Button({ type: ButtonType.Circle }) {
              SymbolGlyph($r('sys.symbol.plus'))
                .fontSize(AppSize.ICON_SM)
                .fontColor([$r('app.color.qj_brand')])
            }
            .attributeModifier(new AppIconButtonModifier())
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text('简单换色 modifier（AppTextColorModifier / AppDividerModifier / AppBadgeModifier / AppImageModifier，v3.21）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Column({ space: AppSpacing.MD }) {
            Row({ space: AppSpacing.LG }) {
              Text('品牌色文字').attributeModifier(new AppTextColorModifier($r('app.color.qj_brand')))
              Text('危险色文字').attributeModifier(new AppTextColorModifier($r('app.color.app_danger')))
              Text('弱化文字').attributeModifier(new AppTextColorModifier($r('app.color.app_text_tertiary')))
            }
            .width('100%')

            Divider().attributeModifier(new AppDividerModifier())
            Divider().attributeModifier(new AppDividerModifier($r('app.color.qj_brand'), AppStroke.THIN))

            Row({ space: AppSpacing.LG }) {
              Progress({ value: 60, total: 100, type: ProgressType.Linear })
                .attributeModifier(new AppProgressModifier())
                .width(100)
              Progress({ value: 60, total: 100, type: ProgressType.Linear })
                .attributeModifier(new AppProgressModifier($r('app.color.app_success')))
                .width(100)
            }
            .width('100%')

            Image($r('app.media.background'))
              .attributeModifier(new AppImageModifier(AppRadius.XL))
              .width(160)
              .height(90)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Text('扩展换肤组件（AppLoadingProgress / AppGauge / AppSelect / AppSearch / AppRefresh，v3.21）')
            .fontSize(AppFontSize.CAPTION)
            .fontColor($r('app.color.app_text_quaternary'))
          Column({ space: AppSpacing.MD }) {
            Row({ space: AppSpacing.LG }) {
              AppLoadingProgress()
                .width(32)
                .height(32)
              AppGauge({ value: 60, min: 0, max: 100 })
                .width(80)
                .height(80)
            }
            .width('100%')

            Row({ space: AppSpacing.LG }) {
              AppBadge({ count: 5 }) {
                SymbolGlyph($r('sys.symbol.house_fill'))
                  .fontSize(AppSize.ICON_LG)
                  .fontColor([$r('app.color.app_text_secondary')])
              }
              AppBadge({ value: 'New', badgeColor: $r('app.color.qj_brand') }) {
                Text('品牌徽标')
                  .fontSize(AppFontSize.BODY)
                  .fontColor($r('app.color.app_text_primary'))
              }
            }
            .width('100%')

            AppSelect({
              options: ['选项 A', '选项 B', '选项 C'],
              selectedIndex: this.ctlSelectIndex,
              onSelect: (i: number): void => {
                this.ctlSelectIndex = i;
              }
            })

            AppSearch({
              value: this.ctlSearchValue,
              placeholder: '搜索（光标随强调色）',
              onChange: (v: string): void => {
                this.ctlSearchValue = v;
              }
            })
            .width('100%')

            Column() {
              AppRefresh({
                refreshing: this.ctlRefreshing,
                promptText: '下拉刷新',
                onRefreshing: (): void => {
                  setTimeout(() => {
                    this.ctlRefreshing = false;
                  }, 1500);
                }
              }) {
                List() {
                  ForEach(['内容行 1', '内容行 2', '内容行 3'], (item: string) => {
                    ListItem() {
                      Text(item)
                        .width('100%')
                        .padding(AppSpacing.MD)
                    }
                  }, (item: string) => item)
                }
                .width('100%')
                .height(160)
              }
            }
            .width('100%')
            .height(200)
            .backgroundColor($r('app.color.app_bg_page'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
  }

  /**
   * 动效常量标注行（名称 + 值 + 用途）。
   *
   * 【真机走查修正 v3.27.1】原为单行「固定宽度 160/150vp + layoutWeight」——在系统字号放大
   * （本机实测约 1.75×，适老化场景）时说明列被挤到 1 字宽、行高暴涨。改为两行式：
   * 第一行名称/值（比例列宽），第二行说明整行 —— 与字号无关地保持可读。
   */
  @Builder
  motionRow(name: string, value: string, desc: string) {
    Column({ space: AppSpacing.XXS }) {
      Row({ space: AppSpacing.XS }) {
        Text(name)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
        Text(value)
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.qj_brand'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(desc)
        .fontSize(AppFontSize.CAPTION_XS)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** v3.26 新增：动效规范（MotionSpec / MotionEffects）——此前有实现、无展示。 */
  @Builder
  motionBlock() {
    this.sectionTitle('动效规范（MotionSpec / MotionEffects）')
    Column({ space: AppSpacing.XS }) {
      Text('全工程动效语言的单一来源：页面与组件只允许引用 MotionEffects，禁止就地写 TransitionEffect / animateTo 字面量。')
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')
      this.motionRow('DURATION_FAST', `${MotionSpec.DURATION_FAST}ms`, '即时反馈：按钮按下 / 勾选')
      this.motionRow('DURATION_NORMAL', `${MotionSpec.DURATION_NORMAL}ms`, '常规动画：卡片展开 / 列表增删')
      this.motionRow('DURATION_SLOW', `${MotionSpec.DURATION_SLOW}ms`, '转场动画：页面切换 / 大范围布局变化')
      this.motionRow('DURATION_LOOP', `${MotionSpec.DURATION_LOOP}ms`, '循环动画：Loading 旋转 / 呼吸 / 扫掠')
      this.motionRow('CURVE_ENTER / EXIT', 'Friction / FastOutSlowIn', '标准缓动：进入 / 退出')
      this.motionRow('CURVE_SPRING / LIST', 'Sharp / Friction', '强调缓动（锐利收尾）/ 列表增删插值')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')

    Text('示例一：点击方块 → animateTo(MotionEffects.appearParam()) 切换尺寸（标准出现参数）')
      .fontSize(AppFontSize.CAPTION)
      .fontColor($r('app.color.app_text_tertiary'))
      .width('100%')
      .margin({ top: AppSpacing.MD })
    Column()
      .width(this.motionExpanded ? 200 : 72)
      .height(AppSize.TOUCH_STANDARD)
      .borderRadius(AppRadius.MD)
      .backgroundColor($r('app.color.qj_brand'))
      .onClick(() => {
        this.getUIContext().animateTo(MotionEffects.appearParam(), () => {
          this.motionExpanded = !this.motionExpanded;
        });
      })

    Text('示例二：列表项增删 → MotionEffects.listItem() 非对称透明度过渡')
      .fontSize(AppFontSize.CAPTION)
      .fontColor($r('app.color.app_text_tertiary'))
      .width('100%')
      .margin({ top: AppSpacing.MD })
    Row({ space: AppSpacing.SM }) {
      CommonButton({
        text: '添加条目', variant: ButtonVariant.SECONDARY, onAction: () => {
          this.getUIContext().animateTo(MotionEffects.appearParam(), () => {
            this.motionSeq = this.motionSeq + 1;
            this.motionItems.push(`列表条目 ${this.motionSeq}`);
          });
        }
      })
      CommonButton({
        text: '删除末项', variant: ButtonVariant.SECONDARY, onAction: () => {
          this.getUIContext().animateTo(MotionEffects.appearParam(), () => {
            if (this.motionItems.length > 0) {
              this.motionItems.pop();
            }
          });
        }
      })
    }
    .width('100%')
    Column({ space: AppSpacing.XS }) {
      ForEach(this.motionItems, (item: string) => {
        Text(item)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .width('100%')
          .padding(AppSpacing.MD)
          .borderRadius(AppRadius.MD)
          .backgroundColor($r('app.color.app_bg_card'))
          .transition(MotionEffects.listItem())
      }, (item: string) => item)
    }
    .width('100%')
    .margin({ top: AppSpacing.SM })
  }

  /** v3.26 新增：ColorMath 色彩数学（Canvas 常量轨的换算单一来源）。 */
  @Builder
  colorMathBlock() {
    this.sectionTitle('ColorMath 色彩数学（Canvas 常量轨的换算单一来源）')
    Column({ space: AppSpacing.XS }) {
      Text(`当前色：${this.colorMathSeed}（点下方预设切换；取色器 / 图表常量轨同源换算，禁止各组件自造）`)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_secondary'))
        .width('100%')
      Row({ space: AppSpacing.SM }) {
        CommonButton({
          text: '#0A59F7', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.colorMathSeed = '#0A59F7';
          }
        })
        CommonButton({
          text: '#0C8040', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.colorMathSeed = '#0C8040';
          }
        })
        CommonButton({
          text: '#C4365E', variant: ButtonVariant.SECONDARY, onAction: () => {
            this.colorMathSeed = '#C4365E';
          }
        })
      }
      .width('100%')

      // 【v3.26 实测】换算行必须直接把 @Computed 值读进各自的 Text——
      // 经 @Builder 值参数转手（this.colorMathRow(label, value)）会被按值捕获、不随状态刷新。
      Row({ space: AppSpacing.SM }) {
        Text('hexToRgb')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .width('36%')
        Text(this.rgbText)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: AppSpacing.SM }) {
        Text('rgbToHsl')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .width('36%')
        Text(this.hslText)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: AppSpacing.SM }) {
        Text('hexToHsv')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .width('36%')
        Text(this.hsvText)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: AppSpacing.SM }) {
        Text('hsvToHex 回算')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .width('36%')
        Text(this.hsvHexText)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: AppSpacing.SM }) {
        Text('往返偏差')
          .fontSize(AppFontSize.CAPTION)
          .fontColor($r('app.color.app_text_secondary'))
          .width('36%')
        Text(this.roundTripText)
          .fontSize(AppFontSize.BODY_SM)
          .fontColor($r('app.color.app_text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /** 全量长页的分组小标题（TV / PC 入口在 groupId 为空时使用；L2 单组页不渲染）。 */
  @Builder
  groupSectionHeader(title: string, desc: string) {
    Column({ space: AppSpacing.XXS }) {
      Text(title)
        .fontSize(AppFontSize.TITLE_SM)
        .fontWeight(AppFontWeight.MEDIUM)
        .fontColor($r('app.color.app_text_primary'))
        .width('100%')
      Text(desc)
        .fontSize(AppFontSize.CAPTION)
        .fontColor($r('app.color.app_text_tertiary'))
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: AppSpacing.XXXL, bottom: AppSpacing.SM })
  }

  /** 四组按序全渲染（TV / PC 入口；手机端走 L2 单组页，不经此处）。 */
  @Builder
  allGroups() {
    this.groupSectionHeader('操作与状态', '按钮六形态 + 标签五档语义')
    this.groupAct()
    this.groupSectionHeader('输入与检索', '搜索栏受控 + 300ms 防抖')
    this.groupInput()
    this.groupSectionHeader('反馈与容器', '轻提示 / 失败提示 / 确认对话框 + ActionCard')
    this.groupFeedback()
    this.groupSectionHeader('弹层与选择器', '四类选择器 + Sheet（统一走 UIContext）')
    this.groupOverlay()
    this.groupSectionHeader('响应式与令牌', '响应式 DSL / 折叠折痕 / 色彩令牌')
    this.groupResponsive()
    this.groupSectionHeader('平台能力', '沉浸避让 / 分享 / 选图 / 剪贴板')
    this.groupPlatform()
    this.groupSectionHeader('应用组件与动效', 'AppComponent 反馈族 / modifier 族 / 控件工厂 / 动效规范')
    this.groupApp()
    this.motionBlock()

    // v3.65：VitalUI（@quizzyjoy/vitalui 库内组件）单独成区，与上面的应用级示例分区展示
    this.groupSectionHeader('VitalUI 组件 · 数据图表', '四图表聚合：玫瑰 / 饼 / 季度玫瑰 / 雷达（Canvas 自绘）')
    this.groupChart()
    this.groupSectionHeader('VitalUI 组件 · 加载与骨架', 'CommonLoading 四形态 + SkeletonBlock')
    this.groupLoading()
    this.groupSectionHeader('VitalUI 组件 · 颜色选择器', 'CommonColorPicker + ColorMath 色彩数学')
    this.groupColor()
    this.groupSectionHeader('VitalUI 组件 · 状态与列表', 'StateContainer 四态 + RefreshList 状态机')
    this.groupState()
  }

  /**
   * 单组渲染（L2 分组页）：groupId 决定区块。
   * 动效规范与色彩数学并入「应用组件与动效」组（原独立「动效与工具」区块只由索引卡进入）。
   */
  @Builder
  groupBody() {
    if (this.groupId === 'act') {
      this.groupAct()
    } else if (this.groupId === 'input') {
      this.groupInput()
    } else if (this.groupId === 'feedback') {
      this.groupFeedback()
    } else if (this.groupId === 'overlay') {
      this.groupOverlay()
    } else if (this.groupId === 'responsive') {
      this.groupResponsive()
    } else if (this.groupId === 'platform') {
      this.groupPlatform()
    } else if (this.groupId === 'app') {
      this.groupApp()
      this.motionBlock()
    } else if (this.groupId === 'chart') {
      this.groupChart()
    } else if (this.groupId === 'loading') {
      this.groupLoading()
    } else if (this.groupId === 'color') {
      this.groupColor()
    } else if (this.groupId === 'state') {
      this.groupState()
    } else if (this.groupId === '') {
      this.allGroups()
    } else {
      this.groupAct()
    }
  }

  /**
   * ColorMath 示例：hex → RGB 分量。
   * 用 @Computed 而非普通方法——普通方法的取值不在 ArkUI 依赖追踪链上，
   * 切换 colorMathSeed 时不会触发这些文本重算（v3.26 实测踩坑）。
   */
  @Computed
  get rgbText(): string {
    const rgb = ColorMath.hexToRgb(this.colorMathSeed);
    return rgb === undefined ? '非法色值' : `R ${rgb.r} / G ${rgb.g} / B ${rgb.b}`;
  }

  /** ColorMath 示例：hex → HSL。 */
  @Computed
  get hslText(): string {
    const rgb = ColorMath.hexToRgb(this.colorMathSeed);
    if (rgb === undefined) {
      return '非法色值';
    }
    const hsl = ColorMath.rgbToHsl(rgb.r, rgb.g, rgb.b);
    return hsl === undefined
      ? '换算失败'
      : `H ${Math.round(hsl.h)}° / S ${Math.round(hsl.s)}% / L ${Math.round(hsl.l)}%`;
  }

  /** ColorMath 示例：hex → HSV。 */
  @Computed
  get hsvText(): string {
    const hsv = ColorMath.hexToHsv(this.colorMathSeed);
    return hsv === undefined
      ? '换算失败'
      : `H ${Math.round(hsv.h)}° / S ${Math.round(hsv.s)}% / V ${Math.round(hsv.v)}%`;
  }

  /** ColorMath 示例：HSV → hex 回算值。 */
  @Computed
  get hsvHexText(): string {
    const hsv = ColorMath.hexToHsv(this.colorMathSeed);
    return hsv === undefined ? '换算失败' : ColorMath.hsvToHex(hsv.h, hsv.s, hsv.v);
  }

  /**
   * ColorMath 示例：hex → HSV → hex 的往返偏差。
   *
   * HSV 换算在 8-bit 整数域**非严格无损**（如 #C4365E 往返为 #c4375f，单通道偏 1），
   * 故以「最大通道偏差」表达而非断言"一致"——这是色卡/取色器可接受的量化误差。
   */
  @Computed
  get roundTripText(): string {
    const hsv = ColorMath.hexToHsv(this.colorMathSeed);
    const srcRgb = ColorMath.hexToRgb(this.colorMathSeed);
    if (hsv === undefined || srcRgb === undefined) {
      return '换算失败';
    }
    const back: string = ColorMath.hsvToHex(hsv.h, hsv.s, hsv.v);
    const backRgb = ColorMath.hexToRgb(back);
    if (backRgb === undefined) {
      return '换算失败';
    }
    const delta: number = Math.max(
      Math.abs(backRgb.r - srcRgb.r),
      Math.abs(backRgb.g - srcRgb.g),
      Math.abs(backRgb.b - srcRgb.b)
    );
    return delta === 0
      ? '往返一致（严格无损）'
      : `往返 ${back}（最大通道偏差 ${delta}/255 · HSV 往返非严格无损）`;
  }

  build() {
    Scroll() {
      // 响应式令牌范式（ListStateView 同构）：外层居中，内层限宽 + 断点内边距
      Column() {
      Column() {
        this.groupBody()
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .constraintSize({ maxWidth: DesignToken.contentMaxWidth(this.bp()) })
      .padding({
        left: DesignToken.pagePadding(this.bp()),
        right: DesignToken.pagePadding(this.bp()),
        bottom: DesignToken.tabPageBottomPadding(this.bp(), this.windowAdapter.bottomAvoidVp)
      })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg_page'))
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    // v3.70：Sheet 改挂页面根节点。原先挂在 groupApp 末尾，拆成七页后
    // 只有「应用组件与动效」页能弹，弹层页点 Sheet 无反应（sheet 链断）。
    .bindSheet(this.sheetShow, this.demoSheetBuilder(), AppSheetOptions.bind({
      onDisappear: () => {
        this.sheetShow = false;
      }
    }))
  }
}
