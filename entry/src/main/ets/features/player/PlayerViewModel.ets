import { getMediaInfoApi, getPlaystateApi, getSubtitleApi } from "sdk";
import { ApiClient } from "../../network/ApiClient";
import { QueueManager } from "../../player/queue/QueueManager";
import { BusinessError } from "@kit.BasicServicesKit";
import { JellyfinMediaSource } from "../../player/source/JellyfinMediaSource";
import { BaseItemDtoQueryResult, PlayMethod, RepeatMode } from "sdk/src/main/ets/generated-client/models";
import { Constants } from "../../utils/Constants";
import { TrackSelectionHelper } from "../../player/TrackSelectionHelper";
import { AxiosResponse } from "@ohos/axios";
import { buffer } from "@kit.ArkTS";
import { PlayerUIState } from "./PlayerUIState";
import { SubtitleManager } from "../../utils/SubtitleManager";
import { PlayStatus } from "./PlayStatus";
import { IjkMediaPlayer } from "@ohos/ijkplayer";
import { QueueItem } from "../../entity/QueueItem";

@ObservedV2
export class PlayerViewModel {
  queueManager: QueueManager = new QueueManager(this)
  subtitleManager: SubtitleManager = new SubtitleManager()
  uiState: PlayerUIState
  @Trace url?: string

  constructor(uiState: PlayerUIState) {
    this.uiState = uiState
  }

  @Monitor('uiState.CONTROL_PlayStatus')
  onPlayerStateChanged() {

  }

  get mediaSourceOrNull(): JellyfinMediaSource | undefined {
    return this.queueManager.currentMediaSourceOrNull
  }

  trackSelectionHelper: TrackSelectionHelper = new TrackSelectionHelper(this)
  initialTracksSelected: boolean = false
  //由于这个player要设置完url才能得到,暂时保存初始化信息
  initSource?: JellyfinMediaSource

  load(source: JellyfinMediaSource, url: string[], playWhenReady: boolean) {
    this.initSource = source
    this.uiState.currentPlayId = this.queueManager.currentQueue[this.queueManager.currentQueueIndex]
    this.uiState.audioTrackIndex = source.audioStreamIndex
    this.uiState.title = source.name
    this.uiState.seriesName = source.item.SeriesName
    for (let index = 0; index < url.length; index++) {
      const element = url[index];
      if (index === 0) {
        this.url = element
        //设置播放器url,开始播放

        this.uiState.playWhenReady = playWhenReady
        this.initialTracksSelected = false
        let startTime = this.initSource.startTimeMs
        if (startTime > 0) {
          this.uiState.initSeek = startTime
        }
        this.reportPlaybackStart(source)
      } else {
        console.log('外挂字幕:' + element);
      }
    }
    this.getItems()
    if (source.item.SeriesId) {
      this.getItems(source.item.SeriesId)
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
    let hasFinished = this.uiState.CONTROL_PlayStatus == PlayStatus.DONE
    let lastPositionTicks =
      hasFinished ? mediaSource.runTimeTicks :
        IjkMediaPlayer.getInstance().getCurrentPosition() * Constants.TICKS_PER_MILLISECOND
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

  getSubtitle(source: JellyfinMediaSource) {
    if (source.selectedSubtitleStream) {
      getSubtitleApi(ApiClient.Instance()).getSubtitle({
        routeItemId: source.itemId,
        routeMediaSourceId: source.id,
        routeIndex: source.selectedSubtitleStreamIndex,
        routeFormat: source.selectedSubtitleStream.Codec
      }).then((res: AxiosResponse<string, ArrayBuffer>) => {
        let resText = buffer.from(res.data).toString()
        this.uiState.subtitles = this.subtitleManager.parse(resText, source.selectedSubtitleStream!.Codec!)
      }).catch((e: BusinessError) => {
        console.error(e.message)
      })
    }
  }

  //获取播放列表信息
  getItems(id?: string) {
    if (id) { //剧id
      this.queueManager.getItem(id).then((res: AxiosResponse<BaseItemDtoQueryResult>) => {
        if (res.data.Items && res.data.Items.length > 0) {
          this.uiState.overview = res.data.Items[0].Overview ?? ""
          this.uiState.genres = res.data.Items[0].Genres ?? []
        }
      }).catch((e: BusinessError) => {

      })
    } else {
      this.queueManager.getItems().then((res: AxiosResponse<BaseItemDtoQueryResult>) => {
        console.log(this.initSource?.itemId)
        console.log(JSON.stringify(res.data.Items));
        let items = res.data.Items
        if (this.queueManager.currentQueue.length > 0) {
          this.uiState.playList = this.queueManager.currentQueue.map(e => {
            let item = items?.find(i => i.Id == e)
            let queueItem: QueueItem = {
              id: e,
              playIndex: item?.IndexNumber ?? NaN, //items?.find(i=>i.Id == e)
              name: item?.Name ?? ''
            }
            return queueItem
          })
        }
        this.uiState.scroller.scrollToIndex(this.uiState.playList.findIndex(e=>e.id == this.uiState.currentPlayId))
      }).catch((e: BusinessError) => {

      })
    }
  }
}