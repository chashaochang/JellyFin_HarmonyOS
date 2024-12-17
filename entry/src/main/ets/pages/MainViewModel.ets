import { ApiClientController } from '../data/ApiClientController'

export enum ServerState {
  Pending,
  Unset,
  Available
}

@ObservedV2
export class MainViewModel {
  apiClientController: ApiClientController
  @Trace serverState: ServerState = ServerState.Unset

  constructor() {
    this.apiClientController = new ApiClientController()
  }

  async refreshServer() {
    let serverEntity = await this.apiClientController.loadSavedServer()
    if (serverEntity) {
      AppStorage.setOrCreate('server', serverEntity)
    }
    this.serverState = serverEntity ? ServerState.Available : ServerState.Unset
  }

  async switchServer(hostname: string) {
    await this.apiClientController.setupServer(hostname)
    await this.refreshServer()
  }
}

const mainViewModel = new MainViewModel()

export default mainViewModel

