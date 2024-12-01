import jellyfin from 'sdk'

export class NativeInterface {
  getDeviceInformation(): string {
    let deviceInfo = jellyfin.deviceInfo
    let clientInfo = jellyfin.clientInfo
    return JSON.stringify(new Object({
      "deviceId": deviceInfo.id,
      "deviceName": deviceInfo.name,
      "appName": clientInfo.name,
      "appVersion": clientInfo.version
    }))
  }
}