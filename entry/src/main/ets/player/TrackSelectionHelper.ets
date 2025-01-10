import { IjkMediaPlayer } from "@ohos/ijkplayer";
import {
  MediaStream,
  MediaStreamType,
  PlayMethod,
  SubtitleDeliveryMethod
} from "sdk/src/main/ets/generated-client/models";
import { PlayerViewModel } from "../features/player/PlayerViewModel";
import { JellyfinMediaSource } from "./source/JellyfinMediaSource";

const TAG = 'TrackSelectionHelper'
export class TrackSelectionHelper {
  viewModel: PlayerViewModel

  constructor(viewModel: PlayerViewModel) {
    this.viewModel = viewModel
  }

  get mediaSourceOrNull(): JellyfinMediaSource | undefined {
    return this.viewModel.mediaSourceOrNull
  }

  selectInitialTracks() {
    if (!this.mediaSourceOrNull) {
      return
    }
    let mediaSource = this.mediaSourceOrNull
    if (mediaSource.selectedAudioStream) {
      this.selectPlayerAudioTrack(mediaSource, mediaSource.selectedAudioStream, true)
    }
    this.selectSubtitleTrack3(mediaSource, mediaSource.selectedSubtitleStream, true)
  }

  /**
   * Select an audio track in the media source and apply changes to the current player, if necessary and possible.
   *
   * @param mediaStreamIndex the [MediaStream.index] that should be selected
   * @return true if the audio track was changed
   */
  selectAudioTrack(selectedMediaStream: MediaStream): boolean {
    let mediaSource = this.viewModel.mediaSourceOrNull
    if (!mediaSource) {
      return false
    }
    if (selectedMediaStream.Type != MediaStreamType.Audio) {
      throw new Error('Selected stream must be an audio stream');
    }

    // For transcoding and external streams, we need to restart playback
    if (mediaSource.playMethod == PlayMethod.Transcode || selectedMediaStream.IsExternal) {
      return this.viewModel.queueManager.selectAudioStreamAndRestartPlayback(selectedMediaStream)
    }
    let success = this.selectPlayerAudioTrack(mediaSource, selectedMediaStream, false)
    if (success) {
      this.viewModel.logTracks()
    }
    return success
  }

  private selectPlayerAudioTrack(mediaSource: JellyfinMediaSource, audioStream: MediaStream,
    initial: boolean): boolean {
    if (mediaSource.playMethod == PlayMethod.Transcode) {
      // Transcoding does not require explicit audio selection
      return true
    }
    if (mediaSource.audioStreams.length == 1 || !initial && audioStream === mediaSource.selectedAudioStream) {
      return true
    }
    if (!mediaSource.selectAudioStream(audioStream)) {
      return false
    }
    //let embeddedStreamIndex = mediaSource.getEmbeddedStreamIndex(audioStream)
    if (this.viewModel.uiState.audioTrackIndex && this.viewModel.uiState.audioTrackIndex > 0) {
      console.log(TAG,'deselectTrack:'+this.viewModel.uiState.audioTrackIndex);
      IjkMediaPlayer.getInstance().deselectTrack(this.viewModel.uiState.audioTrackIndex + '')
    }
    console.log(TAG,'selectTrack:' + audioStream.Index);
    IjkMediaPlayer.getInstance().selectTrack(audioStream.Index + '')
    return true
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

  selectSubtitleTrack3(mediaSource: JellyfinMediaSource, subtitleStream: MediaStream | undefined,
    initial: boolean): boolean {
    // Fast-pass: Skip execution on subsequent calls with the same selection
    if (!initial && subtitleStream === mediaSource.selectedSubtitleStream) {
      return true
    } else if (!mediaSource.selectSubtitleStream(subtitleStream)) { // Apply selection in media source, abort on failure
      return false
    }

    // Apply selection in player
    if (subtitleStream == null) {
      // If no subtitle is selected, simply clear the selection and disable the subtitle renderer
      // trackSelector.clearSelectionAndDisableRendererByType(C.TRACK_TYPE_TEXT)
      this.viewModel.uiState.currentSubtitle = ''
      this.viewModel.uiState.subtitles = []
      return true
    }
    // let player = this.viewModel.playerOrNull
    // if(!player) return false
    switch (subtitleStream.DeliveryMethod) {
        case SubtitleDeliveryMethod.Encode:
          // Normally handled in selectSubtitleTrack(int) by restarting playback,
          // initial selection is always considered successful
          return true
        case SubtitleDeliveryMethod.Embed:
          // For embedded subtitles, we can match by the index of this stream in all embedded streams.
          // let embeddedStreamIndex = mediaSource.getEmbeddedStreamIndex(subtitleStream)
          // let subtitle = this.viewModel.initSource?.subtitleStreams[embeddedStreamIndex]
          // if(!subtitle) return false
          this.viewModel.selectSubtitle(subtitleStream)
          return true
      case SubtitleDeliveryMethod.External:
        // For external subtitles, we can simply match the ID that we set when creating the player media source.
        // for (group in player.currentTracks.groups) {
        //   if (group.getTrackFormat(0).id == "${ExternalSubtitleStream.ID_PREFIX}${subtitleStream.index}") {
        //     return trackSelector.selectTrackByTypeAndGroup(C.TRACK_TYPE_TEXT, group.mediaTrackGroup)
        //   }
        // }
        return false
      default:
        return false
    }
  }
}