import Rdb from "./Rdb";
import { RdbConstants } from "./RdbConstants";
import { relationalStore } from "@kit.ArkData";
import ServerEntity from "./ServerEntity";
import UserEntity from "./UserEntity";
import { when } from "@ohos/hypium";

export class UserDao {
  private userTable = new Rdb(
    RdbConstants.TABLE_USER.tableName,
    RdbConstants.TABLE_USER.sqlCreate,
    RdbConstants.TABLE_USER.columns
  )

  constructor() {
    this.userTable.getRdbStore()
  }

  getRdbStore() {
    this.userTable.getRdbStore()
  }

  insertDataSync(valuesBucket: relationalStore.ValuesBucket): number {
    return this.userTable.insertDataSync(valuesBucket)
  }

  deleteDataSync(valuesBucket: relationalStore.ValuesBucket): number {
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_USER.tableName)
    predicates.equalTo('id', valuesBucket.id)
    return this.userTable.deleteDataSync(predicates)
  }

  updateDataSync(valuesBucket: relationalStore.ValuesBucket): number {
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_USER.tableName)
    predicates.equalTo('id', valuesBucket.id)
    return this.userTable.updateDataSync(predicates, valuesBucket)
  }

  queryDataSync(valuesBucket: relationalStore.ValuesBucket): relationalStore.ResultSet | undefined {
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_USER.tableName)
    predicates.equalTo('id', valuesBucket.id)
    return this.userTable.queryDataSync(predicates)
  }

  async upsert(serverId: number, userId: string, accessToken: string): Promise<number> {
    // 查询现有用户
    const user = await this.getByUserId(serverId, userId)
    if (user) {
      // 如果用户存在，更新访问令牌
      user.accessToken = accessToken
      this.updateDataSync(user.toValuesBucket())
      return user.id
    } else {
      let entity = new UserEntity(serverId,userId,accessToken)
      return this.insertDataSync(entity.toValuesBucket())
    }
  }

  // 根据服务器ID和用户ID获取用户
  async getByUserId(serverId: number, userId: string): Promise<UserEntity | null> {
    try {
      // 实际实现取决于数据存储方式，这里以伪代码示意
      let predicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(RdbConstants.TABLE_USER.tableName)
      predicates.equalTo('server_id', serverId)
      predicates.equalTo('user_id', userId)
      let resultSet: relationalStore.ResultSet | undefined = this.userTable.queryDataSync(predicates)
      let result: UserEntity | null = null
      if (resultSet) {
        while (resultSet.goToNextRow()) {
          result = new UserEntity()
          result.id = resultSet.getLong(0)
          result.serverId = resultSet.getLong(1)
          result.userId = resultSet.getString(2)
          result.accessToken = resultSet.getString(3)
          result.lastLoginTimestamp = resultSet.getLong(4)
        }
      }
      return result
    } catch (error) {
      console.error('Get user by ID failed', error);
      return null;
    }
  }
}