import UserEntity from './UserEntity'
import ServerEntity from './ServerEntity'
import { relationalStore } from '@kit.ArkData'

class ServerUser {
  user: UserEntity
  server: ServerEntity

  constructor(user: UserEntity, server: ServerEntity) {
    this.user = user
    this.server = server
  }

  // 从数据库查询结果创建实例的方法
  static fromQueryResult(
    userResultSet: relationalStore.ResultSet,
    serverResultSet: relationalStore.ResultSet
  ): ServerUser {
    const user = UserEntity.fromResultSet(userResultSet)
    const server = ServerEntity.fromResultSet(serverResultSet)
    return new ServerUser(user, server)
  }

  // 查询示例方法（仅作参考）
  static async findServerUserByUserId(
    rdbStore: relationalStore.RdbStore,
    userId: string
  ): Promise<ServerUser | null> {
    const predicates = new relationalStore.RdbPredicates('User')
    predicates.equalTo('user_id', userId)

    try {
      const resultSet = await rdbStore.query(predicates)
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow()

        // 假设需要关联查询 Server 表
        const serverId = resultSet.getLong(resultSet.getColumnIndex('server_id'))
        const serverPredicates = new relationalStore.RdbPredicates('Server')
        serverPredicates.equalTo('id', serverId)

        const serverResultSet = await rdbStore.query(serverPredicates)
        if (serverResultSet.rowCount > 0) {
          serverResultSet.goToFirstRow()

          return ServerUser.fromQueryResult(resultSet, serverResultSet)
        }
      }
      return null
    } catch (error) {
      console.error('Query error', error)
      return null
    }
  }
}

export default ServerUser