import { AbilityStage } from "@kit.AbilityKit"
import { RedPlayerConfigBuilder, RedPlayerInitManager, RedPlayerPreload } from "@rte-xhs/redplayer"
import LoggerImpl from "./entryability/LoggerImpl"

export default class MainAbilityStage extends AbilityStage {
  onCreate() {
    let configBuilder = new RedPlayerConfigBuilder()
    configBuilder.cachePath = this.context.cacheDir + '/redplayer'
    configBuilder.logger = new LoggerImpl()
    RedPlayerInitManager.initPlayer(configBuilder)
    RedPlayerPreload.globalInit(this.context.cacheDir + '/redplayer', 20, 4, 0)
  }
}