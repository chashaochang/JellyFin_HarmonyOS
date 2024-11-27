import { ApiClient } from "../network/ApiClient";
import { AppPreference } from "./AppPreference";
import { ServerDao } from "./ServerDao";
import { ServerEntity } from "./ServerEntity";

export class ApiClientController {
  appPreference: AppPreference
  serverDao: ServerDao
  apiClient: ApiClient

  constructor() {
    this.appPreference = AppPreference.getInstance()
    this.serverDao = new ServerDao()
    this.apiClient = new ApiClient()
  }

  setupServer(hostname: string) {
    let server = this.serverDao.getServerByHostname(hostname)
    if (!server) {
      this.serverDao.insert(hostname)
    } else {
      this.appPreference.setCurrentServerId(server.id)
    }
    this.apiClient.baseUrl = hostname
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

  configureApiClientServer(server: ServerEntity | null) {
    this.apiClient.baseUrl = server?.hostname
  }
}