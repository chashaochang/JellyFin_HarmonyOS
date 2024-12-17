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
import type { LogLevel } from './log-level';

/**
 * An activity log entry.
 * @export
 * @interface ActivityLogEntry
 */
export interface ActivityLogEntry {
    /**
     * Gets or sets the identifier.
     * @type {number}
     * @memberof ActivityLogEntry
     */
    'Id'?: number;
    /**
     * Gets or sets the name.
     * @type {string}
     * @memberof ActivityLogEntry
     */
    'Name'?: string;
    /**
     * Gets or sets the overview.
     * @type {string}
     * @memberof ActivityLogEntry
     */
    'Overview'?: string | null;
    /**
     * Gets or sets the short overview.
     * @type {string}
     * @memberof ActivityLogEntry
     */
    'ShortOverview'?: string | null;
    /**
     * Gets or sets the type.
     * @type {string}
     * @memberof ActivityLogEntry
     */
    'Type'?: string;
    /**
     * Gets or sets the item identifier.
     * @type {string}
     * @memberof ActivityLogEntry
     */
    'ItemId'?: string | null;
    /**
     * Gets or sets the date.
     * @type {string}
     * @memberof ActivityLogEntry
     */
    'Date'?: string;
    /**
     * Gets or sets the user identifier.
     * @type {string}
     * @memberof ActivityLogEntry
     */
    'UserId'?: string;
    /**
     * Gets or sets the user primary image tag.
     * @type {string}
     * @memberof ActivityLogEntry
     * @deprecated
     */
    'UserPrimaryImageTag'?: string | null;
    /**
     * 
     * @type {LogLevel}
     * @memberof ActivityLogEntry
     */
    'Severity'?: LogLevel;
}


