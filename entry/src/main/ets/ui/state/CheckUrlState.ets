// 定义状态类型
export enum CheckUrlStateType {
  Unchecked = 'Unchecked',
  Pending = 'Pending',
  Success = 'Success',
  Error = 'Error'
}

// 基础状态类
@ObservedV2
export abstract class CheckUrlState {
  @Trace abstract type: CheckUrlStateType;
}

// 具体状态实现
export class Unchecked extends CheckUrlState {
  type = CheckUrlStateType.Unchecked;
}

export class Pending extends CheckUrlState {
  type = CheckUrlStateType.Pending;
}

export class Success extends CheckUrlState {
  type = CheckUrlStateType.Success;
  address: string;

  constructor(address: string) {
    super();
    this.address = address;
  }
}

export class Error extends CheckUrlState {
  type = CheckUrlStateType.Error;
  message?: string;

  constructor(message?: string) {
    super();
    this.message = message;
  }
}