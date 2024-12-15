// ActivityEventConstants.ets
import { PlayOptions } from "../player/interaction/PlayOptions";

// 定义事件类型常量
export class ActivityEvents {
  static readonly CHANGE_FULLSCREEN = 'CHANGE_FULLSCREEN';
  static readonly LAUNCH_NATIVE_PLAYER = 'LAUNCH_NATIVE_PLAYER';
  static readonly OPEN_URL = 'OPEN_URL';
  static readonly DOWNLOAD_FILE = 'DOWNLOAD_FILE';
  static readonly CAST_MESSAGE = 'CAST_MESSAGE';
  static readonly REQUEST_BLUETOOTH_PERMISSION = 'REQUEST_BLUETOOTH_PERMISSION';
  static readonly OPEN_SETTINGS = 'OPEN_SETTINGS';
  static readonly SELECT_SERVER = 'SELECT_SERVER';
  static readonly EXIT_APP = 'EXIT_APP';
}