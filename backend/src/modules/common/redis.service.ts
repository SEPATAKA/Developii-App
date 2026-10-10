import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  readonly client: Redis;

  constructor(config: ConfigService) {
    this.client = new Redis(config.get('REDIS_URL', 'redis://localhost:6379'), {
      maxRetriesPerRequest: 3,
      lazyConnect: true,
    });
  }

  async connect() {
    if (this.client.status === 'wait') {
      await this.client.connect();
    }
  }

  async onModuleDestroy() {
    await this.client.quit().catch(() => undefined);
  }

  async setex(key: string, seconds: number, value: string) {
    await this.connect();
    await this.client.setex(key, seconds, value);
  }

  async get(key: string) {
    await this.connect();
    return this.client.get(key);
  }

  async del(key: string) {
    await this.connect();
    await this.client.del(key);
  }
}
