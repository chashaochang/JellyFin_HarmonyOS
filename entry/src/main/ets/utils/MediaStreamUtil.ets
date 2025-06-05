import { MediaStream } from "sdk/src/main/ets/generated-client/models"

export class MediaStreamUtil {
  static isLandscape(mediaStream?: MediaStream): boolean {
    if (mediaStream?.Width && mediaStream?.Height) {
      return mediaStream.Width > mediaStream.Height
    } else {
      return true
    }
  }

  // static aspectRational(mediaStream: MediaStream): Rational {
  //   if (mediaStream.Width && mediaStream.Height) {
  //     return mediaStream.Width > mediaStream.Height
  //   } else {
  //     return true
  //   }
  // }
}