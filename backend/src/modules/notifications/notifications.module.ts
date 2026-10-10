import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import {
  AdminNotificationsController,
  NotificationsController,
} from './notifications.controller';
import { PushRegistryService } from './push-registry.service';

@Module({
  providers: [NotificationsService, PushRegistryService],
  controllers: [NotificationsController, AdminNotificationsController],
  exports: [NotificationsService, PushRegistryService],
})
export class NotificationsModule {}
