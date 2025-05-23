import { ServerDao } from "./ServerDao"
import { UserDao } from "./UserDao"

export class DBManager {
  private serverDao?: ServerDao
  private userDao?: UserDao
  private static instance?: DBManager

  static getInstance(): DBManager {
    if (!DBManager.instance) {
      DBManager.instance = new DBManager()
    }
    return DBManager.instance
  }

  init(context:Context) {
    this.serverDao = new ServerDao(context)
    this.userDao = new UserDao(context)
  }

  getServerDao(): ServerDao {
    if (!this.serverDao) {
      throw new Error('DBManager is not init!')
    }
    return this.serverDao
  }

  getUserDao(): UserDao {
    if (!this.userDao) {
      throw new Error('DBManager is not init!')
    }
    return this.userDao
  }
}