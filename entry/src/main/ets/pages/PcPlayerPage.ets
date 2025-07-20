import { HMDefaultGlobalAnimator, HMNavigation, HMRouterMgr } from '@hadss/hmrouter'
import { Constants } from '../utils/Constants'
import { AttributeUpdater } from '@kit.ArkUI';
import { PlayOptions } from '../player/interaction/PlayOptions';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct PcPlayerPage {
  modifier: PlayerNavModifier = new PlayerNavModifier();

  build() {
    Stack() {
      HMNavigation({
        navigationId: Constants.PLAYER_NAVIGATION_ID, options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR,
          dialogAnimator: HMDefaultGlobalAnimator.DIALOG_ANIMATOR,
          modifier: this.modifier,
        }
      }).onAppear(()=>{
        let context = this.getUIContext().getHostContext() as common.UIAbilityContext; // UIAbilityContext
        let playOptions: PlayOptions | undefined = AppStorage.get<PlayOptions>('playerOptions')
        if (!playOptions) {
          context.terminateSelf()
          return
        }
        HMRouterMgr.push({ navigationId: Constants.PLAYER_NAVIGATION_ID, pageUrl: '/Player', param: playOptions })
      })
    }.width('100%')
    .height('100%')
  }

}

export class PlayerNavModifier extends AttributeUpdater<NavigationAttribute> {
  instance?: NavigationAttribute

  initializeModifier(instance: NavigationAttribute): void {
    this.instance = instance
    instance.hideTitleBar(true)
  }
}