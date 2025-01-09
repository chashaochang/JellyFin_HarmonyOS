import { getPlaystateApi, getSubtitleApi, ImageUrlsApi } from "sdk";
import { ApiClient } from "../../network/ApiClient";
import { QueueManager } from "../../player/queue/QueueManager";
import { BusinessError, emitter } from "@kit.BasicServicesKit";
import { JellyfinMediaSource } from "../../player/source/JellyfinMediaSource";
import { BaseItemDtoQueryResult, BaseItemKind, PlayMethod, RepeatMode } from "sdk/src/main/ets/generated-client/models";
import { Constants } from "../../utils/Constants";
import { TrackSelectionHelper } from "../../player/TrackSelectionHelper";
import { AxiosResponse } from "@ohos/axios";
import { buffer } from "@kit.ArkTS";
import { PlayerUIState } from "./PlayerUIState";
import { SubtitleManager } from "../../utils/SubtitleManager";
import { PlayStatus } from "./PlayStatus";
import { IjkMediaPlayer } from "@ohos/ijkplayer";
import { QueueItem } from "../../entity/QueueItem";
import avSessionManager from "../../utils/AVSessionManager";
import { avSession } from "@kit.AVSessionKit";

@ObservedV2
export class PlayerViewModel {
  queueManager: QueueManager = new QueueManager(this)
  subtitleManager: SubtitleManager = new SubtitleManager()
  uiState: PlayerUIState
  @Trace url?: string

  constructor(uiState: PlayerUIState) {
    this.uiState = uiState
  }

  async initAVSession() {
    let session = await avSessionManager.initAVSession()
    this.setSessionCallBack(session)
    await session.activate().catch((err: BusinessError) => {
      if (err) {
        console.error(`Failed to activate AVSession, error info: ${JSON.stringify(err)}`);
      }
    });
  }

  setSessionCallBack(session: avSession.AVSession) {
    // 一般在监听器中会对播放器做相应逻辑处理
    // 不要忘记处理完后需要通过set接口同步播放相关信息，参考上面的用例
    avSessionManager.getSession()?.on('play', () => {
      console.info(`on play , do play task`);
      // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('play')取消监听
      // 处理完毕后，请使用SetAVPlayState上报播放状态
      emitter.emit(Constants.PLAYER_EVENT, {
        data: {
          'eventName': 'Play'
        }
      })
    });
    session.on('pause', () => {
      console.info(`on pause , do pause task`);
      // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('pause')取消监听
      // 处理完毕后，请使用SetAVPlayState上报播放状态
      emitter.emit(Constants.PLAYER_EVENT, {
        data: {
          'eventName': 'Pause'
        }
      })
    });
    session.on('stop', () => {
      console.info(`on stop , do stop task`);
      // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('stop')取消监听
      // 处理完毕后，请使用SetAVPlayState上报播放状态
      emitter.emit(Constants.PLAYER_EVENT, {
        data: {
          'eventName': 'Stop'
        }
      })
    });
    session.on('playNext', () => {
      console.info(`on playNext , do playNext task`);
      // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('playNext')取消监听
      // 处理完毕后，请使用SetAVPlayState上报播放状态，使用SetAVMetadata上报媒体信息
      this.queueManager.next()
    });
    session.on('playPrevious', () => {
      console.info(`on playPrevious , do playPrevious task`);
      // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('playPrevious')取消监听
      // 处理完毕后，请使用SetAVPlayState上报播放状态，使用SetAVMetadata上报媒体信息
      this.queueManager.previous()
    });
    // session.on('fastForward', () => {
    //   console.info(`on fastForward , do fastForward task`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('fastForward')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
    // });
    // session.on('rewind', () => {
    //   console.info(`on rewind , do rewind task`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('rewind')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
    // });
    session.on('seek', (time) => {
      console.info(`on seek , the seek time is ${time}`);
      // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('seek')取消监听
      // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
      emitter.emit(Constants.PLAYER_EVENT, {
        data: {
          'eventName': 'Seek',
          'args': time
        }
      })
    });
    session.on('setSpeed', (speed) => {
      console.info(`on setSpeed , the speed is ${speed}`);
      // do some tasks ···
      emitter.emit(Constants.PLAYER_EVENT, {
        data: {
          'eventName': 'Speed',
          'args': speed + 'f'
        }
      })
    });
    // session.on('toggleFavorite', (assetId) => {
    //   console.info(`on toggleFavorite , the target asset Id is ${assetId}`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('toggleFavorite')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报收藏结果isFavorite
    // });

  }

  @Monitor('uiState.CONTROL_PlayStatus')
  async onPlayStateChanged() {
    if (this.uiState.CONTROL_PlayStatus == PlayStatus.INIT) {

    }
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
    this.uiState.mediaType = source.item.Type!
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
        if (source.item.Type == BaseItemKind.Episode) { //电视剧
          this.getItems()
          avSessionManager.getSession()?.setAVQueueTitle(source.item.SeriesName ?? source.item.Name ?? "TITLE",)
          this.getItems(source.item.SeriesId!)
        } else { //电影
          this.getItems(source.itemId)
        }
        avSessionManager?.getSession()?.setAVMetadata(source.toMediaMetadata())
        this.reportPlaybackStart(source)
      } else {
        console.log('外挂字幕:' + element);
      }
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
          let list: QueueItem[] = []
          let sessionQueue: avSession.AVQueueItem[] = []
          this.queueManager.currentQueue.forEach(e => {
            let item = items?.find(i => i.Id == e)
            if (!item) {
              return
            }
            let queueItem: QueueItem = {
              id: e,
              playIndex: item?.IndexNumber ?? NaN,
              name: item?.Name ?? ''
            }
            list.push(queueItem)
            let image =
              ApiClient.Instance().basePath + new ImageUrlsApi().getItemImageUrlById(item.SeriesId ?? item.Id)
            let queueItemDescription: avSession.AVMediaDescription = {
              assetId: item.Id!,
              title: item.SeriesName ?? item.Name ?? "TITLE",
              subtitle: item.SeriesName ? (item.Name ?? '') : '',
              description: 'music_description',
              mediaImage: image,
              startPosition: 0,
              duration: 1000
            };
            let avQueueItem: avSession.AVQueueItem = {
              itemId: item.IndexNumber!,
              description: queueItemDescription
            };
            sessionQueue.push(avQueueItem)
          })
          this.uiState.playList = list
          avSessionManager.getSession()?.setAVQueueItems(sessionQueue)
        }
        this.uiState.scroller.scrollToIndex(this.uiState.playList.findIndex(e => e.id == this.uiState.currentPlayId))
      }).catch((e: BusinessError) => {

      })
    }
  }

  release() {
    this.removeAVSessionCallback()
  }

  removeAVSessionCallback() {
    let session = avSessionManager.getSession()
    if (!session) {
      return
    }
    // 一般在监听器中会对播放器做相应逻辑处理
    // 不要忘记处理完后需要通过set接口同步播放相关信息，参考上面的用例
    session.off('play');
    session.off('pause');
    session.off('stop');
    session.off('playNext');
    session.off('playPrevious');
    // session.on('fastForward', () => {
    //   console.info(`on fastForward , do fastForward task`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('fastForward')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
    // });
    // session.on('rewind', () => {
    //   console.info(`on rewind , do rewind task`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('rewind')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
    // });
    session.off('seek')
    session.off('setSpeed');
    // session.off('toggleFavorite');
    session.destroy()
  }
}