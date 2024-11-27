import { relationalStore } from "@kit.ArkData"

export class ServerEntity {
  id: number
  hostname: string
  lastUsedTimestamp: number

  constructor(hostname: string) {
    this.hostname = hostname
    this.id = 0
    this.lastUsedTimestamp = new Date().getTime()
  }

  asBucket(): relationalStore.ValuesBucket {
    return generateBuckets(this)
  }
}

function generateBuckets(entity: ServerEntity): ServerBuckets {
  let obj: ServerBuckets = {
    id: entity.id,
    hostname: entity.hostname,
    lastUsedTimestamp: entity.lastUsedTimestamp
  }
  return obj
}

interface ServerBuckets extends relationalStore.ValuesBucket {
  id: number
  hostname: string
  lastUsedTimestamp: number
}