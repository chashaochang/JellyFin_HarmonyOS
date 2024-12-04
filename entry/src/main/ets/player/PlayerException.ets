import { BusinessError } from "@kit.BasicServicesKit"

export class PlayerException{
  cause?:BusinessError

  constructor(cause?:BusinessError) {
    this.cause = cause
  }
  static InvalidPlayOptions:PlayerException = new PlayerException()
  static NetworkFailure:PlayerException = new PlayerException()
  static UnsupportedContent:PlayerException = new PlayerException()
}