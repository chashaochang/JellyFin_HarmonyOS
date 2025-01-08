import { SubtitleItem } from "../../utils/SubtitleManager"
import { PlayerStatus, PlayStatus } from "./PlayStatus"

@ObservedV2
export class PlayerUIState {
  //集名称
  @Trace title: string = ''
  //电视剧名称
  @Trace seriesName?: string | null
  @Trace currentSubtitle: string = ''
  @Trace subtitles: SubtitleItem[] = []
  playWhenReady: boolean = true
  initSeek: number = 0
  @Trace CONTROL_PlayStatus: number = PlayStatus.INIT;
  @Trace audioTrackIndex?: number | null = null
  @Trace playerStatus: number = PlayerStatus.IDLE
  @Trace hasPrevious: boolean = false
  @Trace hasNext: boolean = false
}