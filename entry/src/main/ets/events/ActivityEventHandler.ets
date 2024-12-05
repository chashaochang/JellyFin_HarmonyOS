import { HMRouterMgr } from "@hadss/hmrouter";
import { common } from "@kit.AbilityKit";
import { PlayOptions } from "../player/interaction/PlayOptions";
import { ActivityEvent } from "./ActivityEvent";

export class ActivityEventHandler {
  eventHub: common.EventHub

  constructor(eventHub: common.EventHub) {
    this.eventHub = eventHub
  }

  subscribe() {
    this.eventHub.on(ActivityEvent.LaunchNativePlayer, (options: PlayOptions) => {
      HMRouterMgr.push({ pageUrl: '/Player', param: options })
    })
  }

  unsubscribe() {

  }
}