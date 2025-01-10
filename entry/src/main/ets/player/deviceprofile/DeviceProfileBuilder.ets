import { DeviceProfile } from "sdk";
import {
  DlnaProfileType,
  SubtitleDeliveryMethod,
} from "sdk/src/main/ets/generated-client/models";
import { Constants } from "../../utils/Constants";

/**
 * Taken from Jellyfin Web:
 * https://github.com/jellyfin/jellyfin-web/blob/de690740f03c0568ba3061c4c586bd78b375d882/src/scripts/browserDeviceProfile.js#L276
 */
const MAX_STREAMING_BITRATE = 120000000

/**
 * Taken from Jellyfin Web:
 * https://github.com/jellyfin/jellyfin-web/blob/de690740f03c0568ba3061c4c586bd78b375d882/src/scripts/browserDeviceProfile.js#L372
 */
const MAX_STATIC_BITRATE = 100000000

/**
 * Taken from Jellyfin Web:
 * https://github.com/jellyfin/jellyfin-web/blob/de690740f03c0568ba3061c4c586bd78b375d882/src/scripts/browserDeviceProfile.js#L373
 */
const MAX_MUSIC_TRANSCODING_BITRATE = 384000

/***
 *
 */
export class DeviceProfileBuilder {

  getDeviceProfile(): DeviceProfile {

    return {
      Name: Constants.APP_INFO_NAME,
      DirectPlayProfiles: [{ Type:DlnaProfileType.Video },{ Type:DlnaProfileType.Audio }],
      TranscodingProfiles: [],
      ContainerProfiles: [],
      CodecProfiles: [],
      SubtitleProfiles: [{
        Format:'ass',
        Method:SubtitleDeliveryMethod.Embed
      },{
        Format:'srt',
        Method:SubtitleDeliveryMethod.Embed
      }],
      MaxStreamingBitrate: MAX_STREAMING_BITRATE,
      MaxStaticBitrate: MAX_STATIC_BITRATE,
      MusicStreamingTranscodingBitrate: MAX_MUSIC_TRANSCODING_BITRATE,
    }
  }

}