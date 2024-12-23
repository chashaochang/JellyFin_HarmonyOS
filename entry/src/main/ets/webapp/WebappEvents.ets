import { common } from "@kit.AbilityKit"

const NAVIGATION_HELPER = "window.NavigationHelper"
const PLAYBACK_MANAGER = `${NAVIGATION_HELPER}.playbackManager`

export class WebappEvents {
  context: common.Context

  constructor(context: common.Context) {
    this.context = context
  }

  // Web component helpers
  callPlaybackManagerAction(action: String) {
    this.call(`${PLAYBACK_MANAGER}.${action}();`)
  }

  setVolume(volume: number) {
    this.call(`${PLAYBACK_MANAGER}.sendCommand({Name: 'SetVolume', Arguments: { Volume: ${volume} }});`)
  }

  seekTo(pos: number) {
    this.call(`${PLAYBACK_MANAGER}.seekMs(${pos});`)
  }

  call(action: string) {
    this.context.eventHub.emit('webappFunction', action)
  }

  goBack(): boolean {
    this.call(`${NAVIGATION_HELPER}.goBack();`)
    return true
  }
}