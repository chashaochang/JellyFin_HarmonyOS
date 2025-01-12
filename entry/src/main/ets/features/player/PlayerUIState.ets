import { MediaStream } from "sdk/src/main/ets/generated-client/models"
import { BaseItemKind } from "sdk/src/main/ets/generated-client/models/base-item-kind"
import { QueueItem } from "../../entity/QueueItem"
import { QualityOption } from "../../player/qualityoptions/QualityOption"
import { SubtitleItem } from "../../utils/SubtitleManager"
import { PlayerStatus, PlayStatus } from "./PlayStatus"
import { avSession } from "@kit.AVSessionKit"

@ObservedV2
export class PlayerUIState {
  //集名称
  @Trace title: string = ''
  //电视剧名称
  @Trace seriesName?: string | null
  //简介
  @Trace overview: string = ''
  //类型
  @Trace genres: string[] = []
  //当前字幕
  @Trace currentSubtitle: string = ''
  //字幕解析结果
  @Trace subtitles: SubtitleItem[] = []
  //整理后的播放列表
  @Trace playList: QueueItem[] = []
  //整理后的播放列表
  @Trace sessionQueue: avSession.AVQueueItem[] = []
  //当前播放视频id
  @Trace currentPlayId: string = ''
  //媒体类型
  @Trace mediaType: BaseItemKind = BaseItemKind.Video
  //音频列表
  @Trace audioStreams:MediaStream[] = []
  //字幕列表
  @Trace subtitleStreams:MediaStream[] = []
  //选中音频
  selectedAudioStream?: MediaStream
  //选中字幕
  selectedSubtitleStream?: MediaStream
  //质量列表
  qualityOptions:QualityOption[] = []
  //选中码率
  selectedBitrate?: number | null
  //正在投屏
  @Trace isCastPlaying:boolean = false

  scroller: ListScroller = new ListScroller()
  playWhenReady: boolean = true
  //初始进度
  initSeek: number = 0
  @Trace CONTROL_PlayStatus: number = PlayStatus.INIT;
  @Trace audioTrackIndex?: number | null = null
  @Trace playerStatus: number = PlayerStatus.IDLE
  @Trace hasPrevious: boolean = false
  @Trace hasNext: boolean = false
}