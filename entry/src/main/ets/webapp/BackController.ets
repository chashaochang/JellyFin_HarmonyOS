export class BackController {
  callback?: () => boolean

  setOnBackPressListener(callback: () => boolean) {
    this.callback = callback
  }

  onBackPress(): boolean | void {
    if (this.callback) {
      return this.callback()
    }
  }
}