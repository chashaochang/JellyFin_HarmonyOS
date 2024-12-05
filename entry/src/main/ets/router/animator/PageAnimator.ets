import { HMAnimator, HMAnimatorHandle, IHMAnimator, OpacityOption, ScaleOption, TranslateOption } from "@hadss/hmrouter"

@HMAnimator({ animatorName: 'pageAnimator' })
export class PageAnimator implements IHMAnimator {
  effect(enterHandle: HMAnimatorHandle, exitHandle: HMAnimatorHandle): void {
    // 入场动画
    enterHandle.start((translateOption: TranslateOption, scaleOption: ScaleOption,
      opacityOption: OpacityOption) => {
      translateOption.y = '100%'
    })
    enterHandle.finish((translateOption: TranslateOption, scaleOption: ScaleOption,
      opacityOption: OpacityOption) => {
      translateOption.y = '0'
    })
    enterHandle.duration = 500

    // 出场动画
    exitHandle.start((translateOption: TranslateOption, scaleOption: ScaleOption,
      opacityOption: OpacityOption) => {
      translateOption.y = '0'
    })
    exitHandle.finish((translateOption: TranslateOption, scaleOption: ScaleOption,
      opacityOption: OpacityOption) => {
      translateOption.y = '100%'
    })
    exitHandle.duration = 500
  }
}