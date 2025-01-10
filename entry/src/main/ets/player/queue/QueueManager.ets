import { PlayerViewModel } from "../../features/player/PlayerViewModel";
import { PlayOptions } from "../interaction/PlayOptions";
import { PlayerException } from "../PlayerException";
import { JellyfinMediaSource } from "../source/JellyfinMediaSource";
import { MediaSourceResolver } from "../source/MediaSourceResolver";
import { BusinessError } from "@kit.BasicServicesKit";
import { getItemsApi, getVideosApi } from "sdk";
import {
  BaseItemDtoQueryResult,
  DeviceProfile,
  MediaProtocol,
  MediaStream,
  MediaStreamType,
  PlayMethod
} from "sdk/src/main/ets/generated-client/models";
import { ApiClient } from "../../network/ApiClient";
import { AxiosResponse } from "@ohos/axios";
import { Constants } from "../../utils/Constants";
import { DeviceProfileBuilder } from "../deviceprofile/DeviceProfileBuilder";

@ObservedV2
export class QueueManager {
  private viewModel: PlayerViewModel

  constructor(viewModel: PlayerViewModel) {
    this.viewModel = viewModel
  }

  @Trace currentQueue: string[] = []
  @Trace currentQueueIndex: number = 0
  private mediaSourceResolver: MediaSourceResolver = new MediaSourceResolver()
  @Trace currentMediaSourceOrNull?: JellyfinMediaSource

  @Monitor('currentMediaSourceOrNull')
  onMediaSourceChanged() {
    this.viewModel.uiState.hasPrevious = this.hasPrevious()
    this.viewModel.uiState.hasNext = this.hasNext()
  }

  private deviceProfileBuilder: DeviceProfileBuilder = new DeviceProfileBuilder()
  private deviceProfile: DeviceProfile = this.deviceProfileBuilder.getDeviceProfile()

  initializePlaybackQueue(options: PlayOptions): PlayerException | null {
    this.currentQueue = options.ids
    this.currentQueueIndex = options.startIndex
    let itemId: string | null
    if (this.currentQueue.length > 0) {
      itemId = this.currentQueue[this.currentQueueIndex]
    } else {
      itemId = options.mediaSourceId
    }
    if (itemId == null) {
      return PlayerException.InvalidPlayOptions
    }
    this.startPlayback(
      itemId!,
      options.mediaSourceId,
      null,
      options.startPositionTicks,
      options.audioStreamIndex,
      options.subtitleStreamIndex,
      true
    )
    return null
  }

  async startPlayback(
    itemId: string,
    mediaSourceId: string | null,
    maxStreamingBitrate: number | null | undefined,
    startTimeTicks: number | null,
    audioStreamIndex: number | null,
    subtitleStreamIndex: number | null,
    playWhenReady: boolean = true): Promise<PlayerException | null> {
    this.mediaSourceResolver.resolveMediaSource(itemId, mediaSourceId, this.deviceProfile, maxStreamingBitrate,
      startTimeTicks,
      audioStreamIndex, subtitleStreamIndex, playWhenReady)
    ?.then(async jellyfinMediaSource => {
      if (this.currentMediaSourceOrNull) {
        this.viewModel.stopTranscoding(this.currentMediaSourceOrNull)
      }
      this.currentMediaSourceOrNull = jellyfinMediaSource
      this.viewModel.load(jellyfinMediaSource, await this.prepareStreams(jellyfinMediaSource), playWhenReady)
      this.viewModel.getSubtitle(jellyfinMediaSource)
    }).catch((e: BusinessError) => {
      return e
    })
    return null
  }

  hasPrevious(): boolean {
    return this.currentQueue.length > 0 && this.currentQueueIndex > 0
  }

  hasNext(): boolean {
    return this.currentQueue.length > 0 && this.currentQueueIndex < this.currentQueue.length - 1
  }

  async previous(): Promise<boolean> {
    if (!this.hasPrevious()) {
      return false
    }

    if (!this.currentMediaSourceOrNull) {
      return false
    }
    this.currentQueueIndex--;
    let currentMediaSource = this.currentMediaSourceOrNull

    await this.startPlayback(
      this.currentQueue[this.currentQueueIndex],
      null,
      currentMediaSource.maxStreamingBitrate ?? null,
      null,
      null,
      null
    )
    return true
  }

