import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { AuthUser, CurrentUser, Public, Roles } from '../common/auth.decorators';

@Controller('notifications')
export class NotificationsController {
  constructor(private notifications: NotificationsService) {}

  @Get()
  list(@CurrentUser() user: AuthUser) {
    return this.notifications.list(user.id);
  }

  @Post('read-all')
  markAll(@CurrentUser() user: AuthUser) {
    return this.notifications.markAllRead(user.id);
  }

  @Get('chat/messages')
  messages(@CurrentUser() user: AuthUser) {
    return this.notifications.messages(user.id);
  }

  @Post('chat/messages')
  send(@CurrentUser() user: AuthUser, @Body() body: { text: string }) {
    return this.notifications.sendMessage(user.id, body.text);
  }

  @Post('devices')
  registerAuthenticated(
    @CurrentUser() user: AuthUser,
    @Body()
    body: {
      platform: string;
      appVersion?: string;
      pushSubscription?: string;
      permissionState?: string;
      metadata?: object;
    },
  ) {
    return this.notifications.registerDevice(user.id, body);
  }

  @Public()
  @Post('devices/anonymous')
  registerAnonymous(
    @Body()
    body: {
      platform: string;
      appVersion?: string;
      pushSubscription?: string;
      permissionState?: string;
      metadata?: object;
    },
  ) {
    return this.notifications.registerDevice(null, body);
  }

  @Post('devices/:id/bind')
  bind(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.notifications.bindDevice(user.id, id);
  }

  @Post(':id/read')
  markRead(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.notifications.markRead(user.id, id);
  }
}

@Controller('admin/notifications')
export class AdminNotificationsController {
  constructor(private notifications: NotificationsService) {}

  @Roles('admin', 'ops')
  @Post('broadcast')
  broadcast(
    @CurrentUser() admin: AuthUser,
    @Body() body: { title: string; body: string; kind?: string },
  ) {
    return this.notifications.broadcast(
      admin.id,
      body.title,
      body.body,
      body.kind,
    );
  }
}
