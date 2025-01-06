import { emitter } from "@kit.BasicServicesKit"

export class Constants {
  static readonly PLAYER_EVENT: emitter.InnerEvent = {
    eventId: 100001
  }
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