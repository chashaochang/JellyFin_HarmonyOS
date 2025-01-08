import { avSession } from '@kit.AVSessionKit';

class AVSessionManager {

  private session?: avSession.AVSession

  getSession(): avSession.AVSession | undefined {
    return this.session
  }

  async initAVSession(): Promise<avSession.AVSession> {
    let type: avSession.AVSessionType = 'video';
    let session = await avSession.createAVSession(getContext(this), 'SESSION_NAME', type);
    // 请按照如下参数设置，告知系统应用当前支持投播，才能成功投播。
    session.setExtras({
      requireAbilityList: ['url-cast'],
    });
    this.session = session
    return session
  }
}

const avSessionManager = new AVSessionManager()

export default avSessionManager