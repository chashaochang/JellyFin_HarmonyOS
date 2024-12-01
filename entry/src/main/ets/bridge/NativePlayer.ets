import { PlayOptions } from "../player/interaction/PlayOptions";
import { ActivityEvent } from "../events/ActivityEvent";

const TAG = 'NativePlayer'

export class NativePlayer {
  isEnabled() {
    console.log(TAG, 'isEnabled:true');
    return true
  }

  loadPlayer(args: string) {
    let options = PlayOptions.fromJson(args)
    if (options) {
      getContext().eventHub.emit(ActivityEvent.LaunchNativePlayer, options)
    }
  }
}