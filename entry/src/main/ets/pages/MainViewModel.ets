import { ApiClientController } from '../data/ApiClientController'
import { ServerEntity } from '../data/ServerEntity'

@Observed
export class MainViewModel {

  apiClientController: ApiClientController
  serverState: ServerState = new ServerState()

  constructor() {
    this.serverState = ServerState.Unset
    this.apiClientController = new ApiClientController()
    this.refreshServer()
  }

  async refreshServer() {
    let serverEntity = await this.apiClientController.loadSavedServer()
    this.serverState = serverEntity ? ServerState.Available : ServerState.Unset
    if (serverEntity) {
      this.serverState.server = serverEntity!
    }
  }

  switchServer(hostname: string) {
    this.apiClientController.setupServer(hostname)
    this.refreshServer()
  }
}

export class ServerState {
  server?: ServerEntity
  static Pending: ServerState
  static Unset: ServerState
  static Available: ServerState
}