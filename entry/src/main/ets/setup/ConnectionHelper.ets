import jellyfin, { PublicSystemInfo, RecommendedServerInfo } from "sdk"
import { DiscoveryService } from "sdk/src/main/ets/discovery/discovery-service"
import { ServerDiscoveryInfo } from "sdk/src/main/ets/generated-client/models"
import { RecommendedServerInfoScore } from "sdk/src/main/ets/models/recommended-server-info"
import { CheckUrlState } from "../ui/state/CheckUrlState"

class ConnectionHelper {
  async checkServerUrl(enteredUrl: string): Promise<CheckUrlState> {
    let candidates = jellyfin.discovery.getAddressCandidates(enteredUrl)
    const badServers: RecommendedServerInfo[] = []
    const goodServers: RecommendedServerInfo[] = []
    let servers = await jellyfin.discovery.getRecommendedServers(candidates)
    let greatServer = servers.find((e: RecommendedServerInfo) => {
      switch (e.score) {
        case RecommendedServerInfoScore.GREAT:
          return true
        case RecommendedServerInfoScore.GOOD:
          goodServers.push(e)
          return false
        case RecommendedServerInfoScore.OK:
        case RecommendedServerInfoScore.BAD:
          badServers.push(e)
          return false
      }
    })
    const server = greatServer ?? goodServers[0]
    if (server) {
      const systemInfo:PublicSystemInfo|undefined = server.systemInfo
      const serverVersion = systemInfo?.Version
      console.log(`Found valid server at ${server.address} with rating ${server.score} and version ${serverVersion}`)
      let suc = CheckUrlState.Success
      suc.address = server.address
      return suc
    }
    const loggedServers = badServers.map(it => `${it.address}/${it.systemInfo}`).join(', ')
    console.log(`No valid servers found, invalid candidates were: ${loggedServers}`)
    let error: string | null = null

    if (badServers.length > 0) {
      const count = badServers.length
      const unreachableServers = badServers.filter(result => result.systemInfo == null)
      const incompatibleServers = badServers.filter(result => result.systemInfo != null)

      let errorMessage = `${count} connection error(s)`

      if (unreachableServers.length > 0) {
        errorMessage += '\n\nUnable to reach server(s):\n'
        errorMessage += unreachableServers.map(result => `· ${result.address}`).join('\n')
      }

      if (incompatibleServers.length > 0) {
        errorMessage += '\n\nUnsupported version or product:\n'
        errorMessage += incompatibleServers.map(result => `· ${result.address}`).join('\n')
      }

      error = errorMessage
    }
    let err = CheckUrlState.Error
    err.message = error??''
    return err
  }

  async discoverServers(): Promise<ServerDiscoveryInfo[]>{
    return await jellyfin.discovery.discoverLocalServers()
  }
}

const connectionHelper = new ConnectionHelper()

export default connectionHelper