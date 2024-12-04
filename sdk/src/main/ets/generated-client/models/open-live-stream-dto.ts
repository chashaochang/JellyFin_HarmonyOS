/* tslint:disable */
/* eslint-disable */
/**
 * NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * Do not edit the class manually.
 *
 * Jellyfin API
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */


// May contain unused imports in some cases
// @ts-ignore
import type { DeviceProfile } from './device-profile';
// May contain unused imports in some cases
// @ts-ignore
import type { MediaProtocol } from './media-protocol';

/**
 * Open live stream dto.
 * @export
 * @interface OpenLiveStreamDto
 */
export interface OpenLiveStreamDto {
    /**
     * Gets or sets the open token.
     * @type {string}
     * @memberof OpenLiveStreamDto
     */
    'OpenToken'?: string | null;
    /**
     * Gets or sets the user id.
     * @type {string}
     * @memberof OpenLiveStreamDto
     */
    'UserId'?: string | null;
    /**
     * Gets or sets the play session id.
     * @type {string}
     * @memberof OpenLiveStreamDto
     */
    'PlaySessionId'?: string | null;
    /**
     * Gets or sets the max streaming bitrate.
     * @type {number}
     * @memberof OpenLiveStreamDto
     */
    'MaxStreamingBitrate'?: number | null;
    /**
     * Gets or sets the start time in ticks.
     * @type {number}
     * @memberof OpenLiveStreamDto
     */
    'StartTimeTicks'?: number | null;
    /**
     * Gets or sets the audio stream index.
     * @type {number}
     * @memberof OpenLiveStreamDto
     */
    'AudioStreamIndex'?: number | null;
    /**
     * Gets or sets the subtitle stream index.
     * @type {number}
     * @memberof OpenLiveStreamDto
     */
    'SubtitleStreamIndex'?: number | null;
    /**
     * Gets or sets the max audio channels.
     * @type {number}
     * @memberof OpenLiveStreamDto
     */
    'MaxAudioChannels'?: number | null;
    /**
     * Gets or sets the item id.
     * @type {string}
     * @memberof OpenLiveStreamDto
     */
    'ItemId'?: string | null;
    /**
     * Gets or sets a value indicating whether to enable direct play.
     * @type {boolean}
     * @memberof OpenLiveStreamDto
     */
    'EnableDirectPlay'?: boolean | null;
    /**
     * Gets or sets a value indicating whether to enale direct stream.
     * @type {boolean}
     * @memberof OpenLiveStreamDto
     */
    'EnableDirectStream'?: boolean | null;
    /**
     * Gets or sets a value indicating whether always burn in subtitles when transcoding.
     * @type {boolean}
     * @memberof OpenLiveStreamDto
     */
    'AlwaysBurnInSubtitleWhenTranscoding'?: boolean | null;
    /**
     * 
     * @type {DeviceProfile}
     * @memberof OpenLiveStreamDto
     */
    'DeviceProfile'?: DeviceProfile;
    /**
     * Gets or sets the device play protocols.
     * @type {Array<MediaProtocol>}
     * @memberof OpenLiveStreamDto
     */
    'DirectPlayProtocols'?: Array<MediaProtocol>;
}

