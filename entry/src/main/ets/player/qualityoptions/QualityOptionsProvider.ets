import { QualityOption } from "./QualityOption";

class QualityOptionsProvider {
  private defaultQualityOptions: QualityOption[] = [
    { maxHeight: 2160, bitrate: 120000000 },
    { maxHeight: 2160, bitrate: 80000000 },
    { maxHeight: 1080, bitrate: 60000000 },
    { maxHeight: 1080, bitrate: 40000000 },
    { maxHeight: 1080, bitrate: 20000000 },
    { maxHeight: 1080, bitrate: 15000000 },
    { maxHeight: 1080, bitrate: 10000000 },
    { maxHeight: 720, bitrate: 8000000 },
    { maxHeight: 720, bitrate: 6000000 },
    { maxHeight: 720, bitrate: 4000000 },
    { maxHeight: 480, bitrate: 3000000 },
    { maxHeight: 480, bitrate: 1500000 },
    { maxHeight: 480, bitrate: 720000 },
    { maxHeight: 360, bitrate: 420000 },
    { maxHeight: 0, bitrate: 0 },// auto
  ]

  getApplicableQualityOptions(videoWidth: number, videoHeight: number): Array<QualityOption> {
    // If the aspect ratio is less than 16/9, set the width as if it were pillarboxed
    // i.e. 4:3 1440x1080 -> 1920x1080
    // 简单直接的方式
    const aspectRatio = videoWidth / videoHeight;
    const maxAllowedWidth = aspectRatio < 16/9 ? videoHeight * 16 / 9 : videoWidth;

    let maxAllowedHeight: number;
    if (maxAllowedWidth >= 3800) {
      maxAllowedHeight = 2160;
    } else if (maxAllowedWidth >= 1900) { // Some 1080p videos are apparently reported as 1912
      maxAllowedHeight = 1080;
    } else if (maxAllowedWidth >= 1260) {
      maxAllowedHeight = 720;
    } else if (maxAllowedWidth >= 620) {
      maxAllowedHeight = 480;
    } else {
      maxAllowedHeight = 360;
    }

    // 模拟 takeLastWhile
    const result: Array<QualityOption> = [];
    let foundFirst = false;

    // 从后向前遍历
    for (let i = this.defaultQualityOptions.length - 1; i >= 0; i--) {
      const option = this.defaultQualityOptions[i];
      if (option.maxHeight <= maxAllowedHeight) {
        result.unshift(option); // 添加到结果数组前面
        foundFirst = true;
      } else if (foundFirst) {
        break; // 一旦条件不满足且已找到符合条件的元素，就停止遍历
      }
    }

    return result;
  }
}

const qualityOptionsProvider = new QualityOptionsProvider()
export default qualityOptionsProvider