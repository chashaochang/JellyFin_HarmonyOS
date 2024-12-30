import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { Constants } from '../utils/Constants';

const PREFERENCES_NAME: string = 'JellyFin_Preference';

export class AppPreference {
  private preferences?: preferences.Preferences;
  private context = getContext(this) as common.UIAbilityContext;
  private static instance: AppPreference;

  private constructor() {
    this.initPreference(PREFERENCES_NAME);
  }

  public static getInstance(): AppPreference {
    if (!AppPreference.instance) {
      AppPreference.instance = new AppPreference();
    }
    return AppPreference.instance;
  }

  async initPreference(storeName: string): Promise<void> {
    return preferences.getPreferences(this.context, storeName)
      .then((preferences: preferences.Preferences) => {
        this.preferences = preferences;
      });
  }

  async setValue<T>(key: string, value: T): Promise<void> {
    if (this.preferences) {
      await this.preferences.put(key, JSON.stringify(value))
      this.saveUserData();
    } else {
      await this.initPreference(PREFERENCES_NAME)
      this.setValue<T>(key, value);
    }
  }

  async getValue<T>(key: string): Promise<T | null> {
    if (this.preferences) {
      let value: T | null = null;
      let res = await this.preferences.get(key, '')
      if (res) {
        value = JSON.parse(res as string) as T;
      }
      return value;
    } else {
      await this.initPreference(PREFERENCES_NAME)
      return this.getValue<T>(key);
    }
  }

  async hasValue(key: string): Promise<boolean> {
    if (this.preferences) {
      return this.preferences.has(key);
    } else {
      await this.initPreference(PREFERENCES_NAME)
      return this.hasValue(key);
    }
  }

  async deleteValue(key: string): Promise<void> {
    if (this.preferences) {
      await this.preferences.delete(key)
      this.saveUserData();
    } else {
      await this.initPreference(PREFERENCES_NAME)
      this.deleteValue(key);
    }
  }

  saveUserData() {
    this.preferences?.flush();
  }

  currentServerId?: number

  async getCurrentServerId(): Promise<number | null> {
    let id = await this.getValue<number>(Constants.PREF_SERVER_ID)
    if (id && id >= 0) {
      return id
    }
    return null
  }

  setCurrentServerId(id:number){
    this.setValue<number>(Constants.PREF_SERVER_ID,id)
  }

  async getCurrentUserId(): Promise<number | null> {
    let id = await this.getValue<number>(Constants.PREF_USER_ID)
    if (id && id >= 0) {
      return id
    }
    return null
  }

  async setCurrentUserId(id:number){
    await this.setValue<number>(Constants.PREF_USER_ID,id)
  }
}