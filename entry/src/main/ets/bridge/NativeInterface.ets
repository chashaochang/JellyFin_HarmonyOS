import jellyfin from 'sdk'
import { ActivityEvents } from '../events/ActivityEvent'
import { ActivityEventHandler } from '../events/ActivityEventHandler';

const TAG = 'NativeInterface'
export class NativeInterface {

  activityEventHandler:ActivityEventHandler

  constructor(activityEventHandler:ActivityEventHandler) {
    this.activityEventHandler = activityEventHandler
  }

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
    this.emitEvent(ActivityEvents.CHANGE_FULLSCREEN, true)
    return true
  }

  disableFullscreen(): boolean {
    console.log(TAG, 'disableFullscreen');
    this.emitEvent(ActivityEvents.CHANGE_FULLSCREEN, false)
    return true
  }

  openUrl(uri: string): boolean {
    console.log(TAG, 'openUrl');
    this.emitEvent(ActivityEvents.OPEN_URL, uri)
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
    this.emitEvent(ActivityEvents.OPEN_SETTINGS)
  }

  openServerSelection() {
    console.log(TAG, 'openServerSelection');
    this.emitEvent(ActivityEvents.SELECT_SERVER)
  }

  exitApp() {
    console.log(TAG, 'exitApp');
    this.emitEvent(ActivityEvents.EXIT_APP)
  }

  emitEvent(event: string, ...args: Object[]) {
    this.activityEventHandler.eventHub.emit(event, ...args)
  }
}

