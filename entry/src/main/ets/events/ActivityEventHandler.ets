import { HMRouterMgr } from "@hadss/hmrouter";
import { common } from "@kit.AbilityKit";
import { MainViewModel } from "../pages/MainViewModel";
import { PlayOptions } from "../player/interaction/PlayOptions";
import { ActivityEvents } from "./ActivityEvent";

export class ActivityEventHandler {
  eventHub: common.EventHub
  vm: MainViewModel

  constructor(eventHub: common.EventHub, vm: MainViewModel) {
    this.eventHub = eventHub
    this.vm = vm
  }

  subscribe() {
    // 订阅事件
    this.eventHub.on(ActivityEvents.CHANGE_FULLSCREEN, (isFullScreen: boolean) => {

    });
    this.eventHub.on(ActivityEvents.OPEN_URL, (uri: string) => {

    });
    this.eventHub.on(ActivityEvents.REQUEST_BLUETOOTH_PERMISSION, () => {

    });
    this.eventHub.on(ActivityEvents.EXIT_APP, () => {
      getContext().getApplicationContext().killAllProcesses()
    });
    this.eventHub.on(ActivityEvents.SELECT_SERVER, () => {
      this.vm.resetServer()
    })
    this.eventHub.on(ActivityEvents.LAUNCH_NATIVE_PLAYER, (options: PlayOptions) => {
      HMRouterMgr.push({ pageUrl: '/Player', param: options })
    })
  }

  unsubscribe() {
    this.eventHub.off(ActivityEvents.CHANGE_FULLSCREEN)
    this.eventHub.off(ActivityEvents.OPEN_URL)
    this.eventHub.off(ActivityEvents.REQUEST_BLUETOOTH_PERMISSION)
    this.eventHub.off(ActivityEvents.EXIT_APP)
    this.eventHub.off(ActivityEvents.LAUNCH_NATIVE_PLAYER)
  }
}