import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Optional OneSignal installation registry helper.
 * Bind after login / unbind on logout when ONESIGNAL_APP_ID is configured.
 */
@Injectable()
export class PushRegistryService {
  constructor(private config: ConfigService) {}

  get enabled() {
    return Boolean(this.config.get('ONESIGNAL_APP_ID'));
  }

  async notifyUser(_externalId: string, _title: string, _body: string) {
    if (!this.enabled) return { skipped: true };
    // Wire OneSignal REST API when credentials are supplied.
    return { skipped: false, queued: true };
  }
}
