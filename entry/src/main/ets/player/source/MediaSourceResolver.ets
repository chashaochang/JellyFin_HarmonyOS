import { getItemsApi, getMediaInfoApi, PlaybackInfoResponse } from "sdk"
import { ApiClient } from "../../network/ApiClient"
import { BusinessError } from "@kit.BasicServicesKit";
import { AxiosResponse } from "@ohos/axios";
import { JellyfinMediaSource } from "./JellyfinMediaSource";
import { BaseItemDtoQueryResult, DeviceProfile } from "sdk/src/main/ets/generated-client/models";

export class MediaSourceResolver {
  resolveMediaSource(itemId: string,
    mediaSourceId: string | null,
    deviceProfile: DeviceProfile | null,
    maxStreamingBitrate: number | null | undefined,
    startTimeTicks: number | null,
    audioStreamIndex: number | null,
    subtitleStreamIndex: number | null,
    autoOpenLiveStream: boolean = true): Promise<JellyfinMediaSource> | null {

    return new Promise<JellyfinMediaSource>((resolve, reject) => {
      getMediaInfoApi(ApiClient.Instance()).getPostedPlaybackInfo({
        itemId: itemId,
        playbackInfoDto:{
          UserId:AppStorage.get('userId'),
          // We need to remove the dashes so that the server can find the correct media source.
          // And if we didn't pass the mediaSourceId, our stream indices would silently get ignored.
          // https://github.com/jellyfin/jellyfin/blob/9a35fd673203cfaf0098138b2768750f4818b3ab/Jellyfin.Api/Helpers/MediaInfoHelper.cs#L196-L201
          MediaSourceId: mediaSourceId ?? itemId,
          DeviceProfile : deviceProfile,
          MaxStreamingBitrate : maxStreamingBitrate,
          StartTimeTicks : startTimeTicks,
          AudioStreamIndex: audioStreamIndex,
          SubtitleStreamIndex : subtitleStreamIndex,
          AutoOpenLiveStream : autoOpenLiveStream,
        }
        // subtitleStreamIndex: subtitleStreamIndex,
        // autoOpenLiveStream: autoOpenLiveStream,
      }).then((res: AxiosResponse<PlaybackInfoResponse>) => {
        if (res.data.PlaySessionId) {
          let playSessionId = res.data.PlaySessionId
          let mediaSourceInfo = res.data.MediaSources?.find(source => source.Id == itemId)
          if (mediaSourceInfo) {
            getItemsApi(ApiClient.Instance()).getItems({
              ids: Array.of(itemId)
            }).then((res: AxiosResponse<BaseItemDtoQueryResult>) => {
              let items = res.data.Items
              if (items && items.length > 0) {
                resolve(new JellyfinMediaSource(itemId, items[0], mediaSourceInfo!, playSessionId,
                  mediaSourceInfo!.LiveStreamId, maxStreamingBitrate, startTimeTicks, audioStreamIndex,
                  subtitleStreamIndex))
              }
            }).catch((e: BusinessError) => {
              reject(e)
            })
          } else {
            reject(new Error('NetworkFailure'))
          }
        } else {
          reject(new Error('UnsupportedContent'))
        }
      }).catch((e: BusinessError) => {
        reject(e)
      })
    })


  }
}