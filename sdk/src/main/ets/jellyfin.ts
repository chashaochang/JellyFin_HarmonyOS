import { AxiosInstance } from "@ohos/axios";
import { Api } from "./api";
import { DiscoveryService } from "./discovery/discovery-service";
import { ClientInfo } from "./models/client-info";
import { DeviceInfo } from "./models/device-info";

/** Parameters to create a Jellyfin SDK instance. */
export interface JellyfinParameters {
  clientInfo: ClientInfo,
  deviceInfo: DeviceInfo
}
/** Class representing the Jellyfin SDK. */
export class Jellyfin {
  clientInfo;
  deviceInfo;
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
    name: 'JellyFin_Harmonyos',
    version: '1.0.0'
  },
  deviceInfo: {
    name: 'Device Name',
    id: 'unique-device-id'
  }
});

export default jellyfin