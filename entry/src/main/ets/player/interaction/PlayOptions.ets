export class PlayOptions {
  // 属性定义
  ids: string[] // UUID 在 ArkTS 中可以用 string 表示
  mediaSourceId: string | null
  startIndex: number
  startPositionTicks: number | null
  audioStreamIndex: number | null
  subtitleStreamIndex: number | null

  constructor(
    ids?: string[],
    mediaSourceId?: string | null,
    startIndex?: number | null,
    startPositionTicks?: number | null,
    audioStreamIndex?: number | null,
    subtitleStreamIndex?: number | null
  ) {
    this.ids = ids || []
    this.mediaSourceId = mediaSourceId || null
    this.startIndex = startIndex ?? 0
    this.startPositionTicks = startPositionTicks || null
    this.audioStreamIndex = audioStreamIndex || null
    this.subtitleStreamIndex = subtitleStreamIndex || null
  }

  static fromJson(json: string): PlayOptions {
    const object: PlayOptions = JSON.parse(json)
    return object
    // // 处理 ids 的转换
    // const ids: string[] = parseUUIDs(json['ids'])
    // return new PlayOptions(ids, object.mediaSourceId, object.startIndex, object.startPositionTicks,
    //   object.audioStreamIndex, object.subtitleStreamIndex)
  }
}

function parseUUIDs(array: string[]): string[] {
  if (!array) {
    return []
  }
  return array.map(uuid => toUUID(uuid)).filter(u => u !== null) as string[]
}

function toUUID(value: string): string | null {
  try {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    return uuidRegex.test(value) ? value : null
  } catch {
    return null
  }
}