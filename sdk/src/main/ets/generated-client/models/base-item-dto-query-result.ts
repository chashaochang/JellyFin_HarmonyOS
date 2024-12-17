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
import type { BaseItemDto } from './base-item-dto';

/**
 * Query result container.
 * @export
 * @interface BaseItemDtoQueryResult
 */
export interface BaseItemDtoQueryResult {
    /**
     * Gets or sets the items.
     * @type {Array<BaseItemDto>}
     * @memberof BaseItemDtoQueryResult
     */
    'Items'?: Array<BaseItemDto>;
    /**
     * Gets or sets the total number of records available.
     * @type {number}
     * @memberof BaseItemDtoQueryResult
     */
    'TotalRecordCount'?: number;
    /**
     * Gets or sets the index of the first record in Items.
     * @type {number}
     * @memberof BaseItemDtoQueryResult
     */
    'StartIndex'?: number;
}
