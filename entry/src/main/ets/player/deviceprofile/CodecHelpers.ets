import { media } from "@kit.MediaKit"

export class CodecHelpers {
  static getVideoCodec(mimeType: string): string | undefined {
    switch (mimeType) {
      case media.CodecMimeType.VIDEO_MPEG2:
        return "mpeg2video"
      case media.CodecMimeType.VIDEO_H263:
        return "h263"
      case media.CodecMimeType.VIDEO_MPEG4:
        return "mpeg4"
      case media.CodecMimeType.VIDEO_AVC:
        return "h264"
      case media.CodecMimeType.VIDEO_HEVC:
      case 'video/dolby-vision':
        return "hevc"
      case media.CodecMimeType.VIDEO_VP8:
        return "vp8"
      case 'video/x-vnd.on2.vp9':
        return "vp9"
      case 'video/av01':
        return "av1"
      default:
        return undefined
    }
  }

  static getSubtitleMimeType(codec?: string | null): string | null | undefined {
    if (!codec) {
      return null;
    }
    switch (codec.toLowerCase()) {
      case 'srt':
      case 'subrip':
        return 'application/x-subrip';
      case 'ssa':
      case 'ass':
        return 'application/x-ssa'
      case 'ttml':
        return 'application/ttml+xml'
      case 'vtt':
      case 'webvtt':
        return 'application/vtt'
      case 'idx':
      case 'sub':
        return 'application/vobsub'
      case 'pgs':
      case 'pgssub':
        return 'application/pgs'
      case 'smi':
      case 'smil':
        return 'application/smil+xml';
      default:
        return null;
    }
  }
}