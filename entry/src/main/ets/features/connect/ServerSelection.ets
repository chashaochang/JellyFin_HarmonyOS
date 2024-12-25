import { ApiClientController } from "../../data/ApiClientController"
import { CheckUrlState } from "../../ui/state/CheckUrlState"
import { ServerSelectionMode } from "../../ui/state/ServerSelectionMode"
import { inputMethod } from "@kit.IMEKit"
import connectionHelper from "../../setup/ConnectionHelper"
import { KeyCode } from "@kit.InputKit"
import Theme from "../../ui/Theme"
import { ServerSuggestion, Type } from "./ServerSuggestion"
import { ComposeListItem } from "@ohos.arkui.advanced.ComposeListItem"

@ComponentV2
export struct ServerSelection {
  private apiClientController: ApiClientController = new ApiClientController()
  @Param @Once onConnected: (hostname: string) => void = () => {
  }
  @Local hostname: string = ''
  @Local serverSelectionMode: ServerSelectionMode = ServerSelectionMode.ADDRESS
  @Consumer() showExternalConnectionError: boolean = false
  @Local externalError: boolean = this.showExternalConnectionError
  @Local checkUrlState: CheckUrlState = CheckUrlState.Unchecked
  @Local serverSuggestions: ServerSuggestion[] = []

  async aboutToAppear(): Promise<void> {
    let server = await this.apiClientController.loadSavedServer()
    if (server) {
      this.hostname = server.hostname
    }
    let previousServers = this.apiClientController.loadPreviouslyUsedServers()
    // Suggest saved servers
    this.serverSuggestions = previousServers.map(server => {
      return {
        type: Type.SAVED,
        name: server.hostname,
        address: server.hostname,
        timestamp: server.lastUsedTimestamp
      } as ServerSuggestion
    })
    // Prepend discovered servers to suggestions
    let servers = await connectionHelper.discoverServers()
    servers.forEach(serverInfo => {
      this.serverSuggestions = [
        {
          type: Type.DISCOVERED,
          name: serverInfo.Name ?? "",
          address: serverInfo.Address ?? '',
          timestamp: new Date().getTime()
        },
        ...this.serverSuggestions.filter(existing => existing.address !== serverInfo.Address)
      ];
    })
  }

  async onSubmit() {
    this.externalError = false
    this.checkUrlState = CheckUrlState.Pending
    let state = await connectionHelper.checkServerUrl(this.hostname)
    this.checkUrlState = state
    if (state === CheckUrlState.Success) {
      this.onConnected(state.address!)
    }
  }

  build() {
    Column() {
      Text('连接到服务器').padding({ bottom: 8 }).fontSize(24).fontColor(Color.White)
      if (this.serverSelectionMode === ServerSelectionMode.ADDRESS) {
        AddressSelection({
          text: this.hostname,
          errorText: this.showExternalConnectionError ? '无法建立连接。 请检查主机名和你的网络连接。' :
            (this.checkUrlState === CheckUrlState.Error ? this.checkUrlState.message : undefined),
          loading: this.checkUrlState === CheckUrlState.Pending,
          onTextChange: (value: string) => {
            this.externalError = false
            this.checkUrlState = CheckUrlState.Unchecked
            this.hostname = value
          },
          onDiscoveryClick: () => {
            this.externalError = false
            inputMethod.getController().hideTextInput()
            this.serverSelectionMode = ServerSelectionMode.AUTO_DISCOVERY
          },
          onSubmit: () => {
            this.onSubmit()
          }
        })
      } else {
        ServerDiscoveryList({
          serverSuggestions: this.serverSuggestions,
          onGoBack: () => {
            this.serverSelectionMode = ServerSelectionMode.ADDRESS
          },
          onSelectServer: (url: string) => {
            this.hostname = url
            this.serverSelectionMode = ServerSelectionMode.ADDRESS
            this.onSubmit()
          },
        }).height('100%')
      }
    }.alignItems(HorizontalAlign.Start).width('100%').height('100%')
  }
}

