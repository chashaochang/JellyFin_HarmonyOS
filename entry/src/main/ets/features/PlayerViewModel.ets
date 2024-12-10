import { getVideosApi, PlaybackInfoResponse } from "sdk";
import { ApiClient } from "../network/ApiClient";
import { QueueManager } from "../player/queue/QueueManager";
import { BusinessError } from "@kit.BasicServicesKit";

@Observed
export class PlayerViewModel{

  queueManager:QueueManager = new QueueManager(this)

  load(itemId:string,res: PlaybackInfoResponse | null) {
    let sourceInfo = res?.MediaSources?.find(e=>e.Id === itemId)
    if(sourceInfo?.Protocol == 'File'){
      getVideosApi(ApiClient.Instance()).getVideoStream({
        itemId:itemId,
        _static:true,
        playSessionId :res?.PlaySessionId,
        mediaSourceId:sourceInfo.Id,
        deviceId:ApiClient.Instance().deviceInfo,
      }).then((res:string)=>{

        AppStorage.setOrCreate('url',res)


      }).catch((e:BusinessError)=>{
        console.log(JSON.stringify(e));
      })
    }
  }
}