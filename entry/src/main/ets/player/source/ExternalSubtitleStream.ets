export class ExternalSubtitleStream {
  index: number
  deliveryUrl: string
  mimeType: string
  displayTitle: string
  language: string

  constructor(index: number,
    deliveryUrl: string,
    mimeType: string,
    displayTitle: string,
    language: string) {
    this.index = index
    this.deliveryUrl = deliveryUrl
    this.mimeType = mimeType
    this.displayTitle = displayTitle
    this.language = language
  }

  static readonly ID_PREFIX = 'external:'
}