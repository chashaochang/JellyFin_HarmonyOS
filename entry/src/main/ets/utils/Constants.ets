import { emitter } from "@kit.BasicServicesKit"

export class Constants {
  static readonly PLAYER_EVENT: emitter.InnerEvent = {
    eventId: 100001
  }
  /**
   *  Cast playing initial
   */
  static readonly PLAYBACK_STATE_INITIAL: number = 0;

  /**
   *  Cast playing prepare
   */
  static readonly PLAYBACK_STATE_PREPARE: number = 1;

  /**
   *  Cast playing pause
   */
  static readonly PLAYBACK_STATE_PAUSE: number = 3;

  /**
   *  Cast playing stop
   */
  static readonly PLAYBACK_STATE_STOP: number = 6;

  /**
   *  Cast playing play
   */
  static readonly PLAYBACK_STATE_PLAY: number = 2;

  static readonly APP_INFO_NAME = "Jellyfin HarmonyOS"
  // Webapp constants
  static readonly INITIAL_CONNECTION_TIMEOUT = 10000 // 10 seconds

  // Preference keys
  static readonly PREF_SERVER_ID = "pref_server_id"
  static readonly PREF_USER_ID = "pref_user_id"
  static readonly MAIN_BUNDLE_PATH_REGEX =
    /.*\/main\.[^/\s]+\.bundle\.js/ //new Regex(""".*/main\.[^/\s]+\.bundle\.js""")
  static readonly SESSION_CAPABILITIES_PATH = 'sessions/capabilities/full'
  static readonly TICKS_PER_MILLISECOND = 10000
  static readonly NAVIGATION_ID = 'mainNavigation'
  // Video player constants
  static readonly LANGUAGE_UNDEFINED = "und"
}