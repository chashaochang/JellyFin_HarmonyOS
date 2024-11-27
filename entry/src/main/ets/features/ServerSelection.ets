import { ApiClientController } from "../data/ApiClientController"

@Component
export struct ServerSelection{
  private apiClientController:ApiClientController = new ApiClientController()

  onConnected:(hostname:string)=>void = ()=>{}

  @State hostname:string = ''

  async aboutToAppear(): Promise<void> {
    let server = await this.apiClientController.loadSavedServer()
    if(server){
      this.hostname = server.hostname
    }
  }
  build() {
    Column(){
      Text('连接到服务器').padding({bottom:8}).fontSize(24).fontColor(Color.White)
    }.alignItems(HorizontalAlign.Start).width('100%')
  }
}