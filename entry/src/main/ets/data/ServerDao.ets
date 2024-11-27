import Rdb from "./Rdb";
import { RdbConstants } from "./RdbConstants";
import { relationalStore } from "@kit.ArkData";
import { ServerEntity } from "./ServerEntity";

export class ServerDao {
  private serverTable = new Rdb(
    RdbConstants.TABLE_SERVER.tableName,
    RdbConstants.TABLE_SERVER.sqlCreate,
    RdbConstants.TABLE_SERVER.columns
  )

  constructor() {
    this.serverTable.getRdbStore()
  }

  getRdbStore() {
    this.serverTable.getRdbStore()
  }

  insertDataSync(valuesBucket: relationalStore.ValuesBucket): number {
    return this.serverTable.insertDataSync(valuesBucket)
  }

  deleteDataSync(valuesBucket: relationalStore.ValuesBucket): number {
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_SERVER.tableName)
    predicates.equalTo('id', valuesBucket.id)
    return this.serverTable.deleteDataSync(predicates)
  }

  updateDataSync(valuesBucket: relationalStore.ValuesBucket): number {
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_SERVER.tableName)
    predicates.equalTo('id', valuesBucket.id)
    return this.serverTable.updateDataSync(predicates, valuesBucket)
  }

  queryDataSync(valuesBucket: relationalStore.ValuesBucket): relationalStore.ResultSet | undefined {
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_SERVER.tableName)
    predicates.equalTo('id', valuesBucket.id)
    return this.serverTable.queryDataSync(predicates)
  }

  getServer(serverId: number): ServerEntity | null {
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_SERVER.tableName)
    predicates.equalTo('id', serverId)
    let resultSet = this.serverTable.queryDataSync(predicates);
    let result: ServerEntity | null = null;
    if (resultSet) {
      while (resultSet.goToNextRow()) {
        let item: ServerEntity = new ServerEntity(resultSet.getString(1))
        item.id = resultSet.getLong(0)
        item.lastUsedTimestamp = resultSet.getLong(2)
        result = item
      }
      return result
    }
    return null;
  }

  getServerByHostname(hostname:string): ServerEntity | null{
    let predicates: relationalStore.RdbPredicates =
      new relationalStore.RdbPredicates(RdbConstants.TABLE_SERVER.tableName)
    predicates.equalTo('hostname', hostname)
    let resultSet = this.serverTable.queryDataSync(predicates);
    let result: ServerEntity | null = null;
    if (resultSet) {
      while (resultSet.goToNextRow()) {
        let item: ServerEntity = new ServerEntity(resultSet.getString(1))
        item.id = resultSet.getLong(0)
        item.lastUsedTimestamp = resultSet.getLong(2)
        result = item
      }
      return result
    }
    return null;
  }

  insert(hostname:string){
    this.serverTable.insertDataSync(new ServerEntity(hostname).asBucket())
  }
}