import { AxiosResponse } from "@ohos/axios";
import { getVideosApi, PlaybackInfoResponse } from "sdk";
import { ApiClient } from "../network/ApiClient";
import { QueueManager } from "../player/queue/QueueManager";
import { BusinessError } from "@kit.BasicServicesKit";
import { StandardGSYVideoModel } from "@ohos/gsyvideoplayer";

@Observed
export class PlayerViewModel{

  queueManager:QueueManager = new QueueManager(this)
  videoModel: StandardGSYVideoModel = new StandardGSYVideoModel();

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

        // 设置播放的url，设置播放不缓存
        this.videoModel.setUrl('https://baikevideo.cdn.bcebos.com/media/mda-Ofj5DOML8EqV0Umy/da4f175769bcf693d0d0e205e1546015.mp4', true);
        this.videoModel.setTitle(sourceInfo?.Name);
        this.videoModel.setBackClickListener(()=>{

        });
        this.videoModel.setFullClickListener(()=>{

        });
      }).catch((e:BusinessError)=>{
        console.log(JSON.stringify(e));
      })
    }
  }
}