import jellyfin from 'sdk'
import { ActivityEvents } from '../events/ActivityEvent'

const TAG = 'NativeInterface'
export class NativeInterface {

  getDeviceInformation(): string {
    console.log(TAG, 'getDeviceInformation');
    let deviceInfo = jellyfin.deviceInfo
    let clientInfo = jellyfin.clientInfo
    return JSON.stringify(new Object({
      "deviceId": deviceInfo.id,
      "deviceName": deviceInfo.name,
      "appName": clientInfo.name,
      "appVersion": clientInfo.version
    }))
  }

  enableFullscreen(): boolean {
    console.log(TAG, 'enableFullscreen');
    emitEvent(ActivityEvents.CHANGE_FULLSCREEN, true)
    return true
  }

  disableFullscreen(): boolean {
    console.log(TAG, 'disableFullscreen');
    emitEvent(ActivityEvents.CHANGE_FULLSCREEN, false)
    return true
  }

  openUrl(uri: string): boolean {
    console.log(TAG, 'openUrl');
    emitEvent(ActivityEvents.OPEN_URL, uri)
    return true
  }

  updateMediaSession(args: string): boolean {
    console.log(TAG, 'updateMediaSession');
    return true
  }

  hideMediaSession(): boolean {
    console.log(TAG, 'hideMediaSession');
    return true
  }

  updateVolumeLevel(value: number) {
    console.log(TAG, 'updateVolumeLevel');
  }

  downloadFiles(args: string): boolean {
    console.log(TAG, 'downloadFiles');
    return true
  }

  openClientSettings() {
    console.log(TAG, 'openClientSettings');
    emitEvent(ActivityEvents.OPEN_SETTINGS)
  }

  openServerSelection() {
    console.log(TAG, 'openServerSelection');
    emitEvent(ActivityEvents.SELECT_SERVER)
  }

  exitApp() {
    console.log(TAG, 'exitApp');
    emitEvent(ActivityEvents.EXIT_APP)
  }
}

function emitEvent(event: string, ...args: Object[]) {
  getContext().eventHub.emit(event, ...args)
}