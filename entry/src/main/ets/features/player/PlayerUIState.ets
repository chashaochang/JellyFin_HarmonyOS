import { BaseItemKind } from "sdk/src/main/ets/generated-client/models/base-item-kind"
import { QueueItem } from "../../entity/QueueItem"
import { SubtitleItem } from "../../utils/SubtitleManager"
import { PlayerStatus, PlayStatus } from "./PlayStatus"

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
  //当前播放视频id
  @Trace currentPlayId: string = ''
  //媒体类型
  @Trace mediaType: BaseItemKind = BaseItemKind.Video
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