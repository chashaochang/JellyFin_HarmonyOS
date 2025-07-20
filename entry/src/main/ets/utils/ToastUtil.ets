export class ToastUtil {
  static showToast(context: UIContext, msg: string) {
    context.getPromptAction().showToast({
      message: msg
    })
  }
}