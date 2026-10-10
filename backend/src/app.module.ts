import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { WalletModule } from './modules/wallet/wallet.module';
import { InvestmentsModule } from './modules/investments/investments.module';
import { KycModule } from './modules/kyc/kyc.module';
import { LandownerModule } from './modules/landowner/landowner.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { DocumentsModule } from './modules/documents/documents.module';
import { AdminModule } from './modules/admin/admin.module';
import { MailModule } from './modules/mail/mail.module';
import { LedgerModule } from './modules/ledger/ledger.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { ApiExceptionFilter } from './modules/common/api-exception.filter';
import { AdminRolesGuard, JwtAuthGuard } from './modules/common/guards';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 120 }]),
    PrismaModule,
    MailModule,
    LedgerModule,
    PaymentsModule,
    AuthModule,
    UsersModule,
    CatalogModule,
    WalletModule,
    InvestmentsModule,
    KycModule,
    LandownerModule,
    NotificationsModule,
    DocumentsModule,
    AdminModule,
  ],
  providers: [
    { provide: APP_FILTER, useClass: ApiExceptionFilter },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: AdminRolesGuard },
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
