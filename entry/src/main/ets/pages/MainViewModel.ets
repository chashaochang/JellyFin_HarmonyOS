import { ApiClientController } from '../data/ApiClientController'
import ServerEntity from '../data/ServerEntity'

@Observed
export class MainViewModel {

  apiClientController: ApiClientController
  serverState: ServerState = new ServerState()

  constructor() {
    this.serverState = ServerState.Unset
    this.apiClientController = new ApiClientController()
  }

  async refreshServer() {
    let serverEntity = await this.apiClientController.loadSavedServer()
    if (serverEntity) {
      ServerState.Available = new ServerState()
      ServerState.Available.server = serverEntity!
    }
    this.serverState = serverEntity ? ServerState.Available : ServerState.Unset
  }

  switchServer(hostname: string) {
    this.apiClientController.setupServer(hostname)
    this.refreshServer()
  }
}

@Observed
export class ServerState {
  server?: ServerEntity
  static Pending: ServerState
  static Unset: ServerState
  static Available: ServerState
}