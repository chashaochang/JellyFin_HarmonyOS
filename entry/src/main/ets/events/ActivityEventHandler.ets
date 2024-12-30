import { HMRouterMgr } from "@hadss/hmrouter";
import { common } from "@kit.AbilityKit";
import { MainViewModel } from "../pages/MainViewModel";
import { PlayOptions } from "../player/interaction/PlayOptions";
import { ActivityEventType } from "./ActivityEvent";

export class ActivityEventHandler {
  eventHub: common.EventHub
  vm: MainViewModel

  constructor(eventHub: common.EventHub, vm: MainViewModel) {
    this.eventHub = eventHub
    this.vm = vm
  }

  subscribe() {
    // 订阅事件
    this.eventHub.on(ActivityEventType.ChangeFullscreen, (isFullScreen: boolean) => {

    });
    this.eventHub.on(ActivityEventType.OpenUrl, (uri: string) => {

    });
    this.eventHub.on(ActivityEventType.RequestBluetoothPermission, () => {

    });
    this.eventHub.on(ActivityEventType.ExitApp, () => {
      getContext().getApplicationContext().killAllProcesses()
    });
    this.eventHub.on(ActivityEventType.SelectServer, () => {
      this.vm.resetServer()
    })
    this.eventHub.on(ActivityEventType.LaunchNativePlayer, (options: PlayOptions) => {
      HMRouterMgr.push({ pageUrl: '/Player', param: options })
    })
  }

  unsubscribe() {
    this.eventHub.off(ActivityEventType.ChangeFullscreen)
    this.eventHub.off(ActivityEventType.OpenUrl)
    this.eventHub.off(ActivityEventType.RequestBluetoothPermission)
    this.eventHub.off(ActivityEventType.ExitApp)
    this.eventHub.off(ActivityEventType.LaunchNativePlayer)
  }
}