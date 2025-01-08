import {
  BaseItemDto,
  MediaSourceInfo,
  MediaStream,
  MediaStreamType,
  PlayMethod,
  SubtitleDeliveryMethod
} from 'sdk/src/main/ets/generated-client/models'
import { Constants } from '../../utils/Constants'
import { CodecHelpers } from '../deviceprofile/CodecHelpers'
import { ExternalSubtitleStream } from './ExternalSubtitleStream'
import { avSession, avSession as AVSessionManager } from '@kit.AVSessionKit';
import { ImageUrlsApi } from 'sdk'
import { ApiClient } from '../../network/ApiClient'

export class JellyfinMediaSource {
  itemId: string
  item: BaseItemDto
  sourceInfo: MediaSourceInfo
  playSessionId: string
  liveStreamId?: string | null
  maxStreamingBitrate?: number | null
  private startTimeTicks?: number | null
  audioStreamIndex?: number | null
  subtitleStreamIndex?: number | null
  id: string
  name: string
  playMethod: PlayMethod
  runTimeTicks: number
  runTimeMs: number
  mediaStreams: MediaStream[]
  audioStreams: Array<MediaStream>
  subtitleStreams: Array<MediaStream>
  externalSubtitleStreams: ExternalSubtitleStream[]
  _selectedVideoStream?: MediaStream

  private set selectedVideoStream(_selectedVideoStream: MediaStream | undefined) {
    this._selectedVideoStream = _selectedVideoStream
  }

  get selectedVideoStream(): MediaStream | undefined {
    return this._selectedVideoStream
  }

  _selectedAudioStream?: MediaStream

  private set selectedAudioStream(_selectedAudioStream: MediaStream | undefined) {
    this._selectedAudioStream = _selectedAudioStream
  }

  get selectedAudioStream(): MediaStream | undefined {
    return this._selectedAudioStream
  }

  _selectedSubtitleStream?: MediaStream

  private set selectedSubtitleStream(_selectedSubtitleStream: MediaStream | undefined) {
    this._selectedSubtitleStream = _selectedSubtitleStream
  }

  get selectedSubtitleStream(): MediaStream | undefined {
    return this._selectedSubtitleStream
  }

  get selectedAudioStreamIndex(): number | undefined {
    return this.selectedAudioStream?.Index
  }

  // -1 disables subtitles, null would select the default subtitle
  // If the default should be played, it would be explicitly set above
  get selectedSubtitleStreamIndex(): number {
    return this.selectedSubtitleStream?.Index ?? -1
  }


  constructor(itemId: string,
    item: BaseItemDto,
    sourceInfo: MediaSourceInfo,
    playSessionId: string,
    liveStreamId?: string | null,
    maxStreamingBitrate?: number | null,
    startTimeTicks?: number | null,
    audioStreamIndex?: number | null,
    subtitleStreamIndex?: number | null,
  ) {
    this.itemId = itemId
    this.item = item
    this.sourceInfo = sourceInfo
    this.playSessionId = playSessionId
    this.liveStreamId = liveStreamId
    this.maxStreamingBitrate = maxStreamingBitrate
    this.startTimeTicks = startTimeTicks
    this.audioStreamIndex = audioStreamIndex
    this.subtitleStreamIndex = subtitleStreamIndex

    this.id = this.sourceInfo.Id ?? "Media source has no id"
    this.name = item.Name ?? sourceInfo.Name ?? ''
    if (sourceInfo.SupportsDirectPlay) {
      this.playMethod = PlayMethod.DirectPlay
    } else if (sourceInfo.SupportsDirectStream) {
      this.playMethod = PlayMethod.DirectStream
    } else if (sourceInfo.SupportsTranscoding) {
      this.playMethod = PlayMethod.Transcode
    } else {
      throw new Error(`No play method found for ${this.name} (${itemId})`)
    }
    this.runTimeTicks = this.sourceInfo.RunTimeTicks ?? 0
    this.runTimeMs = this.runTimeTicks / Constants.TICKS_PER_MILLISECOND
    this.mediaStreams = sourceInfo.MediaStreams ?? []
    let audio: MediaStream[] = []
    let subtitles: MediaStream[] = []
    let externalSubtitles: ExternalSubtitleStream[] = []
    for (const mediaStream of this.mediaStreams) {
      switch (mediaStream.Type) {
        case MediaStreamType.Video:
          // Always select the first available video stream
          if (this.selectedVideoStream == null) {
            this.selectedVideoStream = mediaStream
          }
          break
        case MediaStreamType.Audio:
          audio.push(mediaStream)
          if (mediaStream.Index == (audioStreamIndex ?? sourceInfo.DefaultAudioStreamIndex)) {
            this.selectedAudioStream = mediaStream
          }
          break
        case MediaStreamType.Subtitle:
          subtitles.push(mediaStream)
          if (mediaStream.Index == (subtitleStreamIndex ?? sourceInfo.DefaultSubtitleStreamIndex)) {
            this.selectedSubtitleStream = mediaStream
          }
          // External subtitles as specified by the deliveryMethod.
          // It is set to external either for external subtitle files or when transcoding.
          // In the latter case, subtitles are extracted from the source file by the server.
          if (mediaStream.DeliveryMethod == SubtitleDeliveryMethod.External) {
            let deliveryUrl = mediaStream.DeliveryUrl
            let mimeType = CodecHelpers.getSubtitleMimeType(mediaStream.Codec)
            if (deliveryUrl != null && mimeType != null) {
              externalSubtitles.push(new ExternalSubtitleStream(
                mediaStream.Index!,
                deliveryUrl,
                mimeType,
                mediaStream.DisplayTitle ?? '',
                mediaStream.Language ?? Constants.LANGUAGE_UNDEFINED,
              ))
            }
          }
          break
      }
    }
    this.audioStreams = audio
    this.subtitleStreams = subtitles
    this.externalSubtitleStreams = externalSubtitles
  }

  //private _startTimeMs: number = 0

  get startTimeMs(): number {
    return (this.startTimeTicks ?? 0) / Constants.TICKS_PER_MILLISECOND
  }

  set startTimeMs(value: number) {
    this.startTimeTicks = value * Constants.TICKS_PER_MILLISECOND
  }

  selectSubtitleStream(stream: MediaStream | undefined | null): boolean {
    if (!stream) {
      this.selectedSubtitleStream = undefined
      return true
    }
    if (stream.Type == MediaStreamType.Subtitle) {
      if (this.mediaStreams[stream.Index!] !== stream) {
        return false
      }
      this.selectedSubtitleStream = stream
      return true
    } else {
      throw new Error('stream.Type Require')
    }
  }

  toMediaMetadata(): AVSessionManager.AVMetadata {
    let image =
      ApiClient.Instance().basePath + new ImageUrlsApi().getItemImageUrlById(this.item.SeriesId ?? this.itemId)
    // 设置必要的媒体信息
    let metadata: AVSessionManager.AVMetadata = {
      assetId: this.itemId, // 由应用指定，用于标识应用媒体库里的媒体
      title: this.item.SeriesName ?? this.item.Name ?? "TITLE",
      mediaImage: image,
      subtitle: this.item.SeriesName ? (this.item.Name ?? '') : '',
      // 发现Cast+ Stream 和 DLNA协议设备，TYPE_CAST_PLUS_STREAM为默认必选。
      filter: avSession.ProtocolType.TYPE_CAST_PLUS_STREAM | avSession.ProtocolType.TYPE_DLNA,
      duration:this.runTimeMs,
    };
    return metadata
  }
}