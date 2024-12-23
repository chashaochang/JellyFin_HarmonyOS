export interface ServerSuggestion {
  type: Type,
  name: string,
  address: string,

  /**
   * A timestamp for this suggestion, used for sorting.
   * For discovered servers, this should be the discovery time,
   * for saved servers, this should be the last used time.
   */
  timestamp: number,
}

export enum Type {
  DISCOVERED,
  SAVED,
}