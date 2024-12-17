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
 * 
 * @export
 * @enum {string}
 */

export const Architecture = {
    X86: 'X86',
    X64: 'X64',
    Arm: 'Arm',
    Arm64: 'Arm64',
    Wasm: 'Wasm',
    S390x: 'S390x'
} as const;

export type Architecture = typeof Architecture[keyof typeof Architecture];


