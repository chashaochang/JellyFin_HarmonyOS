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
import type { ImageType } from './image-type';
// May contain unused imports in some cases
// @ts-ignore
import type { ItemFields } from './item-fields';
// May contain unused imports in some cases
// @ts-ignore
import type { ItemSortBy } from './item-sort-by';
// May contain unused imports in some cases
// @ts-ignore
import type { SortOrder } from './sort-order';

/**
 * Get programs dto.
 * @export
 * @interface GetProgramsDto
 */
export interface GetProgramsDto {
    /**
     * Gets or sets the channels to return guide information for.
     * @type {Array<string>}
     * @memberof GetProgramsDto
     */
    'ChannelIds'?: Array<string> | null;
    /**
     * Gets or sets optional. Filter by user id.
     * @type {string}
     * @memberof GetProgramsDto
     */
    'UserId'?: string | null;
    /**
     * Gets or sets the minimum premiere start date.
     * @type {string}
     * @memberof GetProgramsDto
     */
    'MinStartDate'?: string | null;
    /**
     * Gets or sets filter by programs that have completed airing, or not.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'HasAired'?: boolean | null;
    /**
     * Gets or sets filter by programs that are currently airing, or not.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'IsAiring'?: boolean | null;
    /**
     * Gets or sets the maximum premiere start date.
     * @type {string}
     * @memberof GetProgramsDto
     */
    'MaxStartDate'?: string | null;
    /**
     * Gets or sets the minimum premiere end date.
     * @type {string}
     * @memberof GetProgramsDto
     */
    'MinEndDate'?: string | null;
    /**
     * Gets or sets the maximum premiere end date.
     * @type {string}
     * @memberof GetProgramsDto
     */
    'MaxEndDate'?: string | null;
    /**
     * Gets or sets filter for movies.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'IsMovie'?: boolean | null;
    /**
     * Gets or sets filter for series.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'IsSeries'?: boolean | null;
    /**
     * Gets or sets filter for news.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'IsNews'?: boolean | null;
    /**
     * Gets or sets filter for kids.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'IsKids'?: boolean | null;
    /**
     * Gets or sets filter for sports.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'IsSports'?: boolean | null;
    /**
     * Gets or sets the record index to start at. All items with a lower index will be dropped from the results.
     * @type {number}
     * @memberof GetProgramsDto
     */
    'StartIndex'?: number | null;
    /**
     * Gets or sets the maximum number of records to return.
     * @type {number}
     * @memberof GetProgramsDto
     */
    'Limit'?: number | null;
    /**
     * Gets or sets specify one or more sort orders, comma delimited. Options: Name, StartDate.
     * @type {Array<ItemSortBy>}
     * @memberof GetProgramsDto
     */
    'SortBy'?: Array<ItemSortBy> | null;
    /**
     * Gets or sets sort order.
     * @type {Array<SortOrder>}
     * @memberof GetProgramsDto
     */
    'SortOrder'?: Array<SortOrder> | null;
    /**
     * Gets or sets the genres to return guide information for.
     * @type {Array<string>}
     * @memberof GetProgramsDto
     */
    'Genres'?: Array<string> | null;
    /**
     * Gets or sets the genre ids to return guide information for.
     * @type {Array<string>}
     * @memberof GetProgramsDto
     */
    'GenreIds'?: Array<string> | null;
    /**
     * Gets or sets include image information in output.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'EnableImages'?: boolean | null;
    /**
     * Gets or sets a value indicating whether retrieve total record count.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'EnableTotalRecordCount'?: boolean;
    /**
     * Gets or sets the max number of images to return, per image type.
     * @type {number}
     * @memberof GetProgramsDto
     */
    'ImageTypeLimit'?: number | null;
    /**
     * Gets or sets the image types to include in the output.
     * @type {Array<ImageType>}
     * @memberof GetProgramsDto
     */
    'EnableImageTypes'?: Array<ImageType> | null;
    /**
     * Gets or sets include user data.
     * @type {boolean}
     * @memberof GetProgramsDto
     */
    'EnableUserData'?: boolean | null;
    /**
     * Gets or sets filter by series timer id.
     * @type {string}
     * @memberof GetProgramsDto
     */
    'SeriesTimerId'?: string | null;
    /**
     * Gets or sets filter by library series id.
     * @type {string}
     * @memberof GetProgramsDto
     */
    'LibrarySeriesId'?: string | null;
    /**
     * Gets or sets specify additional fields of information to return in the output.
     * @type {Array<ItemFields>}
     * @memberof GetProgramsDto
     */
    'Fields'?: Array<ItemFields> | null;
}
