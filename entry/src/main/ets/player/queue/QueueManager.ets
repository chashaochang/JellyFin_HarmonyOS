import { PlayerViewModel } from "../../features/PlayerViewModel";
import { PlayOptions } from "../interaction/PlayOptions";
import { PlayerException } from "../PlayerException";
import { MediaSourceResolver } from "../source/MediaSourceResolver";

export class QueueManager {
  private viewModel: PlayerViewModel

  constructor(viewModel: PlayerViewModel) {
    this.viewModel = viewModel
  }

  private currentQueue: string[] = []
  private currentQueueIndex: number = 0
  private mediaSourceResolver: MediaSourceResolver = new MediaSourceResolver()

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
    let res = await this.mediaSourceResolver.resolveMediaSource(itemId, mediaSourceId, maxStreamingBitrate, startTimeTicks,
      audioStreamIndex, subtitleStreamIndex, playWhenReady)
    this.viewModel.load(itemId,res)
    return null
  }
}