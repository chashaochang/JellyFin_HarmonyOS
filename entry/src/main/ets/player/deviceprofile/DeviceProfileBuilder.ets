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

/**
 * List of PCM codecs supported by default
 */
const  PCM_CODECS: Array<string> = [
  "pcm_s8",
  "pcm_s16be",
  "pcm_s16le",
  "pcm_s24le",
  "pcm_s32le",
  "pcm_f32le",
  "pcm_alaw",
  "pcm_mulaw"
];

/**
 * IMPORTANT: Must have same length as SUPPORTED_CONTAINER_FORMATS,
 * as it maps the codecs to the containers with the same index!
 */
const  AVAILABLE_AUDIO_CODECS: Array<Array<string>> = [
// mp4
  ["mp1", "mp2", "mp3", "aac", "alac", "ac3", "opus"],

  // fmp4
  ["mp3", "aac", "ac3", "eac3"],

  // webm
  ["vorbis", "opus"],

  // mkv
  [...PCM_CODECS, "mp1", "mp2", "mp3", "aac", "vorbis", "opus",
    "flac", "alac", "ac3", "eac3", "dts", "mlp", "truehd"],

  // mp3
  ["mp3"],

  // ogg
  ["vorbis", "opus", "flac"],

  // wav
  PCM_CODECS,

  // mpegts
  [...PCM_CODECS, "mp1", "mp2", "mp3", "aac", "ac3",
    "eac3", "dts", "mlp", "truehd"],

  // flv
  ["mp3", "aac"],

  // aac
  ["aac"],

  // flac
  ["flac"],

  // 3gp
  ["3gpp", "aac", "flac"]
];
/**
 * List of container formats supported by default
 *
 * IMPORTANT: Don't change without updating AVAILABLE_VIDEO_CODECS and AVAILABLE_AUDIO_CODECS
 */
const SUPPORTED_CONTAINER_FORMATS: Array<string> = [
  "mp4",
  "fmp4",
  "webm",
  "mkv",
  "mp3",
  "ogg",
  "wav",
  "mpegts",
  "flv",
  "aac",
  "flac",
  "3gp"
];

/***
 *
 */
export class DeviceProfileBuilder {

  getDeviceProfile(): DeviceProfile {

    return {
      Name: Constants.APP_INFO_NAME,
      DirectPlayProfiles: [{ Type:DlnaProfileType.Video },{ Type:DlnaProfileType.Audio }],
      TranscodingProfiles: [
        {
          Type : DlnaProfileType.Video,
          Container : "ts",
          VideoCodec : "h264",
          AudioCodec : "mp1,mp2,mp3,aac,ac3,eac3,dts,mlp,truehd",
          Protocol : "hls",
          Conditions : [],
        },
        {
          Type : DlnaProfileType.Video,
          Container : "mkv",
          VideoCodec : "h264",
          AudioCodec : AVAILABLE_AUDIO_CODECS[SUPPORTED_CONTAINER_FORMATS.indexOf("mkv")].join(","),
          Protocol : "hls",
          Conditions : [],
        },
        {
          Type : DlnaProfileType.Audio,
          Container : "mp3",
          VideoCodec : "",
          AudioCodec : "mp3",
          Protocol : "http",
          Conditions : [],
        },
      ],
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