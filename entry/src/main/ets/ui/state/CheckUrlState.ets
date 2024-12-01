export class CheckUrlState{
  message?:string
  address?:string
  static Unchecked:CheckUrlState = new CheckUrlState()
  static Pending:CheckUrlState = new CheckUrlState()
  static Success:CheckUrlState = new CheckUrlState()
  static Error:CheckUrlState = new CheckUrlState()
}