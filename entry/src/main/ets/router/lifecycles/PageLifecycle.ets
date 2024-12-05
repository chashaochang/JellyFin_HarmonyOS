import { HMLifecycle, HMLifecycleContext, IHMLifecycle } from "@hadss/hmrouter";

@HMLifecycle({ lifecycleName: 'pageLifecycle' })
export class PageLifecycle implements IHMLifecycle {

  onShown(ctx: HMLifecycleContext): void {

  }

  onHidden(ctx: HMLifecycleContext): void {

  }
}