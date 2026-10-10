import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async list(userId: string) {
    const rows = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return rows.map((n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      kind: n.kind,
      read: !!n.readAt,
      createdAt: n.createdAt.toISOString(),
      payload: n.payload,
    }));
  }

  async markRead(userId: string, id: string) {
    await this.prisma.notification.updateMany({
      where: { id, userId },
      data: { readAt: new Date() },
    });
    return { ok: true };
  }

  async markAllRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { ok: true };
  }

  async messages(userId: string) {
    const rows = await this.prisma.chatMessage.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      take: 200,
    });
    return rows.map((m) => ({
      id: m.id,
      text: m.text,
      fromSupport: m.fromSupport,
      createdAt: m.createdAt.toISOString(),
    }));
  }

  async sendMessage(userId: string, text: string) {
    const message = await this.prisma.chatMessage.create({
      data: { userId, text: text.trim(), fromSupport: false },
    });
    return {
      id: message.id,
      text: message.text,
      fromSupport: false,
      createdAt: message.createdAt.toISOString(),
    };
  }

  async registerDevice(
    userId: string | null,
    data: {
      platform: string;
      appVersion?: string;
      pushSubscription?: string;
      permissionState?: string;
      metadata?: object;
    },
  ) {
    return this.prisma.deviceInstallation.create({
      data: {
        userId: userId ?? undefined,
        platform: data.platform,
        appVersion: data.appVersion,
        pushSubscription: data.pushSubscription,
        permissionState: data.permissionState ?? 'unknown',
        metadata: data.metadata,
      },
    });
  }

  async bindDevice(userId: string, deviceId: string) {
    return this.prisma.deviceInstallation.update({
      where: { id: deviceId },
      data: { userId },
    });
  }

  async broadcast(adminId: string, title: string, body: string, kind = 'updates') {
    const users = await this.prisma.user.findMany({ select: { id: true } });
    await this.prisma.notification.createMany({
      data: users.map((u) => ({
        userId: u.id,
        title,
        body,
        kind,
      })),
    });
    await this.prisma.auditLog.create({
      data: {
        actorAdminId: adminId,
        action: 'notifications.broadcast',
        resource: 'notification',
        metadata: { title, count: users.length },
      },
    });
    return { sent: users.length };
  }
}
