import { HMRouterMgr } from "@hadss/hmrouter";
import { common, Want } from "@kit.AbilityKit";
import { MainViewModel } from "../pages/MainViewModel";
import { PlayOptions } from "../player/interaction/PlayOptions";
import { OneMoreUtil } from "../utils/OneMoreUtil";
import { ActivityEventType } from "./ActivityEvent";
import { BusinessError } from "@kit.BasicServicesKit";
import { Constants } from "../utils/Constants";

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
      if (OneMoreUtil.isPc()) {
        let context = getContext() as common.UIAbilityContext;
        // 将Context对象传递过去
        let wantInfo: Want = {
          bundleName: context.abilityInfo.bundleName,
          abilityName: 'PlayerAbility',
          parameters: {
            options: options
          }
        };
        context.startAbility(wantInfo).then(() => {
          console.info("TAG", 'startAbility success.');
        }).catch((error: BusinessError) => {
          console.error("TAG", 'startAbility failed.');
        });
      } else {
        HMRouterMgr.push({ navigationId: Constants.NAVIGATION_ID, pageUrl: '/Player', param: options })
      }
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