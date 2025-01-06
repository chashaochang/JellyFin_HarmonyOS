import { PlayOptions } from "../player/interaction/PlayOptions";
import { audio } from "@kit.AudioKit";
import { ActivityEventType } from "../events/ActivityEvent";
import { emitter } from "@kit.BasicServicesKit";
import { Constants } from "../utils/Constants";

const TAG = 'NativePlayer'

export class NativePlayer {
  private mAudioManager: audio.AudioManager = audio.getAudioManager();
  volumeManager: audio.AudioVolumeManager = this.mAudioManager.getVolumeManager();

  isEnabled() {
    console.log(TAG, 'isEnabled:true');
    return true
  }

  loadPlayer(args: string) {
    console.log(TAG, 'loadPlayer');
    let options = PlayOptions.fromJson(args)
    if (options) {
      getContext().eventHub.emit(ActivityEventType.LaunchNativePlayer, options)
    }
  }

  pausePlayer() {
    console.log(TAG, 'pausePlayer');
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Pause'
      }
    })
  }

  resumePlayer() {
    console.log(TAG, 'resumePlayer');
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Resume'
      }
    })
  }

  stopPlayer() {
    console.log(TAG, 'stopPlayer');
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Stop'
      }
    })
  }

  destroyPlayer() {
    console.log(TAG, 'destroyPlayer');
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Destroy'
      }
    })
  }

  seek(ticks: number) {
    console.log(TAG, 'seek');
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Seek',
        'args': ticks / Constants.TICKS_PER_MILLISECOND
      }
    })
  }

  seekMs(ms: number) {
    console.log(TAG, 'seekMs');
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Seek',
        'args': ms + ''
      }
    })
  }

  setVolume(volume: number) {
    console.log(TAG, 'setVolume');
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'SetVolume',
        'args': volume
      }
    })
  }
}