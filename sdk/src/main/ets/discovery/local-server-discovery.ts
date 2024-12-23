import { connection, socket } from "@kit.NetworkKit"
import { ServerDiscoveryInfo } from "../generated-client/models"
import { BusinessError } from "@kit.BasicServicesKit"
import { buffer } from "@kit.ArkTS"

export class LocalServerDiscovery{

  static readonly DISCOVERY_MESSAGE = "who is JellyfinServer?"
  static readonly DISCOVERY_PORT = 7359
  static readonly DISCOVERY_RECEIVE_BUFFER = 1024 // bytes
  static readonly DISCOVERY_TIMEOUT = 500
  static readonly DISCOVERY_MAX_SERVERS = 15

  private udpSocket: socket.UDPSocket | null = null;
  private isClosed:boolean = false

  /**
   * 尝试读取和解析发送到socket的消息
   */
  private async receive(): Promise<ServerDiscoveryInfo | null> {
    if (!this.udpSocket) {
      return null;
    }
    console.debug("Reading reply...")
    return new Promise((resolve) => {
      // 使用on('message')之前先移除之前的监听器，避免重复
      this.udpSocket?.off('message');
      // 设置消息处理器
      this.udpSocket.on('message', (data) => {
        try {
          // 转换消息为字符串
          const message = buffer.from(data.message).toString();
          console.debug(`Received message "${message}"`);
          // 解析JSON
          const info = JSON.parse(message) as ServerDiscoveryInfo;
          resolve(info);
        } catch (error) {
          console.error(`Unable to parse message: ${error}`);
          resolve(null);
        }
      });
    })
	}

  /**
   * 向指定地址发送广播消息
   */
  private async discoverAddress(address: connection.NetAddress): Promise<void> {
    try {
      if (!this.udpSocket) return;

      await this.udpSocket.send({
        data: LocalServerDiscovery.DISCOVERY_MESSAGE,
        address: address,
      });

      console.debug(`Discovering via ${address.address}`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Unable to send discovery message to ${address.address}: ${err.message}`);
    }
  }

  async discover(timeout: number,
    maxServers: number): Promise<ServerDiscoveryInfo[]> {
    console.info(`Starting discovery with timeout of ${timeout}ms`)

    try {
      this.udpSocket = socket.constructUDPSocketInstance()
      await this.udpSocket.bind({address:'0.0.0.0',port:9990})
      this.udpSocket.setExtraOptions({
        receiveBufferSize: 100000,
        sendBufferSize: 100000,
        reuseAddress: false,
        socketTimeout:timeout,
        broadcast:true
      })
      // 发送广播
      const broadcastAddress = '255.255.255.255';
      const address:connection.NetAddress = {
        address:broadcastAddress,
        port:LocalServerDiscovery.DISCOVERY_PORT,
        family:1//ipv4
      }
      // 使用on('message')之前先移除之前的监听器，避免重复
      // this.udpSocket.off('message');
      // // 设置消息处理器
      // this.udpSocket.on('message', (data) => {
      //   try {
      //     // 转换消息为字符串
      //     const message = buffer.from(data.message)
      //     const str = message.toString()
      //     console.debug(`Received message "${str}"`);
      //     // 解析JSON
      //     const info = message.toJSON() as ServerDiscoveryInfo;
      //     // resolve(info);
      //   } catch (error) {
      //     console.error(`Unable to parse message: ${error}`);
      //     // resolve(null);
      //   }
      // });
      await this.discoverAddress(address)
      console.debug (`Finished sending broadcast, listening for responses`)
      // 接收响应，最多接收指定数量的服务器
      const foundServers = new Set<string>();
      const results: ServerDiscoveryInfo[] = [];
      for (let index = 0; index < maxServers; index++) {
        if (this.isClosed) break
        // 设置超时
        const timeoutPromise = new Promise<void>((resolve) => {
          setTimeout(() => resolve(), timeout);
        });
        try {
          const info = await Promise.race([
            this.receive(),
            timeoutPromise
          ]) as ServerDiscoveryInfo | null;
          if (!info) break; // 超时或接收错误
          // 过滤重复
          if (foundServers.has(info.Id)) continue;
          foundServers.add(info.Id);
          results.push(info);
        } catch (err) {
          break;
        } finally {
          this.udpSocket.off('message')
        }
      }
      return results
    } finally {
      this.udpSocket.close(()=>{
        this.isClosed = true
      })
      this.udpSocket = null;
      console.debug('End');
    }
  }
}