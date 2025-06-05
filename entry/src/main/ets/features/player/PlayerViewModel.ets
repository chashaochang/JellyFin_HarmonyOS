import { getHlsSegmentApi, getLibraryApi, getPlaystateApi, getSubtitleApi, ImageUrlsApi } from "sdk";
import { ApiClient } from "../../network/ApiClient";
import { QueueManager } from "../../player/queue/QueueManager";
import { BusinessError, emitter } from "@kit.BasicServicesKit";
import { JellyfinMediaSource } from "../../player/source/JellyfinMediaSource";
import {
  BaseItemDtoQueryResult,
  BaseItemKind,
  ItemFields,
  MediaStream,
  PlayMethod,
  RepeatMode
} from "sdk/src/main/ets/generated-client/models";
import { Constants } from "../../utils/Constants";
import { TrackSelectionHelper } from "../../player/TrackSelectionHelper";
import { AxiosResponse } from "@ohos/axios";
import { buffer } from "@kit.ArkTS";
import { PlayerUIState } from "./PlayerUIState";
import { SubtitleManager } from "../../utils/SubtitleManager";
import { PlayStatus } from "./PlayStatus";
import { QueueItem } from "../../entity/QueueItem";
import avSessionManager from "../../utils/AVSessionManager";
import { avSession } from "@kit.AVSessionKit";
import qualityOptionsProvider from "../../player/qualityoptions/QualityOptionsProvider";
import { BackgroundTaskManager } from "../../utils/BackgroundTaskManager";
import { SimilarItem } from "../../entity/SimilarItem";

@ObservedV2
export class PlayerViewModel {
  //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
  // });
  // session.on('rewind', () => {
  //   console.info(`on rewind , do rewind task`);
  //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('rewind')取消监听
  //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
  // });

  queueManager: QueueManager = new QueueManager(this)
  subtitleManager: SubtitleManager = new SubtitleManager()
  uiState: PlayerUIState
  @Trace url?: string

  constructor(uiState: PlayerUIState) {
    this.uiState = uiState
  }

  @Monitor('mediaSourceOrNull')
  onMediaSourceChanged() {
    let source = this.mediaSourceOrNull
    if (source) {
      this.uiState.audioTrackIndex = source.audioStreamIndex
      this.uiState.title = source.name
      this.uiState.seriesName = source.item.SeriesName
      this.uiState.audioStreams = source.audioStreams
      this.uiState.subtitleStreams = source.subtitleStreams
      this.uiState.selectedAudioStream = source.selectedAudioStream
      this.uiState.selectedSubtitleStream = source.selectedSubtitleStream
      let videoStream = source.selectedVideoStream
      let height = videoStream?.Height
      let width = videoStream?.Width
      if (height != null && width != null) {
        this.uiState.qualityOptions = qualityOptionsProvider.getApplicableQualityOptions(width, height)
      } else {
        //qualityButton.isVisible = false
      }
    }
  }

  @Monitor('mediaSourceOrNull._selectedAudioStream')
  onSelectedAudioStreamChanged() {
    this.uiState.selectedAudioStream = this.mediaSourceOrNull?._selectedAudioStream
  }

