import { PlayerViewModel } from "../../features/player/PlayerViewModel";
import { PlayOptions } from "../interaction/PlayOptions";
import { PlayerException } from "../PlayerException";
import { JellyfinMediaSource } from "../source/JellyfinMediaSource";
import { MediaSourceResolver } from "../source/MediaSourceResolver";
import { BusinessError } from "@kit.BasicServicesKit";
import { getVideosApi, PlaybackInfoResponse } from "sdk";
import { MediaProtocol, MediaStream, PlayMethod } from "sdk/src/main/ets/generated-client/models";
import { ApiClient } from "../../network/ApiClient";

export class QueueManager {

  private viewModel: PlayerViewModel

  constructor(viewModel: PlayerViewModel) {
    this.viewModel = viewModel
  }

  private currentQueue: string[] = []
  private currentQueueIndex: number = 0
  private mediaSourceResolver: MediaSourceResolver = new MediaSourceResolver()
  currentMediaSourceOrNull?: JellyfinMediaSource

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
    maxStreamingBitrate: number | null,
    startTimeTicks: number | null,
    audioStreamIndex: number | null,
    subtitleStreamIndex: number | null,
    playWhenReady: boolean = true): Promise<PlayerException | null> {
    this.mediaSourceResolver.resolveMediaSource(itemId, mediaSourceId, maxStreamingBitrate, startTimeTicks,
      audioStreamIndex, subtitleStreamIndex, playWhenReady)
    ?.then(async jellyfinMediaSource => {
      if (this.currentMediaSourceOrNull) {
        this.viewModel.stopTranscoding(this.currentMediaSourceOrNull)
      }
      this.currentMediaSourceOrNull = jellyfinMediaSource
      this.viewModel.load(jellyfinMediaSource, await this.prepareStreams(jellyfinMediaSource), playWhenReady)
    }).catch((e: BusinessError) => {

    })
    return null
  }

  async prepareStreams(source: JellyfinMediaSource): Promise<string[]> {
    let videoSource = await this.createVideoMediaSource(source)
    let subtitleSources = this.createExternalSubtitleMediaSources(source)
    return [videoSource, ...subtitleSources]
  }

  createExternalSubtitleMediaSources(source: JellyfinMediaSource):string[] {
    return source.externalSubtitleStreams.map(stream=>{
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
        break
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
        break
      case PlayMethod.Transcode:
        let transcodingPath = sourceInfo.TranscodingUrl
        if(transcodingPath){
          let protocol = sourceInfo.TranscodingSubProtocol
          if(protocol == 'hls'){
            let transcodingUrl = ApiClient.Instance().createUrl(transcodingPath)
            return transcodingUrl
          }else{
            throw new Error(`Unsupported transcode protocol "${protocol}"`)
          }
        }else{
          throw new Error('Missing transcode URL')
        }
        break
    }
    return ''
  }

  selectSubtitleStreamAndRestartPlayback(selectedMediaStream: MediaStream):boolean {
    return true
  }
}