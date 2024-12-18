export class Constants{
  // Preference keys
  static readonly PREF_SERVER_ID = "pref_server_id"
  static readonly PREF_USER_ID = "pref_user_id"

  static readonly MAIN_BUNDLE_PATH_REGEX = /.*\/main\.[^/\s]+\.bundle\.js/  //new Regex(""".*/main\.[^/\s]+\.bundle\.js""")
  static readonly SESSION_CAPABILITIES_PATH = 'sessions/capabilities/full'
  static readonly TICKS_PER_MILLISECOND = 10000

  static readonly NAVIGATION_ID = 'mainNavigation'
}