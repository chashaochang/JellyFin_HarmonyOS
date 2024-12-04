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



/**
 * Enum ImageResolution.
 * @export
 * @enum {string}
 */

export const ImageResolution = {
    MatchSource: 'MatchSource',
    P144: 'P144',
    P240: 'P240',
    P360: 'P360',
    P480: 'P480',
    P720: 'P720',
    P1080: 'P1080',
    P1440: 'P1440',
    P2160: 'P2160'
} as const;

export type ImageResolution = typeof ImageResolution[keyof typeof ImageResolution];



