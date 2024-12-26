import { PlayOptions } from "../player/interaction/PlayOptions";
import { ActivityEvents } from "../events/ActivityEvent";
import { GlobalContext } from "videoplayer/src/main/ets/components/mainpage/GlobalContext";
import { IjkPlayerControl } from "videoplayer/Index";
import { Constants } from "../utils/Constants";
import { audio } from "@kit.AudioKit";

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
      getContext().eventHub.emit(ActivityEvents.LAUNCH_NATIVE_PLAYER, options)
    }
  }

  pausePlayer() {
    console.log(TAG, 'pausePlayer');
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.pause();
    }
  }

  resumePlayer() {
    console.log(TAG, 'resumePlayer');
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.resumePlay();
    }
  }

  stopPlayer() {
    console.log(TAG, 'stopPlayer');
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.stop();
    }
  }

  destroyPlayer() {
    console.log(TAG, 'destroyPlayer');
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.release();
    }
  }

  seek(ticks: number) {
    console.log(TAG, 'seek');
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.seekTo(ticks / Constants.TICKS_PER_MILLISECOND);
    }
  }

  seekMs(ms: number) {
    console.log(TAG, 'seekMs');
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.seekTo(ms);
    }
  }

  setVolume(volume: number) {
    console.log(TAG, 'setVolume');
  }
}