// 使用抽象类和类型区分实现sealed class效果
abstract class DeviceCodec {
  name: string;
  mimeType: string;
  profiles: Set<string>;
  maxBitrate: number;

  constructor(name: string, mimeType: string, profiles: Set<string>, maxBitrate: number) {
    this.name = name;
    this.mimeType = mimeType;
    this.profiles = profiles;
    this.maxBitrate = maxBitrate;
  }
}

export class VideoCodec extends DeviceCodec {
  private levels: Set<number>;

  constructor(
    name: string,
    mimeType: string,
    profiles: Set<string>,
    levels: Set<number>,
    maxBitrate: number
  ) {
    super(name, mimeType, profiles, maxBitrate);
    this.levels = levels;
  }

  mergeCodec(codecToMerge: VideoCodec): VideoCodec {
    const mergedProfiles = new Set<string>();
    const mergedLevels = new Set<number>();

    // 手动添加当前对象的profiles
    this.profiles.forEach(profile => mergedProfiles.add(profile));
    // 手动添加要合并对象的profiles
    codecToMerge.profiles.forEach(profile => mergedProfiles.add(profile));

    // 手动添加当前对象的levels
    this.levels.forEach(level => mergedLevels.add(level));
    // 手动添加要合并对象的levels
    codecToMerge.levels.forEach(level => mergedLevels.add(level));

    return new VideoCodec(
      this.name,
      this.mimeType,
      mergedProfiles,
      mergedLevels,
      Math.max(this.maxBitrate, codecToMerge.maxBitrate)
    );
  }
}

export class AudioCodec extends DeviceCodec {
  private maxChannels: number;
  private maxSampleRate: number | null;

  constructor(
    name: string,
    mimeType: string,
    profiles: Set<string>,
    maxBitrate: number,
    maxChannels: number,
    maxSampleRate: number | null
  ) {
    super(name, mimeType, profiles, maxBitrate);
    this.maxChannels = maxChannels;
    this.maxSampleRate = maxSampleRate;
  }

  mergeCodec(codecToMerge: AudioCodec): AudioCodec {
    let newMaxSampleRate: number | null = null;
    if (this.maxSampleRate !== null) {
      if (codecToMerge.maxSampleRate !== null) {
        newMaxSampleRate = Math.max(this.maxSampleRate, codecToMerge.maxSampleRate);
      } else {
        newMaxSampleRate = this.maxSampleRate;
      }
    } else {
      newMaxSampleRate = codecToMerge.maxSampleRate;
    }

    return new AudioCodec(
      this.name,
      this.mimeType,
      this.mergeProfiles(codecToMerge),  // Helper method to merge profiles
      Math.max(this.maxBitrate, codecToMerge.maxBitrate),
      Math.max(this.maxChannels, codecToMerge.maxChannels),
      newMaxSampleRate
    );
  }

  // Add this helper method in AudioCodec class
  mergeProfiles(codecToMerge: AudioCodec): Set<string> {
    const mergedProfiles = new Set<string>();
    // Add profiles from current codec
    this.profiles.forEach(profile => mergedProfiles.add(profile));
    // Add profiles from codec to merge
    codecToMerge.profiles.forEach(profile => mergedProfiles.add(profile));
    return mergedProfiles;
  }
}