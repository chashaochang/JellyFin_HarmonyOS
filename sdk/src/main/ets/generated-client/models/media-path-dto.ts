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
import type { MediaPathInfo } from './media-path-info';

/**
 * Media Path dto.
 * @export
 * @interface MediaPathDto
 */
export interface MediaPathDto {
    /**
     * Gets or sets the name of the library.
     * @type {string}
     * @memberof MediaPathDto
     */
    'Name': string;
    /**
     * Gets or sets the path to add.
     * @type {string}
     * @memberof MediaPathDto
     */
    'Path'?: string | null;
    /**
     * 
     * @type {MediaPathInfo}
     * @memberof MediaPathDto
     */
    'PathInfo'?: MediaPathInfo;
}
