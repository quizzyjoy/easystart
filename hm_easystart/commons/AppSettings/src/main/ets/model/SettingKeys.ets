/**
 * 设置项持久化键（v3.18 起指向契约包单一真相源）。
 *
 * 键名 / 字号系数 / 强调色校验的真相源已下沉至 @easystart/app-preferences
 * （PreferenceKeys / FontSizeScale）。本文件为 AppSettings 域保留 SettingKeys
 * 命名别名，避免域内调用点大面积改名；键名语义见 PreferenceKeys 头注。
 * AppCommon 的 AppBootstrap 恢复链直接引用 PreferenceKeys，两处自此共享同一份常量。
 */
export { PreferenceKeys as SettingKeys } from '@easystart/app-preferences';

