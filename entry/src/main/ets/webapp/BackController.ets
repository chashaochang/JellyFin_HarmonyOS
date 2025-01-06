export class BackController {
  callback?: () => boolean

  setOnBackPressListener(callback: () => boolean) {
    this.callback = callback
  }

  onBackPress(): boolean {
    return this.callback?.() ?? false
  }
}