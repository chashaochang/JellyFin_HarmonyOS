import { ApiClientController } from '../data/ApiClientController'

export enum ServerState {
  Pending = 0,
  Unset = 1,
  Available = 2
}

@ObservedV2
export class MainViewModel {

  apiClientController: ApiClientController
  @Trace serverState: ServerState = ServerState.Unset
  @Monitor('serverState') onStateChanged(monitor: IMonitor){
    monitor.dirty.forEach((path: string) => {
      console.log(`${path} changed from ${monitor.value(path)?.before} to ${monitor.value(path)?.now}`)
    })
  }

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

  resetServer() {
    this.serverState = ServerState.Unset
  }
}

const mainViewModel = new MainViewModel()

export default mainViewModel

