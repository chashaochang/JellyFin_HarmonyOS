import { getPlaystateApi, getSubtitleApi, getVideosApi, PlaybackInfoResponse } from "sdk";
import { ApiClient } from "../../network/ApiClient";
import { QueueManager } from "../../player/queue/QueueManager";
import { BusinessError } from "@kit.BasicServicesKit";
import { PlayerViewUIState } from "./PlayerViewUIState";
import {
  GlobalContext, IjkPlayerControl, PlayStatus
} from "videoplayer/Index";
import { JellyfinMediaSource } from "../../player/source/JellyfinMediaSource";
import { PlayMethod, RepeatMode } from "sdk/src/main/ets/generated-client/models";
import { Constants } from "../../utils/Constants";
import { TrackSelectionHelper } from "../../player/TrackSelectionHelper";
import { AxiosResponse } from "@ohos/axios";
import { buffer } from "@kit.ArkTS";
import { SubtitleManager } from "../../player/SubtitleManager";

export class PlayerViewModel {

  queueManager: QueueManager = new QueueManager(this)
  subtitleManager:SubtitleManager = new SubtitleManager()

  get mediaSourceOrNull(): JellyfinMediaSource | undefined {
    return this.queueManager.currentMediaSourceOrNull
  }

  uiState: PlayerViewUIState = new PlayerViewUIState()
  trackSelectionHelper: TrackSelectionHelper = new TrackSelectionHelper(this)
  _player?: IjkPlayerControl
  initialTracksSelected: boolean = false
  //由于这个player要设置完url才能得到,暂时保存初始化信息
  initSource?: JellyfinMediaSource

  get playerOrNull(): IjkPlayerControl | undefined | null {
    return this._player
  }

  //相当于prepare
  setupPlayer() {
    this._player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl
    if (this.initSource) {
      this.initialTracksSelected = false
      let startTime = this.initSource.startTimeMs
      if (startTime > 0) {
        this._player.seekTo(startTime)
      }
      this.reportPlaybackStart(this.initSource)
    }

  }

  load(source: JellyfinMediaSource, url: string[], playWhenReady: boolean) {
    this.initSource = source
    for (let index = 0; index < url.length; index++) {
      const element = url[index];
      if (index === 0) {
        //设置播放器url,开始播放
        this.uiState.url = element
        this.uiState.title = source.sourceInfo.Name ?? ''
      } else {
        console.log('外挂字幕:' + element);
      }
    }
    let subtitleStream = source.selectedSubtitleStream
    if (subtitleStream) {
      getSubtitleApi(ApiClient.Instance()).getSubtitle({
        routeItemId: source.itemId,
        routeMediaSourceId: source.id,
        routeIndex: source.selectedSubtitleStreamIndex,
        routeFormat: subtitleStream.Codec
      }).then((res: AxiosResponse<string, ArrayBuffer>) => {
        let resText = buffer.from(res.data).toString()
        console.log('subtitle', resText);
        this.subtitleManager.parse(resText,subtitleStream?.Codec??'')
      }).catch((e: BusinessError) => {
        console.error(e.message)
      })
    }
  }

  stopTranscoding(mediaSource: JellyfinMediaSource) {
    if (mediaSource.playMethod == PlayMethod.Transcode) {
      // hlsSegmentApi.stopEncodingProcess(
      //   deviceId = apiClient.deviceInfo.id,
      //   playSessionId = mediaSource.playSessionId,
      // )
    }
  }

  reportPlaybackStart(mediaSource: JellyfinMediaSource) {
    getPlaystateApi(ApiClient.Instance()).reportPlaybackStart({
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

  async reportPlaybackStop() {
    let mediaSource = this.mediaSourceOrNull
    if (!mediaSource) {
      return
    }
    let player = this.playerOrNull
    if (!player) {
      return
    }
    let hasFinished = player.playStatus == PlayStatus.DONE
    let lastPositionTicks =
      hasFinished ? mediaSource.runTimeTicks : player.getCurrentPosition() * Constants.TICKS_PER_MILLISECOND
    let playStateApi = getPlaystateApi(ApiClient.Instance())
    await playStateApi.reportPlaybackStopped({
      playbackStopInfo: {
        ItemId: mediaSource.itemId,
        PositionTicks: lastPositionTicks,
        PlaySessionId: mediaSource.playSessionId,
        LiveStreamId: mediaSource.liveStreamId,
        Failed: false
      }
    })
    // Mark video as watched if playback finished
    if (hasFinished) {
      playStateApi.markPlayedItem({
        itemId: mediaSource.itemId
      })
    }
    // Stop active encoding if transcoding
    this.stopTranscoding(mediaSource)
  }

  updateSubtitle(pos: number) {
    this.uiState.subtitle = this.subtitleManager.getSubtitle(pos)
    console.log('updateSubtitle',this.uiState.subtitle);
  }
}