  async next(): Promise<boolean> {
    if (!this.hasNext()) {
      return false
    }
    if (!this.currentMediaSourceOrNull) {
      return false
    }
    let currentMediaSource = this.currentMediaSourceOrNull
    this.currentQueueIndex++;
    await this.startPlayback(
      this.currentQueue[this.currentQueueIndex],
      null,
      currentMediaSource.maxStreamingBitrate ?? null,
      null,
      null,
      null
    )
    return true
  }


  async prepareStreams(source: JellyfinMediaSource): Promise<string[]> {
    let videoSource = await this.createVideoMediaSource(source)
    let subtitleSources = this.createExternalSubtitleMediaSources(source)
    return [videoSource, ...subtitleSources]
  }

  createExternalSubtitleMediaSources(source: JellyfinMediaSource): string[] {
    return source.externalSubtitleStreams.map(stream => {
      return stream.deliveryUrl
    })
  }

  async createVideoMediaSource(source: JellyfinMediaSource): Promise<string> {
    let sourceInfo = source.sourceInfo
    switch (source.playMethod) {
      case PlayMethod.DirectPlay:
        if (sourceInfo.Protocol == MediaProtocol.File) {
          return await getVideosApi(ApiClient.Instance()).getVideoStream({
            itemId: source.itemId,
            _static: true,
            playSessionId: source.playSessionId,
            mediaSourceId: sourceInfo.Id,
            deviceId: ApiClient.Instance().deviceInfo.id,
          })
        } else if (sourceInfo.Protocol == MediaProtocol.Http) {
          return sourceInfo.Path!
        } else {
          throw new Error(`Unsupported protocol ${sourceInfo.Protocol}`)
        }
      case PlayMethod.DirectStream:
        let container = sourceInfo.Container
        if (container) {
          return await getVideosApi(ApiClient.Instance()).getVideoStreamByContainer({
            itemId: source.itemId,
            container: container,
            playSessionId: source.playSessionId,
            mediaSourceId: source.id,
            deviceId: ApiClient.Instance().deviceInfo.id,
          })
        } else {
          throw new Error('Missing direct stream container')
        }
      case PlayMethod.Transcode:
        let transcodingPath = sourceInfo.TranscodingUrl
        if (transcodingPath) {
          let protocol = sourceInfo.TranscodingSubProtocol
          if (protocol == 'hls') {
            let transcodingUrl = ApiClient.Instance().createUrl(transcodingPath)
            return transcodingUrl
          } else {
            throw new Error(`Unsupported transcode protocol "${protocol}"`)
          }
        } else {
          throw new Error('Missing transcode URL')
        }
    }
  }

  selectAudioStreamAndRestartPlayback(selectedMediaStream: MediaStream): boolean {
    // 验证选中的是音频流
    if (selectedMediaStream.Type !== MediaStreamType.Audio) {
      throw new Error('Selected stream must be an audio stream');
    }

    let currentMediaSource = this.currentMediaSourceOrNull
    if (!currentMediaSource) {
      return false
    }
    let position = this.viewModel.getPositionAndPause()
    if (!position) {
      return false
    }

    this.startPlayback(
      currentMediaSource.itemId,
      currentMediaSource.id,
      currentMediaSource.maxStreamingBitrate,
      position * Constants.TICKS_PER_MILLISECOND,
      selectedMediaStream.Index!,
      currentMediaSource.selectedSubtitleStreamIndex,
      true,
    )
    return true
  }

  selectSubtitleStreamAndRestartPlayback(selectedMediaStream?: MediaStream): boolean {
    // 验证选中的是字幕
    if (selectedMediaStream?.Type !== MediaStreamType.Subtitle) {
      throw new Error('Selected stream must be an subtitle stream');
    }

    let currentMediaSource = this.currentMediaSourceOrNull
    if (!currentMediaSource) {
      return false
    }
    let position = this.viewModel.getPositionAndPause()
    if (!position) {
      return false
    }

    this.startPlayback(
      currentMediaSource.itemId,
      currentMediaSource.id,
      currentMediaSource.maxStreamingBitrate,
      position * Constants.TICKS_PER_MILLISECOND,
      selectedMediaStream?.Index ?? -1,
      currentMediaSource.selectedSubtitleStreamIndex,
      true,
    )
    return true
  }

  async getItems(): Promise<AxiosResponse<BaseItemDtoQueryResult>> {
    return getItemsApi(ApiClient.Instance()).getItems({
      ids: this.currentQueue
    })
  }

  async getItem(id: string): Promise<AxiosResponse<BaseItemDtoQueryResult>> {
    return getItemsApi(ApiClient.Instance()).getItems({
      ids: Array.of(id),
      includeItemTypes: ['Series'],
      fields: ['Overview', 'Genres'],
    })
  }
}