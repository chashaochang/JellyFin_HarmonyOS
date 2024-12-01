import { AxiosInstance } from "@ohos/axios";
import { Api } from "./api";
import { DiscoveryService } from "./discovery/discovery-service";
import { ClientInfo } from "./models/client-info";
import { DeviceInfo } from "./models/device-info";
import { deviceInfo } from '@kit.BasicServicesKit';
import { bundleManager } from "@kit.AbilityKit";

/** Parameters to create a Jellyfin SDK instance. */
export interface JellyfinParameters {
  clientInfo: ClientInfo,
  deviceInfo: DeviceInfo
}
/** Class representing the Jellyfin SDK. */
export class Jellyfin {
  clientInfo: ClientInfo;
  deviceInfo:DeviceInfo;
  discovery:DiscoveryService;

  constructor(parameters: JellyfinParameters) {
    this.clientInfo = parameters.clientInfo;
    this.deviceInfo = parameters.deviceInfo;
    this.discovery = new DiscoveryService(this);
  }

  /**
   * Creates an Api instance for a given server path.
   * @param basePath A base path of a server.
   * @param accessToken An (optional) access token to use for authentication.
   * @param axiosInstance An (optional) Axios instance for the Api to use.
   * @returns An Api instance.
   */
  createApi(basePath: string, accessToken?: string, axiosInstance?: AxiosInstance): Api {
    return new Api(basePath, this.clientInfo, this.deviceInfo, accessToken, axiosInstance);
  }
}

// Create a new instance of the SDK
const jellyfin = new Jellyfin({
  clientInfo: {
    name: 'JellyFin_HarmonyOS',
    version: bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).versionName
  },
  deviceInfo: {
    name: deviceInfo.marketName,
    id: deviceInfo.ODID
  }
});

export default jellyfin