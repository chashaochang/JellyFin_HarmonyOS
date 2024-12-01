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
      this.preferences.put(key, JSON.stringify(value)).then(() => {
        this.saveUserData();
      })
    } else {
      this.initPreference(PREFERENCES_NAME).then(() => {
        this.setValue<T>(key, value);
      });
    }
  }

  async getValue<T>(key: string): Promise<T | null> {
    if (this.preferences) {
      return this.preferences.get(key, '').then((res: preferences.ValueType) => {
        let value: T | null = null;
        if (res) {
          value = JSON.parse(res as string) as T;
        }
        return value;
      });
    } else {
      return this.initPreference(PREFERENCES_NAME).then(() => {
        return this.getValue<T>(key);
      });
    }
  }

  async hasValue(key: string): Promise<boolean> {
    if (this.preferences) {
      return this.preferences.has(key);
    } else {
      return this.initPreference(PREFERENCES_NAME).then(() => {
        return this.hasValue(key);
      });
    }
  }

  async deleteValue(key: string): Promise<void> {
    if (this.preferences) {
      this.preferences.delete(key).then(() => {
        this.saveUserData();
      });
    } else {
      this.initPreference(PREFERENCES_NAME).then(() => {
        this.deleteValue(key);
      });
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
}