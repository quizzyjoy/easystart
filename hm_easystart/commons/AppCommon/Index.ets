/**
 * @easystart/app-common 统一导出入口。
 *
 * 项目 Common：组合共享三库的"胶水"，含项目决策（装配顺序、生命周期配对）。
 * 判据：换一个 app 就不能原样用的装配逻辑，放这里；能用的放共享三库。
 * 依赖 foundation + platform，**不依赖 VitalUI**（手表可用）；零 @kit 导入。
 */
export { AppBootstrap } from './src/main/ets/bootstrap/AppBootstrap';
