import { common } from "@kit.AbilityKit";
import { PlayOptions } from "../player/interaction/PlayOptions";
import { ActivityEvent } from "./ActivityEvent";

export class ActivityEventHandler {
  eventHub: common.EventHub

  constructor(eventHub: common.EventHub) {
    this.eventHub = eventHub
  }

  subscribe(pathStack: NavPathStack) {
    this.eventHub.on(ActivityEvent.LaunchNativePlayer, (options: PlayOptions) => {
      pathStack.pushPathByName('PlayerView', options)
    })
  }

  unsubscribe() {

  }
}