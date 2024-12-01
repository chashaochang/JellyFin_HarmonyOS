import { PlayOptions } from "../player/interaction/PlayOptions"

@Component
struct PlayerView{

  @Prop options:PlayOptions

  build() {
    NavDestination(){
      Column(){
        Text('播放'+this.options.mediaSourceId)
      }
    }.hideTitleBar(true)
  }
}

@Builder
export function PlayerViewViewBuilder(name:string,options:PlayOptions){
  PlayerView({
    options:options
  })
}