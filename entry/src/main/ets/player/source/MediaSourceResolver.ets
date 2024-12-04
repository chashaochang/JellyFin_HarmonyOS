import { getMediaInfoApi, PlaybackInfoResponse } from "sdk"
import { ApiClient } from "../../network/ApiClient"
import { BusinessError } from "@kit.BasicServicesKit";
import { AppPreference } from "../../data/AppPreference";
import { AxiosResponse } from "@ohos/axios";

export class MediaSourceResolver {
  resolveMediaSource(itemId: string,
    mediaSourceId: string | null,
    // deviceProfile: DeviceProfile | null,
    maxStreamingBitrate: number | null,
    startTimeTicks: number | null,
    audioStreamIndex: number | null,
    subtitleStreamIndex: number | null,
    autoOpenLiveStream: boolean = true):Promise<PlaybackInfoResponse>|null {

    return new Promise<PlaybackInfoResponse>((resolve,reject)=>{
      getMediaInfoApi(ApiClient.Instance()).getPostedPlaybackInfo({
        itemId: itemId,
        userId:AppStorage.get('userId'),
        mediaSourceId:mediaSourceId??itemId,
        audioStreamIndex:audioStreamIndex,
        subtitleStreamIndex:subtitleStreamIndex,
        autoOpenLiveStream:autoOpenLiveStream,
      }).then((res:AxiosResponse<PlaybackInfoResponse>)=>{
        // let playSessionId = res.data.PlaySessionId
        // let mediaInfo = res.data.MediaSources?.find(e=>e.Id === itemId)
        // console.log(`playSessionId:${playSessionId}`);
        // console.table(mediaInfo)
        resolve(res.data)
      }).catch((e:BusinessError)=>{
        reject(e)
      })
    })


  }
}