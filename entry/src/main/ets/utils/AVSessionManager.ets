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

  async unregisterSessionListener() {
    if (!this.session) {
      return;
    }
    this.session.off('play');
    this.session.off('pause');
    this.session.off('playNext');
    this.session.off('playPrevious');
    // this.session.off('setLoopMode');
    this.session.off('seek');
    // this.session.off('toggleFavorite');

    this.session.off('stop');
    // session.on('fastForward', () => {
    //   console.info(`on fastForward , do fastForward task`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('fastForward')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
    // });
    // session.on('rewind', () => {
    //   console.info(`on rewind , do rewind task`);
    //   // 如暂不支持该指令，请勿注册；或在注册后但暂不使用时，通过session.off('rewind')取消监听
    //   // 处理完毕后，请使用SetAVPlayState上报播放状态和播放position
    // });
    this.session.off('setSpeed');
    this.session.destroy()
  }
}

const avSessionManager = new AVSessionManager()

export default avSessionManager