// SubtitleManager.ets

// 字幕项结构
interface SubtitleItem {
  index: number; // 序号
  startTime: number; // 开始时间(毫秒)
  endTime: number; // 结束时间(毫秒)
  text: string; // 字幕文本
}

export class SubtitleManager {
  private subtitles: SubtitleItem[] = [];

  parse(resText: string, format: string) {
    switch (format.toLowerCase()) {
      case 'srt':
      case 'subrip':
        this.parseSRT(resText)
        break;
      case 'ass':
        this.parseASS(resText)
        break
    }
  }

  // 解析ASS格式字幕
  parseASS(content: string) {
    const lines = content.split('\n');
    const validSubtitles: SubtitleItem[] = [];
    let currentSection = '';
    let index = 0;

    for (const line of lines) {
      const trimmedLine = line.trim();

      // 跳过空行和注释
      if (!trimmedLine || trimmedLine.startsWith(';')) {
        continue;
      }

      // 检查区段标记
      if (trimmedLine.startsWith('[') && trimmedLine.endsWith(']')) {
        currentSection = trimmedLine.slice(1, -1);
        continue;
      }

      // 只处理Events区段中的Dialogue行
      if (currentSection === 'Events' && trimmedLine.startsWith('Dialogue:')) {
        const parts = trimmedLine.substring(9).split(',');
        if (parts.length < 10) continue;

        // 解析开始和结束时间
        const startTime = this.parseASSTime(parts[1].trim());
        const endTime = this.parseASSTime(parts[2].trim());

        // 合并剩余部分作为文本，并清理ASS格式标记
        const text = this.cleanASSText(parts.slice(9).join(','));

        const subtitle: SubtitleItem = {
          index: index++,
          startTime,
          endTime,
          text
        };

        validSubtitles.push(subtitle);
      }
    }

    this.subtitles = validSubtitles;
  }

  // 解析ASS时间格式 (H:MM:SS.cc)
  private parseASSTime(timeStr: string): number {
    const timeParts = timeStr.split(':');
    const hours = parseInt(timeParts[0]);
    const minutes = parseInt(timeParts[1]);

    const secondParts = timeParts[2].split('.');
    const seconds = parseInt(secondParts[0]);
    const centiseconds = parseInt(secondParts[1]);

    return hours * 3600000 +
      minutes * 60000 +
      seconds * 1000 +
      centiseconds * 10;
  }

  // 清理ASS文本中的样式标记
  private cleanASSText(text: string): string {
    // 移除绘图标记
    let cleanText = text.replace(/\{\\p[0-9]\}.*?\{\\p0\}/g, '');

    // 移除样式标记
    cleanText = cleanText.replace(/\{[^}]*\}/g, '');

    // 替换换行符
    cleanText = cleanText.replace(/\\N/g, '\n');
    cleanText = cleanText.replace(/\\n/g, '\n');

    return cleanText.trim();
  }

  // 解析SRT格式字幕
  parseSRT(content: string) {
    console.log('parseSRT');
    const blocks = content.trim().split('\n\n');
    const validSubtitles: SubtitleItem[] = [];

    for (let i = 0; i < blocks.length; i++) {
      const lines = blocks[i].trim().split('\n');
      if (lines.length < 3) {
        continue;
      }

      const timeLine = lines[1].split(' --> ');
      if (timeLine.length !== 2) {
        continue;
      }

      const subtitle: SubtitleItem = {
        index: parseInt(lines[0]),
        startTime: this.timeToMs(timeLine[0].trim()),
        endTime: this.timeToMs(timeLine[1].trim()),
        text: lines.slice(2).join('\n')
      };

      validSubtitles.push(subtitle);
    }

    this.subtitles = validSubtitles;
  }

  // 时间字符串转毫秒
  private timeToMs(timeStr: string): number {
    const timeParts = timeStr.split(',');
    const time = timeParts[0];
    const ms = timeParts[1];

    const timeSegments = time.split(':');
    const hours = parseInt(timeSegments[0]);
    const minutes = parseInt(timeSegments[1]);
    const seconds = parseInt(timeSegments[2]);

    return hours * 3600000 +
      minutes * 60000 +
      seconds * 1000 +
    parseInt(ms);
  }

  // 根据当前时间获取字幕
  getSubtitle(currentTime: number): string {
    const subtitle = this.subtitles.find(item =>
    currentTime >= item.startTime && currentTime <= item.endTime
    );
    return subtitle?.text || '';
  }
}