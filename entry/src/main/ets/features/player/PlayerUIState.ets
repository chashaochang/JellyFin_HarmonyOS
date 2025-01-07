import { SubtitleItem } from "../../utils/SubtitleManager"
import { PlayStatus } from "./PlayStatus"

@ObservedV2
export class PlayerUIState {
  @Trace title: string = ''
  @Trace currentSubtitle: string = ''
  @Trace subtitles: SubtitleItem[] = []
  playWhenReady: boolean = true
  initSeek: number = 0
  @Trace CONTROL_PlayStatus: number = PlayStatus.INIT;
  @Trace audioTrackIndex?: number|null = null
}