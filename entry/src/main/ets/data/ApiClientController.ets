import { ObjectUtil } from "@pura/harmony-utils";
import jellyfin from "sdk/src/main/ets/jellyfin";
import { ApiClient } from "../network/ApiClient";
import { AppPreference } from "./AppPreference";
import { ServerDao } from "./ServerDao";
import ServerEntity from "./ServerEntity";
import { UserDao } from "./UserDao";

export class ApiClientController {

  appPreference: AppPreference
  serverDao: ServerDao
  userDao: UserDao
  baseDeviceInfo = jellyfin.deviceInfo

  constructor() {
    this.appPreference = AppPreference.getInstance()
    this.serverDao = new ServerDao()
    this.userDao = new UserDao()
  }

  async setupUser(serverId: number, userId: string, accessToken: string) {
    //let id = await this.userDao.upsert(serverId,userId,accessToken)
    //await this.appPreference.setCurrentUserId(id)
    this.configureApiClientUser(userId, accessToken)
  }

  async setupServer(hostname: string) {
    let server = this.serverDao.getServerByHostname(hostname)
    if (!server) {
      this.serverDao.insert(hostname)
    } else {
      this.appPreference.setCurrentServerId(server.id)
    }
    ApiClient.init(hostname)
  }

  async loadSavedServer(): Promise<ServerEntity | null> {
    let server: ServerEntity | null = null
    let serverId = await this.appPreference.getCurrentServerId()
    if (serverId) {
      server = this.serverDao.getServer(serverId)
    }
    this.configureApiClientServer(server)
    return server
  }

  loadPreviouslyUsedServers():ServerEntity[] {
    return this.serverDao.getAllServers().filter(async server=>{
      server.id === await this.appPreference.getCurrentServerId()
    })
  }

  configureApiClientServer(server: ServerEntity | null) {
    if(server){
      ApiClient.init(server?.hostname)
    }
  }

  configureApiClientUser(userId: string, accessToken: string) {
    ApiClient.Instance().userId = userId
    ApiClient.Instance().accessToken = accessToken
    // Append user id to device id to ensure uniqueness across sessions
    let info = ObjectUtil.deepCopy(this.baseDeviceInfo)
    info.id = this.baseDeviceInfo.id + userId
    ApiClient.Instance().deviceInfo = info
  }
}