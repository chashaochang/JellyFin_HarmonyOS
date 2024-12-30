// ActivityEventConstants.ets
import { PlayOptions } from "../player/interaction/PlayOptions";

// 定义事件类型常量
// 定义事件类型
export enum ActivityEventType {
  ChangeFullscreen = 'ChangeFullscreen',
  LaunchNativePlayer = 'LaunchNativePlayer',
  OpenUrl = 'OpenUrl',
  DownloadFile = 'DownloadFile',
  CastMessage = 'CastMessage',
  RequestBluetoothPermission = 'RequestBluetoothPermission',
  OpenSettings = 'OpenSettings',
  SelectServer = 'SelectServer',
  ExitApp = 'ExitApp'
}

// 基础事件类
@ObservedV2
export abstract class ActivityEvent {
  @Trace abstract type: ActivityEventType;
}

// 带参数的事件类
export class ChangeFullscreen extends ActivityEvent {
  type = ActivityEventType.ChangeFullscreen;
  isFullscreen: boolean;

  constructor(isFullscreen: boolean) {
    super();
    this.isFullscreen = isFullscreen;
  }
}

export class LaunchNativePlayer extends ActivityEvent {
  type = ActivityEventType.LaunchNativePlayer;
  playOptions: PlayOptions;

  constructor(playOptions: PlayOptions) {
    super();
    this.playOptions = playOptions;
  }
}

export class OpenUrl extends ActivityEvent {
  type = ActivityEventType.OpenUrl;
  uri: string;

  constructor(uri: string) {
    super();
    this.uri = uri;
  }
}

export class DownloadFile extends ActivityEvent {
  type = ActivityEventType.DownloadFile;
  uri: ResourceStr;
  title: string;
  filename: string;

  constructor(uri: ResourceStr, title: string, filename: string) {
    super();
    this.uri = uri;
    this.title = title;
    this.filename = filename;
  }
}

export class CastMessage extends ActivityEvent {
  type = ActivityEventType.CastMessage;
  action: string;
  args: Array<ESObject>;

  constructor(action: string, args: Array<ESObject>) {
    super();
    this.action = action;
    this.args = args;
  }
}

// 无参数的单例事件类
export class RequestBluetoothPermission extends ActivityEvent {
  type = ActivityEventType.RequestBluetoothPermission;
  private static instance: RequestBluetoothPermission;

  private constructor() {
    super();
  }

  static getInstance(): RequestBluetoothPermission {
    if (!RequestBluetoothPermission.instance) {
      RequestBluetoothPermission.instance = new RequestBluetoothPermission();
    }
    return RequestBluetoothPermission.instance;
  }
}

export class OpenSettings extends ActivityEvent {
  type = ActivityEventType.OpenSettings;
  private static instance: OpenSettings;

  private constructor() {
    super();
  }

  static getInstance(): OpenSettings {
    if (!OpenSettings.instance) {
      OpenSettings.instance = new OpenSettings();
    }
    return OpenSettings.instance;
  }
}

export class SelectServer extends ActivityEvent {
  type = ActivityEventType.SelectServer;
  private static instance: SelectServer;

  private constructor() {
    super();
  }

  static getInstance(): SelectServer {
    if (!SelectServer.instance) {
      SelectServer.instance = new SelectServer();
    }
    return SelectServer.instance;
  }
}

export class ExitApp extends ActivityEvent {
  type = ActivityEventType.ExitApp;
  private static instance: ExitApp;

  private constructor() {
    super();
  }

  static getInstance(): ExitApp {
    if (!ExitApp.instance) {
      ExitApp.instance = new ExitApp();
    }
    return ExitApp.instance;
  }
}