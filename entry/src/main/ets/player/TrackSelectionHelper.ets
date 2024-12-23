import { MediaStream, SubtitleDeliveryMethod } from "sdk/src/main/ets/generated-client/models";
import { PlayerViewModel } from "../features/player/PlayerViewModel";
import { JellyfinMediaSource } from "./source/JellyfinMediaSource";

export class TrackSelectionHelper {
  viewModel: PlayerViewModel

  constructor(viewModel: PlayerViewModel) {
    this.viewModel = viewModel
  }

  selectSubtitleTrack(mediaStream: MediaStream): boolean {
    let mediaSource = this.viewModel.mediaSourceOrNull
    if (!mediaSource) {
      return false
    }
    if (mediaStream?.DeliveryMethod == SubtitleDeliveryMethod.Encode) {
      return this.viewModel.queueManager.selectSubtitleStreamAndRestartPlayback(mediaStream)
    }
    return this.selectSubtitleTrack3(mediaSource, mediaStream, false)
  }

  selectSubtitleTrack3(mediaSource: JellyfinMediaSource, subtitleStream: MediaStream, initial: boolean): boolean {
    // Fast-pass: Skip execution on subsequent calls with the same selection
    if (!initial && subtitleStream === mediaSource.selectedSubtitleStream) {
      return true
    } else if (!mediaSource.selectSubtitleStream(subtitleStream)) {// Apply selection in media source, abort on failure
      return false
    }

    // Apply selection in player
    if (subtitleStream == null) {
      // If no subtitle is selected, simply clear the selection and disable the subtitle renderer
      // trackSelector.clearSelectionAndDisableRendererByType(C.TRACK_TYPE_TEXT)
      return true
    }
    let player = this.viewModel.playerOrNull
    if(!player) return false
    switch (subtitleStream.DeliveryMethod){

      default :
        return false
    }
  }
}