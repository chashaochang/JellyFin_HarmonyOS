import { getPlaystateApi, getVideosApi, PlaybackInfoResponse } from "sdk";
import { ApiClient } from "../../network/ApiClient";
import { QueueManager } from "../../player/queue/QueueManager";
import { BusinessError } from "@kit.BasicServicesKit";
import { PlayerViewUIState } from "./PlayerViewUIState";
import { BaseVideoPlayer, GlobalContext, IjkVideoPlayer, PlayStatus } from "@ohos/gsyvideoplayer/Index";
import { JellyfinMediaSource } from "../../player/source/JellyfinMediaSource";
import { PlayMethod, RepeatMode } from "sdk/src/main/ets/generated-client/models";
import { Constants } from "../../utils/Constants";
import { audio } from "@kit.AudioKit";
import { TrackSelectionHelper } from "../../player/TrackSelectionHelper";

export class PlayerViewModel {
  queueManager: QueueManager = new QueueManager(this)

  get mediaSourceOrNull(): JellyfinMediaSource | undefined {
    return this.queueManager.currentMediaSourceOrNull
  }

  uiState: PlayerViewUIState = new PlayerViewUIState()
  trackSelectionHelper: TrackSelectionHelper = new TrackSelectionHelper(this)
  _player?: BaseVideoPlayer
  initialTracksSelected: boolean = false
  //由于这个player要设置完url才能得到,暂时保存初始化信息
  initSource?: JellyfinMediaSource

  get playerOrNull(): BaseVideoPlayer | undefined | null {
    return this._player
  }

  setupPlayer() {
    this._player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer
    if (this.initSource) {
      this.initialTracksSelected = false
      let startTime = this.initSource.startTimeMs
      if (startTime > 0) {
        this._player.seekTo(startTime)
      }
      this.reportPlaybackStart(this.initSource)
      if (this.initSource.selectedSubtitleStream) {
        this.trackSelectionHelper.selectSubtitleTrack(this.initSource.selectedSubtitleStream)
        this._player.selectTrack(1)
      }
    }
  }

  load(source: JellyfinMediaSource, url: string[], playWhenReady: boolean) {
    this.initSource = source
    for (let index = 0; index < url.length; index++) {
      const element = url[index];
      if (index === 0) {
        //设置播放器url,开始播放
        this.uiState.url = element
      } else {
        console.log('外挂字幕:' + element);
      }
    }
  }

  stopTranscoding(mediaSource: JellyfinMediaSource) {

  }

  async reportPlaybackStart(mediaSource: JellyfinMediaSource) {
    await getPlaystateApi(ApiClient.Instance()).reportPlaybackStart({
      playbackStartInfo: {
        ItemId: mediaSource.itemId,
        PlayMethod: mediaSource.playMethod,
        PlaySessionId: mediaSource.playSessionId,
        AudioStreamIndex: mediaSource.selectedAudioStream?.Index,
        SubtitleStreamIndex: mediaSource.selectedSubtitleStream?.Index,
        // IsPaused:true,
        IsMuted: false,
        CanSeek: true,
        PositionTicks: mediaSource.startTimeMs * Constants.TICKS_PER_MILLISECOND,
        // VolumeLevel:audio.getAudioManager().getVolume(audio.AudioVolumeType.MEDIA),
        RepeatMode: RepeatMode.RepeatNone
      }
    })
  }
}