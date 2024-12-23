import { getItemsApi, getMediaInfoApi, PlaybackInfoResponse } from "sdk"
import { ApiClient } from "../../network/ApiClient"
import { BusinessError } from "@kit.BasicServicesKit";
import { AppPreference } from "../../data/AppPreference";
import { AxiosResponse } from "@ohos/axios";
import { JellyfinMediaSource } from "./JellyfinMediaSource";
import { BaseItemDtoQueryResult } from "sdk/src/main/ets/generated-client/models";

export class MediaSourceResolver {
  resolveMediaSource(itemId: string,
    mediaSourceId: string | null,
    // deviceProfile: DeviceProfile | null,
    maxStreamingBitrate: number | null,
    startTimeTicks: number | null,
    audioStreamIndex: number | null,
    subtitleStreamIndex: number | null,
    autoOpenLiveStream: boolean = true): Promise<JellyfinMediaSource> | null {

    return new Promise<JellyfinMediaSource>((resolve, reject) => {
      getMediaInfoApi(ApiClient.Instance()).getPostedPlaybackInfo({
        itemId: itemId,
        userId: AppStorage.get('userId'),
        mediaSourceId: mediaSourceId ?? itemId,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        autoOpenLiveStream: autoOpenLiveStream,
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