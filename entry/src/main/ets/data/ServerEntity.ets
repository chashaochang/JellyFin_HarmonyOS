import relationalStore from '@ohos.data.relationalStore'

// 定义常量
const TABLE_NAME = 'Server'
const ID = 'id'
const HOSTNAME = 'hostname'
const LAST_USED_TIMESTAMP = 'last_used_timestamp'

// 定义实体类
class ServerEntity {
  id: number = 0
  hostname: string = ''
  lastUsedTimestamp: number = 0

  // 构造函数
  constructor(hostname?: string) {
    if (hostname !== undefined) {
      this.hostname = hostname
      this.lastUsedTimestamp = Date.now()
    }
  }

  // 创建表的SQL语句
  static getCreateTableSql(): string {
    return `
      CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
        ${ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${HOSTNAME} TEXT NOT NULL UNIQUE,
        ${LAST_USED_TIMESTAMP} INTEGER NOT NULL
      )
    `
  }

  // 转换为数据库值映射
  toValuesBucket(): relationalStore.ValuesBucket {
    return {
      HOSTNAME: this.hostname,
      LAST_USED_TIMESTAMP: this.lastUsedTimestamp
    }
  }

  // 从数据库结果创建实例
  static fromResultSet(resultSet: relationalStore.ResultSet): ServerEntity {
    const server = new ServerEntity()
    server.id = resultSet.getLong(resultSet.getColumnIndex(ID))
    server.hostname = resultSet.getString(resultSet.getColumnIndex(HOSTNAME))
    server.lastUsedTimestamp = resultSet.getLong(resultSet.getColumnIndex(LAST_USED_TIMESTAMP))
    return server
  }

}

export default ServerEntity