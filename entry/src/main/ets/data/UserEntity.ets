import relationalStore from '@ohos.data.relationalStore'

// 定义常量
const TABLE_NAME = 'User'
const ID = 'id'
const SERVER_ID = 'server_id'
const USER_ID = 'user_id'
const ACCESS_TOKEN = 'access_token'
const LAST_LOGIN_TIMESTAMP = 'last_login_timestamp'

// 定义实体类
class UserEntity {
  id: number = 0
  serverId: number = 0
  userId: string = ''
  accessToken: string | null = null
  lastLoginTimestamp: number = 0

  // 构造函数
  constructor(
    serverId?: number,
    userId?: string,
    accessToken?: string | null
  ) {
    if (serverId !== undefined && userId !== undefined) {
      this.serverId = serverId
      this.userId = userId
      this.accessToken = accessToken || null
      this.lastLoginTimestamp = Date.now()
    }
  }

  // 创建表的SQL语句
  static getCreateTableSql(): string {
    return `
      CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
        ${ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${SERVER_ID} INTEGER NOT NULL,
        ${USER_ID} TEXT NOT NULL,
        ${ACCESS_TOKEN} TEXT,
        ${LAST_LOGIN_TIMESTAMP} INTEGER NOT NULL,
        UNIQUE(${SERVER_ID}, ${USER_ID}),
        FOREIGN KEY(${SERVER_ID}) REFERENCES Server(id)
      )
    `
  }

  // 转换为数据库值映射
  toValuesBucket(): relationalStore.ValuesBucket {
    return {
      SERVER_ID: this.serverId,
      USER_ID: this.userId,
      ACCESS_TOKEN: this.accessToken,
      LAST_LOGIN_TIMESTAMP: this.lastLoginTimestamp
    }
  }

  // 从数据库结果创建实例
  static fromResultSet(resultSet: relationalStore.ResultSet): UserEntity {
    const user = new UserEntity()
    user.id = resultSet.getLong(resultSet.getColumnIndex(ID))
    user.serverId = resultSet.getLong(resultSet.getColumnIndex(SERVER_ID))
    user.userId = resultSet.getString(resultSet.getColumnIndex(USER_ID))
    user.accessToken = resultSet.getString(resultSet.getColumnIndex(ACCESS_TOKEN))
    user.lastLoginTimestamp = resultSet.getLong(resultSet.getColumnIndex(LAST_LOGIN_TIMESTAMP))
    return user
  }
}

export default UserEntity