  @Monitor('mediaSourceOrNull._selectedSubtitleStream')
  onSelectedSubtitleStreamChanged() {
    this.uiState.selectedSubtitleStream = this.mediaSourceOrNull?._selectedSubtitleStream
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
    session.on('play', () => {
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
          'args': speed
        }
      })
    });
    // session.on('toggleFavorite', (assetId) => {
    //   console.info(`on toggleFavorite , the target asset Id is ${assetId}`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('toggleFavorite')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报收藏结果isFavorite
    // });
    session.on('outputDeviceChange', this.sessionOutputDeviceChange)
  }

  private sessionOutputDeviceChange = async (connectState: avSession.ConnectionState,
    device: avSession.OutputDeviceInfo) => {
    let currentDevice: avSession.DeviceInfo = device?.devices?.[0];
    if (currentDevice.castCategory === avSession.AVCastCategory.CATEGORY_REMOTE &&
      connectState === avSession.ConnectionState.STATE_CONNECTED) {
      if (currentDevice.supportedProtocols === avSession.ProtocolType.TYPE_CAST_PLUS_STREAM) {
        // 此设备支持cast+投播协议
        console.log('此设备支持cast+投播协议')
      } else if (currentDevice.supportedProtocols === avSession.ProtocolType.TYPE_DLNA) {
        // 此设备支持DLNA投播协议
        console.log('此设备支持DLNA投播协议')
      }
      this.startCast()
    } else if ((currentDevice.castCategory === avSession.AVCastCategory.CATEGORY_REMOTE &&
      connectState === avSession.ConnectionState.STATE_DISCONNECTED) ||
      (currentDevice.castCategory === avSession.AVCastCategory.CATEGORY_LOCAL &&
        connectState === avSession.ConnectionState.STATE_CONNECTED)) {
      if (device) {
        this.stopCast()
      }
    }
  };

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
    this.uiState.selectedBitrate = source.maxStreamingBitrate
    this.uiState.mediaType = source.item.Type!
    this.uiState.currentPlayId = this.queueManager.currentQueue[this.queueManager.currentQueueIndex]
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
    //更多类似的
    getLibraryApi(ApiClient.Instance()).getSimilarItems({
      itemId: source.item.SeriesId ?? source.itemId,
      userId: AppStorage.get('userId'),
      limit: 12,
      fields: [ItemFields.PrimaryImageAspectRatio, ItemFields.CanDelete]
    }).then((res: AxiosResponse<BaseItemDtoQueryResult>) => {
      let result = res.data.Items?.map(e => {
        let desc = e.ProductionYear + ''
        switch (e.Status) {
          case 'Continuing':
            desc += ' - 现在'
            break
          case 'Ended':
            desc = desc + ' - ' + new Date(e.EndDate!).getFullYear()
            break
        }
        let item: SimilarItem = {
          id:e.Id!,
          name: e.Name ?? '',
          image: ApiClient.Instance().basePath + new ImageUrlsApi().getItemImageUrlById(e.Id),
          desc: desc,
          runTimeTicks : e.RunTimeTicks
        }
        return item
      }) ?? []
      this.uiState.similarItems = result
    })
  }

  stopTranscoding(mediaSource: JellyfinMediaSource) {
    if (mediaSource.playMethod == PlayMethod.Transcode) {
      getHlsSegmentApi(ApiClient.Instance()).stopEncodingProcess({
        deviceId: ApiClient.Instance().deviceInfo.id,
        playSessionId: mediaSource.playSessionId,
      })
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
    let lastPositionTicks = hasFinished ? mediaSource.runTimeTicks : 0//IMediaPlayer.getCurrentPosition() * Constants.TICKS_PER_MILLISECOND
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

  selectSubtitle(selectedSubtitleStream: MediaStream) {
    getSubtitleApi(ApiClient.Instance()).getSubtitle({
      routeItemId: this.initSource!.itemId,
      routeMediaSourceId: this.initSource?.id,
      routeIndex: selectedSubtitleStream.Index,
      routeFormat: selectedSubtitleStream?.Codec
    }).then((res: AxiosResponse<string, ArrayBuffer>) => {
      let resText = buffer.from(res.data).toString()
      this.uiState.subtitles = this.subtitleManager.parse(resText, selectedSubtitleStream!.Codec!)
    }).catch((e: BusinessError) => {
      console.error(e.message)
    })
  }

  getSubtitle(source: JellyfinMediaSource) {
    if (source.playMethod == PlayMethod.Transcode) {
      this.uiState.currentSubtitle = ''
      this.uiState.subtitles = []
      return
    }
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
              mediaImage: image,
            };
            let avQueueItem: avSession.AVQueueItem = {
              itemId: item.IndexNumber!,
              description: queueItemDescription
            };
            sessionQueue.push(avQueueItem)
          })
          this.uiState.playList = list
          avSessionManager.getSession()?.setAVQueueItems(sessionQueue)
          this.uiState.sessionQueue = sessionQueue
        }
        this.uiState.scroller.scrollToIndex(this.uiState.playList.findIndex(e => e.id == this.uiState.currentPlayId))
      }).catch((e: BusinessError) => {

      })
    }
  }

  release() {
    avSessionManager.unregisterSessionListener()
    //BackgroundTaskManager.stopContinuousTask(this.context);
  }

  getPositionAndPause(): number {
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Pause'
      }
    })
    return 0//IjkMediaPlayer.getInstance().getCurrentPosition()
  }

  changeBitrate(bitrate?: number) {
    this.queueManager.changeBitrate(bitrate)
  }

  logTracks() {

  }

  private async startCast() {
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'Pause'
      }
    })
    let castController = await avSessionManager.getSession()?.getAVCastController()
    castController?.on('playbackStateChange', 'all', this.playbackStateChangeListener);
    castController?.on('endOfStream', this.reloadCasting);
    castController?.on('playNext', this.playNextCallback);
    castController?.on('playPrevious', this.playPreviousCallback);
    let queueItem = this.uiState.playList.find(e => e.id == this.uiState.currentPlayId)
    let avQueueItem: avSession.AVQueueItem = {
      itemId: queueItem!.playIndex,
      description: {
        assetId: queueItem!.id,
        title: this.uiState.seriesName ?? this.uiState.title,
        subtitle: this.uiState.seriesName ? this.uiState.title : '',
        mediaUri: this.url,

        mediaType: 'VIDEO',
        appName: Constants.APP_INFO_NAME,
        //startPosition为投播当前进度，设置该字段可将本机播放进度同步到远端
        startPosition: 0,//IjkMediaPlayer.getInstance().getCurrentPosition(),
        // 投播资源播放时长，设置该字段可将本机播放时长同步到远端显示
        duration: 0//IjkMediaPlayer.getInstance().getDuration(),
      }
    }

    try {
      await castController?.prepare(avQueueItem)
      await castController?.start(avQueueItem)
    } catch (e) {
      console.error(e)
    }
    BackgroundTaskManager.startContinuousTask(AppStorage.get('context'))
    this.uiState.isCastPlaying = true;
  }

  async stopCast() {
    avSessionManager.getSession()?.stopCasting()
    this.uiState.isCastPlaying = false;
    let castController = await avSessionManager.getSession()?.getAVCastController()
    castController?.off('playbackStateChange');
    castController?.off('endOfStream');
    castController?.off('playNext');
    castController?.off('playPrevious');
    BackgroundTaskManager.stopContinuousTask(AppStorage.get('context'))
  }

  private playbackStateChangeListener = (playbackState: avSession.AVPlaybackState) => {
    const duration = playbackState?.extras?.duration;
    // if (typeof duration === 'number') {
    //   this.playDurationChange(duration as number);
    // }

    if (typeof playbackState?.position?.elapsedTime !== 'undefined') {
      //this.positionChange(playbackState?.position?.elapsedTime);
      emitter.emit(Constants.PLAYER_EVENT, {
        data: {
          'eventName': 'Seek',
          'args': playbackState?.position?.elapsedTime
        }
      })
    }

    if (playbackState.state === Constants.PLAYBACK_STATE_PAUSE ||
      playbackState.state === Constants.PLAYBACK_STATE_STOP ||
      playbackState.state === Constants.PLAYBACK_STATE_PREPARE ||
      playbackState.state === Constants.PLAYBACK_STATE_INITIAL) {
      this.uiState.isCastPlaying = false;
    }

    if (playbackState.state === Constants.PLAYBACK_STATE_PLAY) {
      this.uiState.isCastPlaying = true;
    }
  };
  private reloadCasting = async () => {
    let queueItem = this.uiState.playList.find(e => e.id == this.uiState.currentPlayId)
    let image =
      ApiClient.Instance().basePath + new ImageUrlsApi().getItemImageUrlById(queueItem?.id)
    let avQueueItem: avSession.AVQueueItem = {
      itemId: queueItem!.playIndex,
      description: {
        assetId: queueItem!.id,
        title: (this.uiState.mediaType == BaseItemKind.Episode ? this.uiState.seriesName : this.uiState.title) ?? '',
        subtitle: (this.uiState.mediaType == BaseItemKind.Episode ? this.uiState.title : '') ?? '',
        mediaImage: image,
        mediaUri: this.url,
        mediaType: 'VIDEO',
        appName: Constants.APP_INFO_NAME,
        //startPosition为投播当前进度，设置该字段可将本机播放进度同步到远端
        startPosition: 0,
        // 投播资源播放时长，设置该字段可将本机播放时长同步到远端显示
        duration: 0//IMediaPlayer.getInstance().getDuration(),
      }
    }

    try {
      let castController = await avSessionManager.getSession()?.getAVCastController()
      await castController?.prepare(avQueueItem)
      await castController?.start(avQueueItem)
    } catch (e) {
      console.error(e)
    }
    this.uiState.isCastPlaying = true;
  };
  public playNextCallback = (): void => {
    this.queueManager.next()
  };
  public playPreviousCallback = (): void => {
    this.queueManager.previous()
  };

  changeEpisode(index: number) {
    this.queueManager.changeEpisode(index)
  }
}