@Component
struct AddressSelection {
  @Prop text: string
  @Prop errorText: string
  @Prop loading: boolean
  onTextChange: (x: string) => void = () => {
  }
  onDiscoveryClick: () => void = () => {
  }
  onSubmit: () => void = () => {
  }

  build() {
    Column() {
      ServerUrlField({
        text: this.text,
        onTextChanged: this.onTextChange,
        onSubmit: this.onSubmit
      })
      AnimatedErrorText({
        errorText: this.errorText
      })
      if (!this.loading) {
        Blank().height(12)
        StyledTextButton({
          text: '连接',
          enable: this.text.length > 0,
          onclick: this.onSubmit,
        })
        StyledTextButton({
          text: '选择服务器',
          onclick: this.onDiscoveryClick
        })
      } else {

      }
    }
  }
}

@Component
struct ServerUrlField {
  @Prop text: string
  onTextChanged: (val: string) => void = () => {
  }
  onSubmit: () => void = () => {
  }

  build() {
    TextInput({
      text: this.text,
      placeholder: '主机',
    })
      .onChange((v) => {
        this.onTextChanged(v)
      })
      .width('100%')
      .padding({ bottom: 8 })
      .onKeyEvent((event) => {
        if (event.keyCode === KeyCode.KEYCODE_ENTER) {
          this.onSubmit()
        }
      })
      .type(InputType.URL)
      .onSubmit(() => {
        this.onSubmit()
      })
      .maxLines(1)
      .borderWidth(1)
      .borderColor(Color.Gray)
      .borderRadius(4)
      .height(50)
      .placeholderColor(Color.Gray)
      .fontColor(Color.White)
  }
}

@Component
struct AnimatedErrorText {
  @Prop errorText: string

  build() {
    Text(this.errorText).width('100%').padding({ top: 4 }).fontColor(Theme.colors.error)
  }
}

@Component
struct StyledTextButton {
  @Prop text: string
  @Prop enable: boolean
  onclick: () => void = () => {
  }

  build() {
    Button(this.text, { type: ButtonType.Normal, stateEffect: true })
      .borderRadius(8)
      .backgroundColor(0x317aff)
      .width('100%')
      .onClick(() => {
        this.onclick()
      })
      .enabled(this.enable)
      .padding({ top: 4, bottom: 4 })
      .margin({ top: 16 })

  }
}

@ComponentV2
struct ServerDiscoveryList {
  @Param @Require serverSuggestions: ServerSuggestion[]
  @Param @Require onGoBack: () => void
  @Param @Require onSelectServer: (url: string) => void

  build() {
    Column() {
      Row() {
        Button() {
          Image($r('app.media.ic_back'))
        }.backgroundColor(Color.Transparent).onClick(() => {
          this.onGoBack()
        }).size({ width: 40, height: 40 })

        Text('现有服务器').layoutWeight(1).padding(8).fontColor(Color.White)
        LoadingProgress().margin({
          left: 12, right: 12
        }).width(24).height(24)
      }

      Blank().height(8)
      Column() {
        Repeat<ServerSuggestion>(this.serverSuggestions).each((obj: RepeatItem<ServerSuggestion>) => {
          ServerDiscoveryItem({
            serverSuggestion: obj.item,
            onClickServer: () => {
              this.onSelectServer(obj.item.address)
            }
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ bottom: 16 })
      .backgroundColor(Theme.colors.surface)
      .borderRadius(4)
    }.height('100%')
  }
}


@ComponentV2
struct ServerDiscoveryItem {
  @Param @Require serverSuggestion: ServerSuggestion
  @Param @Require onClickServer: () => void

  build() {
    Column() {
      Text(this.serverSuggestion.name).fontColor(Color.White).fontSize(18)
      Text(this.serverSuggestion.address).fontColor(Color.Gray).fontSize(16)
    }.width('100%')
    .padding(10).alignItems(HorizontalAlign.Start).onClick(() => {
      this.onClickServer()
    })
  }
}